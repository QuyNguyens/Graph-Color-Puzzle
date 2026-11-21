import 'dart:async';

/// Trạng thái của Rewarded Ad
enum RewardedAdState {
  initial,
  loading,
  loaded,
  showing,
  failed,
}

/// Interface dịch vụ Rewarded Ads tuân thủ Clean Architecture.
/// Định nghĩa hợp đồng hiển thị quảng cáo trả thưởng và xử lý callback an toàn.
abstract class RewardedAdService {
  /// Khởi tạo SDK quảng cáo (an toàn trên mọi nền tảng)
  Future<void> initialize();

  /// Nạp trước (preload) video quảng cáo trả thưởng
  Future<void> loadRewardedAd();

  /// Kiểm tra quảng cáo đã sẵn sàng hiển thị hay chưa
  bool get isAdLoaded;

  /// Trạng thái hiện tại của Ad
  RewardedAdState get state;

  /// Stream thông báo khi trạng thái quảng cáo thay đổi
  Stream<RewardedAdState> get stateStream;

  /// Hiển thị quảng cáo trả thưởng.
  /// - [onUserEarnedReward]: Callback kích hoạt DUY NHẤT một lần khi người chơi xem hết video và được AdMob xác nhận thưởng.
  /// - [onAdFailedToShow]: Callback khi việc hiển thị thất bại (mạng, lỗi SDK...).
  /// - [onAdDismissed]: Callback khi người chơi đóng quảng cáo (dù có nhận thưởng hay không).
  Future<bool> showRewardedAd({
    required void Function(int amount, String type) onUserEarnedReward,
    void Function(String error)? onAdFailedToShow,
    void Function()? onAdDismissed,
  });

  /// Hủy tài nguyên khi cần
  void dispose();
}
