import 'dart:async';
import 'dart:convert';

import '../../domain/repositories/daily_hint_repository.dart';
import '../datasources/daily_hint_local_datasource.dart';

/// Triển khai DailyHintRepository với hàng đợi bất đồng bộ nguyên tử.
/// Đảm bảo tính nhất quán dữ liệu và loại trừ race condition khi người chơi bấm nút Hint liên tục.
class DailyHintRepositoryImpl implements DailyHintRepository {
  DailyHintRepositoryImpl({
    required DailyHintLocalDataSource localDataSource,
    DateTime Function()? nowProvider,
  })  : _localDataSource = localDataSource,
        _nowProvider = nowProvider ?? DateTime.now;

  final DailyHintLocalDataSource _localDataSource;
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

  /// Đọc quota hiện tại, tự động kiểm tra ngày và reset về maxDailyHints (1) nếu sang ngày mới.
  Future<int> _readAndSyncQuota() async {
    final today = _getTodayString();
    final rawJson = await _localDataSource.getRawQuota();

    if (rawJson == null || rawJson.trim().isEmpty) {
      // Chưa từng lưu dữ liệu -> Khởi tạo maxDailyHints cho ngày hôm nay
      await _saveQuota(date: today, remaining: DailyHintRepository.maxDailyHints);
      return DailyHintRepository.maxDailyHints;
    }

    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        await _saveQuota(date: today, remaining: DailyHintRepository.maxDailyHints);
        return DailyHintRepository.maxDailyHints;
      }

      final savedDate = decoded['date'] as String?;
      final savedRemaining = decoded['remaining'] as int?;

      // Nếu đã sang ngày mới -> reset cứng về maxDailyHints (1), không cộng dồn
      if (savedDate != today) {
        await _saveQuota(date: today, remaining: DailyHintRepository.maxDailyHints);
        return DailyHintRepository.maxDailyHints;
      }

      // Vẫn trong ngày cũ -> không âm
      final validRemaining = (savedRemaining ?? DailyHintRepository.maxDailyHints);
      return validRemaining < 0 ? 0 : validRemaining;
    } catch (_) {
      // Dữ liệu JSON bị hỏng -> fallback về maxDailyHints
      await _saveQuota(date: today, remaining: DailyHintRepository.maxDailyHints);
      return DailyHintRepository.maxDailyHints;
    }
  }

  Future<void> _saveQuota({required String date, required int remaining}) async {
    final payload = jsonEncode({
      'date': date,
      'remaining': remaining < 0 ? 0 : remaining,
    });
    await _localDataSource.saveRawQuota(payload);
  }

  @override
  Future<int> getRemainingHints() {
    return _synchronized(() => _readAndSyncQuota());
  }

  @override
  Future<int?> consumeHint() {
    return _synchronized(() async {
      final currentRemaining = await _readAndSyncQuota();

      // Nếu đã hết quota trong ngày -> Trả về null
      if (currentRemaining <= 0) {
        return null;
      }

      final newRemaining = currentRemaining - 1;
      final today = _getTodayString();
      await _saveQuota(date: today, remaining: newRemaining);

      return newRemaining;
    });
  }

  @override
  Future<int> addHintReward({int amount = 1}) {
    return _synchronized(() async {
      final currentRemaining = await _readAndSyncQuota();
      final effectiveAmount = amount > 0 ? amount : 1;
      final newRemaining = currentRemaining + effectiveAmount;
      final today = _getTodayString();
      await _saveQuota(date: today, remaining: newRemaining);

      return newRemaining;
    });
  }

  @override
  Future<void> resetDailyHints() {
    return _synchronized(() async {
      final today = _getTodayString();
      await _saveQuota(date: today, remaining: DailyHintRepository.maxDailyHints);
    });
  }
}
