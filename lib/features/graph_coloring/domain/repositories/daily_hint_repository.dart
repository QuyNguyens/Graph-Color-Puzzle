/// Interface quản lý hạn ngạch Hint hằng ngày (Daily Hint Quota).
/// Tuân thủ Clean Architecture, Tầng Domain thuần Dart.
abstract class DailyHintRepository {
  /// Số lượt Hint miễn phí tối đa mỗi ngày.
  static const int maxDailyHints = 1;

  /// Lấy số lượt Hint còn lại trong ngày của người chơi (0..1+).
  /// Tự động kiểm tra và reset về 1 nếu đã bước sang ngày mới.
  Future<int> getRemainingHints();

  /// Tiêu thụ nguyên tử (atomic) 1 lượt Hint.
  ///
  /// Quy trình:
  /// - Kiểm tra và reset ngày mới trước khi tiêu thụ.
  /// - Nếu còn lượt (> 0): giảm 1 và lưu ngay lập tức, trả về số lượt còn lại (ví dụ: 0).
  /// - Nếu đã hết lượt (== 0): trả về `null` và không thay đổi dữ liệu.
  /// - Toàn bộ thao tác đọc/ghi được serialize để loại trừ race condition khi người dùng bấm liên tục.
  Future<int?> consumeHint();

  /// Thêm lượt Hint khi người chơi xem quảng cáo trả thưởng thành công.
  /// Trả về số lượt Hint mới sau khi cộng.
  Future<int> addHintReward({int amount = 1});

  /// Đặt lại hạn ngạch Hint về mặc định (dùng cho debug/test).
  Future<void> resetDailyHints();
}
