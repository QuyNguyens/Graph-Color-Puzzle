import 'dart:async';
import 'dart:convert';

import '../../domain/entities/daily_challenge_state.dart';
import '../../domain/entities/level_completion_event.dart';
import '../../domain/repositories/daily_challenge_repository.dart';
import '../datasources/daily_challenge_local_datasource.dart';
import '../models/daily_challenge_dto.dart';

/// Triển khai DailyChallengeRepository với hàng đợi bất đồng bộ nguyên tử.
/// Đảm bảo tính nhất quán dữ liệu, chống race condition và hỗ trợ reset ngày mới an toàn.
/// Tầng Data Layer.
class DailyChallengeRepositoryImpl implements DailyChallengeRepository {
  DailyChallengeRepositoryImpl({
    required DailyChallengeLocalDataSource localDataSource,
    DateTime Function()? nowProvider,
  })  : _localDataSource = localDataSource,
        _nowProvider = nowProvider ?? DateTime.now;

  final DailyChallengeLocalDataSource _localDataSource;
  final DateTime Function() _nowProvider;

  // Hàng đợi tuần tự (Mutex) đảm bảo các thao tác đọc-sửa-ghi luôn nguyên tử
  Future<dynamic> _operationQueue = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  String _getTodayString() {
    return _nowProvider().toIso8601String().substring(0, 10);
  }

  Future<DailyChallengeState> _readAndSyncState() async {
    final today = _getTodayString();
    final rawJson = await _localDataSource.getRawChallenge();

    if (rawJson == null || rawJson.trim().isEmpty) {
      final initial = DailyChallengeState.initial(today);
      await _saveStateToDisk(initial);
      return initial;
    }

    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        final initial = DailyChallengeState.initial(today);
        await _saveStateToDisk(initial);
        return initial;
      }

      final dto = DailyChallengeDto.fromJson(decoded);

      // Nếu đã sang ngày mới -> reset cứng về trạng thái ban đầu của ngày mới
      if (dto.date != today) {
        final freshState = DailyChallengeState.initial(today);
        await _saveStateToDisk(freshState);
        return freshState;
      }

      return dto.toEntity();
    } catch (_) {
      // Dữ liệu JSON bị hỏng -> fallback an toàn
      final fallback = DailyChallengeState.initial(today);
      await _saveStateToDisk(fallback);
      return fallback;
    }
  }

  Future<bool> _saveStateToDisk(DailyChallengeState state) async {
    final dto = DailyChallengeDto.fromEntity(state);
    final rawJson = jsonEncode(dto.toJson());
    return await _localDataSource.saveRawChallenge(rawJson);
  }

  @override
  Future<DailyChallengeState> getDailyChallengeState() {
    return _synchronized(() => _readAndSyncState());
  }

  @override
  Future<bool> recordCompletion(LevelCompletionEvent event) {
    return _synchronized(() async {
      final today = _getTodayString();

      // Sự kiện không thuộc ngày hôm nay: Bỏ qua không cộng vào Daily Challenge hôm nay
      if (event.completedDate != today) {
        return true;
      }

      final currentState = await _readAndSyncState();

      // Kiểm tra idempotent: Nếu attemptId này đã được xử lý trong ngày -> bỏ qua
      if (currentState.isAttemptProcessed(event.attemptId)) {
        return true;
      }

      // Cập nhật tiến độ nhiệm vụ và ghi nhận attemptId
      final updatedState = currentState.withCompletion(event);

      // Ghi đĩa nguyên tử cả tiến độ và processed_attempt_ids trong cùng 1 payload
      final success = await _saveStateToDisk(updatedState);
      return success;
    });
  }

  @override
  Future<bool> markMissionClaimed(String missionId) {
    return _synchronized(() async {
      final currentState = await _readAndSyncState();

      // Kiểm tra xem nhiệm vụ có tồn tại và đã hoàn thành chưa
      final mission = currentState.missions.firstWhere(
        (m) => m.id == missionId,
        orElse: () => throw ArgumentError('Không tìm thấy nhiệm vụ $missionId'),
      );

      if (!mission.isCompleted || mission.isClaimed) {
        return false;
      }

      final updatedState = currentState.withClaimedMission(missionId);
      final success = await _saveStateToDisk(updatedState);
      return success;
    });
  }

  @override
  Future<bool> resetDailyChallenge() {
    return _synchronized(() async {
      final today = _getTodayString();
      final freshState = DailyChallengeState.initial(today);
      return await _saveStateToDisk(freshState);
    });
  }
}

