import 'daily_mission.dart';

/// Sự kiện ghi nhận hoàn thành một màn chơi (Completion Event).
/// Dữ liệu đầu vào cho quy trình Outbox và Daily Challenges.
/// Tầng Domain thuần Dart.
class LevelCompletionEvent {
  const LevelCompletionEvent({
    required this.attemptId,
    required this.levelId,
    required this.earnedStars,
    required this.hintsUsed,
    required this.mistakesCount,
    required this.completedDate,
    required this.timestampIso,
  });

  /// Định danh duy nhất cố định của lượt chơi (UUID v4)
  final String attemptId;

  /// ID của level vừa hoàn thành
  final String levelId;

  /// Số sao đạt được (1..3)
  final int earnedStars;

  /// Số lượt gợi ý đã sử dụng trong lượt chơi này
  final int hintsUsed;

  /// Tổng số lỗi đã mắc trong lượt chơi này
  final int mistakesCount;

  /// Ngày hoàn thành thực tế theo giờ địa phương (YYYY-MM-DD)
  final String completedDate;

  /// Thời điểm hoàn thành thực tế dạng ISO 8601
  final String timestampIso;

  /// Kiểm tra xem sự kiện này có thỏa mãn điều kiện của nhiệm vụ tương ứng không.
  bool matchesMission(DailyMissionType missionType) {
    switch (missionType) {
      case DailyMissionType.completeLevels:
        return true;
      case DailyMissionType.noHint:
        return hintsUsed == 0;
      case DailyMissionType.perfectGame:
        return earnedStars == 3;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelCompletionEvent &&
        other.attemptId == attemptId &&
        other.levelId == levelId &&
        other.earnedStars == earnedStars &&
        other.hintsUsed == hintsUsed &&
        other.mistakesCount == mistakesCount &&
        other.completedDate == completedDate &&
        other.timestampIso == timestampIso;
  }

  @override
  int get hashCode => Object.hash(
        attemptId,
        levelId,
        earnedStars,
        hintsUsed,
        mistakesCount,
        completedDate,
        timestampIso,
      );
}

