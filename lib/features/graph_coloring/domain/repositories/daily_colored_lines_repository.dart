/// Interface quản lý hạn ngạch lượt sử dụng đường nối màu hằng ngày (Daily Colored Lines Quota).
/// Tuân thủ Clean Architecture, Tầng Domain thuần Dart.
abstract class DailyColoredLinesRepository {
  /// Số lượt sử dụng đường nối màu miễn phí tối đa mỗi ngày.
  static const int maxDailyQuota = 5;

  /// Lấy số lượt sử dụng đường nối màu còn lại trong ngày (0..5+).
  /// Tự động kiểm tra và reset về 5 nếu đã bước sang ngày mới (00:00).
  Future<int> getRemainingQuota();

  /// Tiêu thụ nguyên tử (atomic) 1 lượt khi kết thúc màn chơi (hoàn thành hoặc game over).
  ///
  /// Quy trình:
  /// - Kiểm tra và reset ngày mới trước khi tiêu thụ.
  /// - Nếu còn lượt (> 0): giảm 1 và lưu ngay lập tức, trả về số lượt còn lại (0..5+).
  /// - Nếu đã hết lượt (== 0): trả về `null` và không thay đổi dữ liệu.
  /// - Toàn bộ thao tác đọc/ghi được serialize để loại trừ race condition.
  Future<int?> consumeQuota();

  /// Thêm lượt sử dụng đường nối màu khi người chơi xem video quảng cáo nhận thưởng thành công.
  /// Trả về số lượt mới sau khi cộng.
  Future<int> addQuotaReward({int amount = 1});

  /// Đặt lại hạn ngạch về mặc định (dùng cho debug/test).
  Future<void> resetDailyQuota();
}
