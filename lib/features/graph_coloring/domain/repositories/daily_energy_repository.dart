/// Kết quả trả về sau khi thực hiện nhận thưởng Năng lượng.
/// Đầy đủ thông tin phục vụ kiểm soát Idempotency và cập nhật giao diện.
class ClaimRewardResult {
  const ClaimRewardResult({
    required this.isSuccess,
    required this.alreadyClaimed,
    required this.previousEnergy,
    required this.actualAdded,
    required this.currentEnergy,
    required this.cappedAtMax,
    this.errorMessage,
  });

  /// Thao tác ghi đĩa SharedPreferences thành công hay không
  final bool isSuccess;

  /// Phần thưởng này đã được nhận trước đó chưa (Idempotent)
  final bool alreadyClaimed;

  /// Số Energy trước khi nhận thưởng
  final int previousEnergy;

  /// Lượng Energy thực tế được cộng sau khi áp dụng trần tối đa 3
  final int actualAdded;

  /// Số Energy sau khi xử lý (0..3)
  final int currentEnergy;

  /// Có bị chạm trần 3 Energy không (target > 3)
  final bool cappedAtMax;

  /// Thông báo lỗi nếu thất bại
  final String? errorMessage;
}

/// Interface quản lý hạn ngạch Năng lượng hằng ngày (Daily Energy).
/// Tuân thủ Clean Architecture, Tầng Domain thuần Dart.
abstract class DailyEnergyRepository {
  /// Số Năng lượng tối đa mỗi ngày (GDD Chuẩn hóa Sub-phase D2).
  static const int maxDailyEnergy = 3;

  /// Lấy số Năng lượng còn lại trong ngày của người chơi (0..3).
  /// Tự động kiểm tra và reset về 3 nếu đã bước sang ngày mới (Asia/Ho_Chi_Minh).
  Future<int> getRemainingEnergy();

  /// Tiêu thụ nguyên tử (atomic) Năng lượng (mặc định amount = 1).
  ///
  /// Quy trình:
  /// - Kiểm tra và reset ngày mới trước khi tiêu thụ.
  /// - Hỗ trợ [attemptId] và [reason] để đảm bảo Exactly-once và Idempotency bền vững.
  /// - Nếu [attemptId] đã từng bị trừ Energy cho bất kỳ terminal transition nào,
  ///   trả về số năng lượng hiện tại mà không trừ lần hai.
  /// - Nếu đủ năng lượng (remaining >= amount): trừ amount và lưu ngay, trả về số năng lượng còn lại (0..3).
  /// - Nếu không đủ năng lượng (remaining < amount): trả về `null` và không thay đổi dữ liệu.
  /// - Toàn bộ thao tác đọc/ghi được serialize qua Mutex để loại trừ race condition.
  Future<int?> consumeEnergy({
    int amount = 1,
    String? attemptId,
    String? reason,
  });

  /// Cộng thêm Năng lượng (chuẩn bị cho Rewarded Ads sau này).
  /// Năng lượng sau khi cộng luôn được clamp tối đa 3.
  Future<int> addEnergy(int amount);

  /// Nhận thưởng Năng lượng nguyên tử theo rewardId (Sub-phase 5.3).
  /// - Lưu remainingEnergy và claimed_rewards trong cùng một payload.
  /// - Dùng chung cơ chế serialize (Mutex) với consume/add/reset.
  /// - Idempotent: Nếu rewardId đã tồn tại, trả về alreadyClaimed = true, actualAdded = 0.
  Future<ClaimRewardResult> claimEnergyReward({
    required int amount,
    required String rewardId,
  });

  /// Đặt lại Năng lượng về mặc định 3 (dùng cho debug/test).
  Future<void> resetDailyEnergy();
}
