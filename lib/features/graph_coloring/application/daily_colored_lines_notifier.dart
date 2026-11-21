import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'line_settings_providers.dart';

/// Quản lý trạng thái số lượt sử dụng đường nối màu còn lại trong ngày (0..5+).
/// Tuân thủ Riverpod 3 Notifier.
class DailyColoredLinesNotifier extends Notifier<int> {
  late final DailyColoredLinesRepository _repository;

  @override
  int build() {
    _repository = ref.watch(dailyColoredLinesRepositoryProvider);
    // Tự động đồng bộ quota khi Notifier được khởi tạo
    Future.microtask(() => refreshQuota());
    return DailyColoredLinesRepository.maxDailyQuota;
  }

  /// Làm mới và đồng bộ lại quota từ Repository (tự động reset nếu sang ngày mới).
  Future<int> refreshQuota() async {
    final remaining = await _repository.getRemainingQuota();
    state = remaining;
    return remaining;
  }

  /// Tiêu thụ nguyên tử 1 lượt đường nối màu khi kết thúc màn chơi (thắng hoặc thua).
  /// Trả về số lượt còn lại nếu thành công, hoặc `null` nếu đã hết lượt.
  Future<int?> consumeTurn() async {
    final newQuota = await _repository.consumeQuota();
    if (newQuota != null) {
      state = newQuota;
    } else {
      state = 0;
    }
    return newQuota;
  }

  /// Thêm lượt khi người dùng xem quảng cáo nhận thưởng thành công.
  Future<int> grantQuotaReward({int amount = 1}) async {
    final newQuota = await _repository.addQuotaReward(amount: amount);
    state = newQuota;
    return newQuota;
  }
}

/// Provider quản lý hạn ngạch đường nối màu hằng ngày.
final dailyColoredLinesNotifierProvider =
    NotifierProvider<DailyColoredLinesNotifier, int>(
  DailyColoredLinesNotifier.new,
);
