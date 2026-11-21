import 'dart:async';
import 'dart:convert';

import '../../domain/repositories/daily_energy_repository.dart';
import '../datasources/daily_energy_local_datasource.dart';

class _EnergyData {
  const _EnergyData({
    required this.date,
    required this.remaining,
    required this.claimedRewards,
    this.consumedTransitions = const [],
  });

  final String date;
  final int remaining;
  final List<String> claimedRewards;
  final List<String> consumedTransitions;
}

/// Triển khai DailyEnergyRepository với hàng đợi bất đồng bộ nguyên tử.
/// Đảm bảo tính nhất quán dữ liệu, loại trừ race condition, hỗ trợ claim thưởng idempotent
/// và chống tiêu thụ Energy trùng lặp cho cùng một attemptId.
class DailyEnergyRepositoryImpl implements DailyEnergyRepository {
  DailyEnergyRepositoryImpl({
    required DailyEnergyLocalDataSource localDataSource,
    DateTime Function()? nowProvider,
  })  : _localDataSource = localDataSource,
        _nowProvider = nowProvider ?? DateTime.now;

  final DailyEnergyLocalDataSource _localDataSource;
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

  /// Xác định chuỗi ngày hiện tại (YYYY-MM-DD) theo múi giờ chuẩn Asia/Ho_Chi_Minh (UTC+7).
  String _getTodayString() {
    final nowUtc = _nowProvider().toUtc();
    final vnTime = nowUtc.add(const Duration(hours: 7));
    return vnTime.toIso8601String().substring(0, 10);
  }

  /// Đọc dữ liệu năng lượng và claimed_rewards, tự động kiểm tra ngày và reset về 3 nếu sang ngày mới.
  Future<_EnergyData> _readAndSyncEnergyData() async {
    final today = _getTodayString();
    final rawJson = await _localDataSource.getRawEnergy();

    if (rawJson == null || rawJson.trim().isEmpty) {
      final initialData = _EnergyData(
        date: today,
        remaining: DailyEnergyRepository.maxDailyEnergy,
        claimedRewards: const [],
        consumedTransitions: const [],
      );
      await _saveEnergyData(initialData);
      return initialData;
    }

    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        final fallback = _EnergyData(
          date: today,
          remaining: DailyEnergyRepository.maxDailyEnergy,
          claimedRewards: const [],
          consumedTransitions: const [],
        );
        await _saveEnergyData(fallback);
        return fallback;
      }

      final savedDate = decoded['date'] as String?;
      final savedRemaining = decoded['remaining'] as int?;
      final rawClaimed = decoded['claimed_rewards'] as List<dynamic>? ?? [];
      final savedClaimed = rawClaimed.map((e) => e.toString()).toList();
      final rawTransitions =
          decoded['consumed_transitions'] as List<dynamic>? ?? [];
      final savedTransitions =
          rawTransitions.map((e) => e.toString()).toList();

      // Kiểm tra sang ngày mới (chỉ reset nếu today > savedDate hoặc savedDate null)
      if (savedDate != today) {
        if (savedDate == null || today.compareTo(savedDate) > 0) {
          final freshData = _EnergyData(
            date: today,
            remaining: DailyEnergyRepository.maxDailyEnergy,
            claimedRewards: const [],
            consumedTransitions: const [],
          );
          await _saveEnergyData(freshData);
          return freshData;
        }
      }

      // Giới hạn Energy trong khoảng [0..3]
      final validRemaining =
          (savedRemaining ?? DailyEnergyRepository.maxDailyEnergy)
              .clamp(0, DailyEnergyRepository.maxDailyEnergy);

      return _EnergyData(
        date: today,
        remaining: validRemaining,
        claimedRewards: savedClaimed,
        consumedTransitions: savedTransitions,
      );
    } catch (_) {
      final fallback = _EnergyData(
        date: today,
        remaining: DailyEnergyRepository.maxDailyEnergy,
        claimedRewards: const [],
        consumedTransitions: const [],
      );
      await _saveEnergyData(fallback);
      return fallback;
    }
  }

  Future<bool> _saveEnergyData(_EnergyData data) async {
    final payload = jsonEncode({
      'date': data.date,
      'remaining':
          data.remaining.clamp(0, DailyEnergyRepository.maxDailyEnergy),
      'claimed_rewards': data.claimedRewards,
      'consumed_transitions': data.consumedTransitions,
    });
    return await _localDataSource.saveRawEnergy(payload);
  }

  @override
  Future<int> getRemainingEnergy() {
    return _synchronized(() async {
      final data = await _readAndSyncEnergyData();
      return data.remaining;
    });
  }

  @override
  Future<int?> consumeEnergy({
    int amount = 1,
    String? attemptId,
    String? reason,
  }) {
    return _synchronized(() async {
      final data = await _readAndSyncEnergyData();
      if (amount <= 0) {
        return data.remaining;
      }

      // Kiểm tra Idempotency nếu có attemptId
      if (attemptId != null && attemptId.trim().isNotEmpty) {
        final cleanId = attemptId.trim();
        final transitionKey = reason != null ? '${cleanId}_$reason' : cleanId;

        // Nếu attempt này đã từng bị trừ Energy cho bất kỳ terminal transition nào -> Trả về remaining ngay, không trừ lần 2
        final alreadyConsumed = data.consumedTransitions.any(
          (t) => t == transitionKey || t.startsWith('${cleanId}_'),
        );

        if (alreadyConsumed) {
          return data.remaining;
        }

        // Nếu không đủ năng lượng để trừ
        if (data.remaining < amount) {
          return null;
        }

        final newRemaining = (data.remaining - amount)
            .clamp(0, DailyEnergyRepository.maxDailyEnergy);

        final updatedTransitions = [...data.consumedTransitions, transitionKey];
        final updatedData = _EnergyData(
          date: data.date,
          remaining: newRemaining,
          claimedRewards: data.claimedRewards,
          consumedTransitions: updatedTransitions,
        );

        final success = await _saveEnergyData(updatedData);
        if (!success) {
          return null;
        }

        return newRemaining;
      }

      // Fallback nếu không truyền attemptId
      if (data.remaining < amount) {
        return null;
      }

      final newRemaining = (data.remaining - amount)
          .clamp(0, DailyEnergyRepository.maxDailyEnergy);

      final updatedData = _EnergyData(
        date: data.date,
        remaining: newRemaining,
        claimedRewards: data.claimedRewards,
        consumedTransitions: data.consumedTransitions,
      );

      final success = await _saveEnergyData(updatedData);
      if (!success) {
        return null;
      }

      return newRemaining;
    });
  }

  @override
  Future<int> addEnergy(int amount) {
    return _synchronized(() async {
      final data = await _readAndSyncEnergyData();
      if (amount <= 0) {
        return data.remaining;
      }

      final newRemaining = (data.remaining + amount)
          .clamp(0, DailyEnergyRepository.maxDailyEnergy);

      final updatedData = _EnergyData(
        date: data.date,
        remaining: newRemaining,
        claimedRewards: data.claimedRewards,
        consumedTransitions: data.consumedTransitions,
      );

      final success = await _saveEnergyData(updatedData);
      if (!success) {
        return data.remaining;
      }

      return newRemaining;
    });
  }

  @override
  Future<ClaimRewardResult> claimEnergyReward({
    required int amount,
    required String rewardId,
  }) {
    return _synchronized(() async {
      final data = await _readAndSyncEnergyData();

      // Kiểm tra tham số hợp lệ
      if (amount <= 0 || rewardId.trim().isEmpty) {
        return ClaimRewardResult(
          isSuccess: false,
          alreadyClaimed: false,
          previousEnergy: data.remaining,
          actualAdded: 0,
          currentEnergy: data.remaining,
          cappedAtMax: false,
          errorMessage: 'Tham số nhận thưởng không hợp lệ.',
        );
      }

      // Kiểm tra xem rewardId này đã từng được nhận chưa (Idempotency)
      if (data.claimedRewards.contains(rewardId)) {
        return ClaimRewardResult(
          isSuccess: true,
          alreadyClaimed: true,
          previousEnergy: data.remaining,
          actualAdded: 0,
          currentEnergy: data.remaining,
          cappedAtMax: false,
        );
      }

      final previousEnergy = data.remaining;
      final target = previousEnergy + amount;
      final newRemaining = target.clamp(0, DailyEnergyRepository.maxDailyEnergy);
      final actualAdded = newRemaining - previousEnergy;
      final cappedAtMax = target > DailyEnergyRepository.maxDailyEnergy;

      final updatedClaimed = [...data.claimedRewards, rewardId];
      final updatedData = _EnergyData(
        date: data.date,
        remaining: newRemaining,
        claimedRewards: updatedClaimed,
        consumedTransitions: data.consumedTransitions,
      );

      final success = await _saveEnergyData(updatedData);
      if (!success) {
        return ClaimRewardResult(
          isSuccess: false,
          alreadyClaimed: false,
          previousEnergy: previousEnergy,
          actualAdded: 0,
          currentEnergy: previousEnergy,
          cappedAtMax: false,
          errorMessage: 'Không thể ghi vào bộ nhớ thiết bị.',
        );
      }

      return ClaimRewardResult(
        isSuccess: true,
        alreadyClaimed: false,
        previousEnergy: previousEnergy,
        actualAdded: actualAdded,
        currentEnergy: newRemaining,
        cappedAtMax: cappedAtMax,
      );
    });
  }

  @override
  Future<void> resetDailyEnergy() {
    return _synchronized(() async {
      final today = _getTodayString();
      final freshData = _EnergyData(
        date: today,
        remaining: DailyEnergyRepository.maxDailyEnergy,
        claimedRewards: const [],
        consumedTransitions: const [],
      );
      await _saveEnergyData(freshData);
    });
  }
}
