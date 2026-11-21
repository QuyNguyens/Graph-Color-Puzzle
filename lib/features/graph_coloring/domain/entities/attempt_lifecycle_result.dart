/// Kết quả thực thi một hành động vòng đời Attempt (Replay, Restart, Retry, Abandon).
/// Tầng Domain thuần Dart, giúp phân biệt rõ ràng các tình huống nghiệp vụ
/// mà không bắt UI phải phân tích chuỗi lỗi (Error String Parsing).
enum AttemptLifecycleResult {
  /// Thành công: Ván chơi mới đã được khởi tạo hoặc ván chơi cũ đã kết thúc an toàn.
  success,

  /// Thất bại: Không đủ Năng lượng (Energy = 0) để thực hiện hành động.
  /// Bàn cờ và active session được giữ nguyên vẹn 100%.
  insufficientEnergy,

  /// Thất bại: Trạng thái vòng đời hiện tại không hợp lệ cho hành động này
  /// (ví dụ: gọi restart khi game đã thắng hoặc đã thua, gọi retry khi game đang chơi).
  invalidLifecycleState,

  /// Thành công lặp (Idempotent): Thao tác terminal này đã được thực hiện trước đó cho attemptId.
  alreadyTerminated,

  /// Thất bại: Không thể ghi bộ nhớ cục bộ bền vững.
  persistenceFailure;

  bool get isSuccess =>
      this == AttemptLifecycleResult.success ||
      this == AttemptLifecycleResult.alreadyTerminated;

  bool get isInsufficientEnergy =>
      this == AttemptLifecycleResult.insufficientEnergy;
}
