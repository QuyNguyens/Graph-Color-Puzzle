import '../../domain/entities/level_completion_event.dart';

/// DTO tuần tự hóa sự kiện hoàn thành màn chơi trong hàng đợi Outbox.
/// Tầng Data Layer.
class PendingCompletionEventDto {
  const PendingCompletionEventDto({
    required this.attemptId,
    required this.levelId,
    required this.earnedStars,
    required this.hintsUsed,
    required this.mistakesCount,
    required this.completedDate,
    required this.timestampIso,
  });

  final String attemptId;
  final String levelId;
  final int earnedStars;
  final int hintsUsed;
  final int mistakesCount;
  final String completedDate;
  final String timestampIso;

  factory PendingCompletionEventDto.fromEntity(LevelCompletionEvent event) {
    return PendingCompletionEventDto(
      attemptId: event.attemptId,
      levelId: event.levelId,
      earnedStars: event.earnedStars,
      hintsUsed: event.hintsUsed,
      mistakesCount: event.mistakesCount,
      completedDate: event.completedDate,
      timestampIso: event.timestampIso,
    );
  }

  LevelCompletionEvent toEntity() {
    return LevelCompletionEvent(
      attemptId: attemptId,
      levelId: levelId,
      earnedStars: earnedStars,
      hintsUsed: hintsUsed,
      mistakesCount: mistakesCount,
      completedDate: completedDate,
      timestampIso: timestampIso,
    );
  }

  Map<String, dynamic> toJson() => {
        'attempt_id': attemptId,
        'level_id': levelId,
        'earned_stars': earnedStars,
        'hints_used': hintsUsed,
        'mistakes_count': mistakesCount,
        'completed_date': completedDate,
        'timestamp_iso': timestampIso,
      };

  factory PendingCompletionEventDto.fromJson(Map<String, dynamic> json) {
    return PendingCompletionEventDto(
      attemptId: json['attempt_id'] as String? ?? '',
      levelId: json['level_id'] as String? ?? '',
      earnedStars: json['earned_stars'] as int? ?? 1,
      hintsUsed: json['hints_used'] as int? ?? 0,
      mistakesCount: json['mistakes_count'] as int? ?? 0,
      completedDate: json['completed_date'] as String? ?? '',
      timestampIso: json['timestamp_iso'] as String? ?? '',
    );
  }
}

