import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/daily_energy_repository.dart';
import 'energy_providers.dart';

/// Quản lý trạng thái Năng lượng còn lại trong ngày (0..3).
/// Tuân thủ Riverpod 3 Notifier API.
class DailyEnergyNotifier extends Notifier<int> {
  late final DailyEnergyRepository _repository;

  @override
  int build() {
    _repository = ref.watch(dailyEnergyRepositoryProvider);
    // Tự động đồng bộ năng lượng khi Notifier được khởi tạo
    Future.microtask(() => refreshEnergy());
    return DailyEnergyRepository.maxDailyEnergy;
  }

  /// Làm mới và đồng bộ lại năng lượng từ Repository (tự động reset về 3 nếu sang ngày mới).
  Future<int> refreshEnergy() async {
    final remaining = await _repository.getRemainingEnergy();
    state = remaining;
    return remaining;
  }

  /// Tiêu thụ nguyên tử Năng lượng (mặc định amount = 1).
  /// Hỗ trợ [attemptId] và [reason] để đảm bảo tính Exactly-once và Idempotency bền vững.
  /// Trả về số năng lượng còn lại nếu thành công (0..3), hoặc `null` nếu không đủ năng lượng.
  Future<int?> consumeEnergy({
    int amount = 1,
    String? attemptId,
    String? reason,
  }) async {
    final newEnergy = await _repository.consumeEnergy(
      amount: amount,
      attemptId: attemptId,
      reason: reason,
    );
    if (newEnergy != null) {
      state = newEnergy;
    }
    return newEnergy;
  }

  /// Cộng thêm Năng lượng (dành cho Rewarded Ads trong tương lai).
  Future<int> addEnergy(int amount) async {
    final newEnergy = await _repository.addEnergy(amount);
    state = newEnergy;
    return newEnergy;
  }

  /// Nhận thưởng Năng lượng nguyên tử từ Rewarded Ads theo rewardId (UUID v4).
  /// Cập nhật ngay lập tức state Riverpod nếu nhận thưởng thành công.
  Future<ClaimRewardResult> claimEnergyReward({
    required int amount,
    required String rewardId,
  }) async {
    final result = await _repository.claimEnergyReward(
      amount: amount,
      rewardId: rewardId,
    );
    if (result.isSuccess) {
      state = result.currentEnergy;
    }
    return result;
  }
}

/// Provider quản lý hạn ngạch Năng lượng hằng ngày.
final dailyEnergyNotifierProvider =
    NotifierProvider<DailyEnergyNotifier, int>(DailyEnergyNotifier.new);
