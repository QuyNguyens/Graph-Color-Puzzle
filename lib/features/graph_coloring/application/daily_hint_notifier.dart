import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/daily_hint_repository.dart';
import 'hint_providers.dart';

/// Quản lý trạng thái số lượt Hint còn lại trong ngày (0..3).
/// Tuân thủ Riverpod 3 Notifier.
class DailyHintNotifier extends Notifier<int> {
  late final DailyHintRepository _repository;

  @override
  int build() {
    _repository = ref.watch(dailyHintRepositoryProvider);
    // Tự động đồng bộ quota khi Notifier được khởi tạo
    Future.microtask(() => refreshQuota());
    return DailyHintRepository.maxDailyHints;
  }

  /// Làm mới và đồng bộ lại quota từ Repository (tự động reset nếu sang ngày mới).
  Future<int> refreshQuota() async {
    final remaining = await _repository.getRemainingHints();
    state = remaining;
    return remaining;
  }

  /// Tiêu thụ 1 lượt Hint theo cơ chế nguyên tử.
  /// Trả về số lượt còn lại nếu thành công (ví dụ: 0), hoặc `null` nếu đã hết lượt.
  Future<int?> consumeHint() async {
    final newQuota = await _repository.consumeHint();
    if (newQuota != null) {
      state = newQuota;
    } else {
      // Đảm bảo state thể hiện chính xác 0 nếu đã hết
      state = 0;
    }
    return newQuota;
  }

  /// Thêm lượt Hint khi người dùng xem quảng cáo nhận thưởng thành công.
  Future<int> grantHintReward({int amount = 1}) async {
    final newQuota = await _repository.addHintReward(amount: amount);
    state = newQuota;
    return newQuota;
  }
}

/// Provider quản lý hạn ngạch Hint hằng ngày.
final dailyHintNotifierProvider =
    NotifierProvider<DailyHintNotifier, int>(DailyHintNotifier.new);
