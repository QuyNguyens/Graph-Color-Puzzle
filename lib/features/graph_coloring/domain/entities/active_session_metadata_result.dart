/// Kết quả thẩm định siêu dữ liệu phiên chơi hiện tại (Metadata Inspection).
/// Tầng Domain thuần Dart, không phụ thuộc Framework hay DataSource.
sealed class ActiveSessionMetadataResult {
  const ActiveSessionMetadataResult();
}

/// 1. Không có Active Session trên bộ nhớ cục bộ (key null hoặc chuỗi rỗng).
class NoActiveSessionResult extends ActiveSessionMetadataResult {
  const NoActiveSessionResult();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoActiveSessionResult;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// 2. Session ván chơi dở dang hợp lệ (đang chơi, chưa hoàn thành).
class ValidPlayingSessionResult extends ActiveSessionMetadataResult {
  const ValidPlayingSessionResult({
    required this.levelId,
    required this.attemptId,
    required this.mistakesCount,
    required this.hintsUsed,
  });

  final String levelId;
  final String attemptId;
  final int mistakesCount;
  final int hintsUsed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidPlayingSessionResult &&
          other.levelId == levelId &&
          other.attemptId == attemptId &&
          other.mistakesCount == mistakesCount &&
          other.hintsUsed == hintsUsed;

  @override
  int get hashCode => Object.hash(levelId, attemptId, mistakesCount, hintsUsed);
}

/// 3. Session ván chơi đã thắng hợp lệ (đã hoàn thành, đang chờ phân phối/dọn dẹp).
class ValidCompletedSessionResult extends ActiveSessionMetadataResult {
  const ValidCompletedSessionResult({
    required this.levelId,
    required this.attemptId,
    required this.earnedStars,
    required this.hintsUsed,
    required this.mistakesCount,
    required this.completedAtIso,
  });

  final String levelId;
  final String attemptId;
  final int earnedStars;
  final int hintsUsed;
  final int mistakesCount;
  final String completedAtIso;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidCompletedSessionResult &&
          other.levelId == levelId &&
          other.attemptId == attemptId &&
          other.earnedStars == earnedStars &&
          other.hintsUsed == hintsUsed &&
          other.mistakesCount == mistakesCount &&
          other.completedAtIso == completedAtIso;

  @override
  int get hashCode => Object.hash(
        levelId,
        attemptId,
        earnedStars,
        hintsUsed,
        mistakesCount,
        completedAtIso,
      );
}

/// 4. Dữ liệu Session bị hỏng cú pháp, thiếu trường bắt buộc hoặc không hợp lệ.
class CorruptedSessionMetadataResult extends ActiveSessionMetadataResult {
  const CorruptedSessionMetadataResult({
    required this.reason,
    this.rawLevelId,
    this.error,
  });

  final String reason;
  final String? rawLevelId;
  final Object? error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorruptedSessionMetadataResult &&
          other.reason == reason &&
          other.rawLevelId == rawLevelId &&
          other.error == error;

  @override
  int get hashCode => Object.hash(reason, rawLevelId, error);
}

/// 5. Lỗi truy cập storage tạm thời (SharedPreferences / I/O platform failure).
/// Dữ liệu trên đĩa không bị hỏng, chỉ là không thể truy cập tại thời điểm kiểm tra.
class TransientSessionMetadataErrorResult extends ActiveSessionMetadataResult {
  const TransientSessionMetadataErrorResult({
    required this.reason,
    this.error,
  });

  final String reason;
  final Object? error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransientSessionMetadataErrorResult &&
          other.reason == reason &&
          other.error == error;

  @override
  int get hashCode => Object.hash(reason, error);
}
