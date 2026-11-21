/// Trạng thái vòng đời của quá trình phục hồi khởi động (Startup Recovery).
/// Tầng Application Layer.
enum RecoveryStatus {
  /// Ứng dụng vừa khởi động, chưa bắt đầu tiến trình phục hồi. Gameplay bị khóa.
  initial,

  /// Đang trong quá trình quét đĩa, phân loại metadata và xử lý Outbox. Gameplay bị khóa.
  recovering,

  /// Phục hồi hoàn tất an toàn. Active Session slot đã sạch hoặc là ván đang chơi hợp lệ.
  /// Gameplay ĐƯỢC PHÉP hoạt động.
  ready,

  /// Phát hiện Completed Session nhưng chưa enqueue Outbox được hoặc clear session thất bại.
  /// Gameplay BỊ KHÓA CHẶT để bảo vệ dữ liệu ván thắng, ngăn ván mới ghi đè.
  blocked,

  /// Gặp lỗi I/O storage, file JSON hỏng hoặc ngoại lệ nghiêm trọng.
  /// Gameplay BỊ KHÓA CHẶT để bảo toàn dữ liệu gốc, không tự ý format đĩa.
  failedSafe,
}

/// Trạng thái bất biến (immutable) của Startup Recovery.
/// Được quản lý bởi StartupRecoveryController ở Sub-phase sau.
/// Tầng Application Layer.
class StartupRecoveryState {
  const StartupRecoveryState({
    required this.status,
    this.errorMessage,
    this.blockedLevelId,
    this.pendingEventsCount = 0,
  });

  /// Trạng thái khởi tạo mặc định khi ứng dụng vừa bật
  const StartupRecoveryState.initial()
      : status = RecoveryStatus.initial,
        errorMessage = null,
        blockedLevelId = null,
        pendingEventsCount = 0;

  final RecoveryStatus status;
  final String? errorMessage;
  final String? blockedLevelId;
  final int pendingEventsCount;

  /// Điều kiện tiên quyết DUY NHẤT để cho phép các API gameplay hoạt động:
  bool get canPlay => status == RecoveryStatus.ready;

  /// Đang trong tình trạng cần khóa để bảo vệ dữ liệu ván thắng hoặc dữ liệu lỗi:
  bool get isDataProtected =>
      status == RecoveryStatus.blocked || status == RecoveryStatus.failedSafe;

  /// Đang trong quá trình phục hồi:
  bool get isRecovering => status == RecoveryStatus.recovering;

  StartupRecoveryState copyWith({
    RecoveryStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? blockedLevelId,
    bool clearBlockedLevelId = false,
    int? pendingEventsCount,
  }) {
    return StartupRecoveryState(
      status: status ?? this.status,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      blockedLevelId:
          clearBlockedLevelId ? null : (blockedLevelId ?? this.blockedLevelId),
      pendingEventsCount: pendingEventsCount ?? this.pendingEventsCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StartupRecoveryState &&
          other.status == status &&
          other.errorMessage == errorMessage &&
          other.blockedLevelId == blockedLevelId &&
          other.pendingEventsCount == pendingEventsCount;

  @override
  int get hashCode => Object.hash(
        status,
        errorMessage,
        blockedLevelId,
        pendingEventsCount,
      );
}
