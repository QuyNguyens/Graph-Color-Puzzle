import '../../domain/entities/game_move.dart';
import '../../domain/services/uuid_generator.dart';

/// DTO tuần tự hóa lịch sử nước đi.
class SavedMoveDto {
  const SavedMoveDto({
    required this.nodeId,
    required this.previousColorCode,
    required this.newColorCode,
    required this.timestampIso,
  });

  final String nodeId;
  final String? previousColorCode;
  final String? newColorCode;
  final String timestampIso;

  factory SavedMoveDto.fromEntity(GameMove move) {
    return SavedMoveDto(
      nodeId: move.nodeId,
      previousColorCode: move.previousColor?.code,
      newColorCode: move.newColor?.code,
      timestampIso: move.timestamp.toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'node_id': nodeId,
        'prev_color': previousColorCode,
        'new_color': newColorCode,
        'timestamp': timestampIso,
      };

  factory SavedMoveDto.fromJson(Map<String, dynamic> json) {
    return SavedMoveDto(
      nodeId: json['node_id'] as String,
      previousColorCode: json['prev_color'] as String?,
      newColorCode: json['new_color'] as String?,
      timestampIso: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

/// DTO tuần tự hóa toàn bộ trạng thái phiên chơi có kèm phiên bản schema.
/// Hỗ trợ Migration an toàn từ version 1, 2, 3 sang version 4 khi bổ sung:
/// - attemptId (UUID v4 cố định cho từng lượt chơi)
/// - completedAtIso (thời điểm hoàn thành thực tế nếu ván chơi đã thắng)
/// - earnedStars (số sao đạt được nếu ván chơi đã thắng)
class SavedSessionDto {
  const SavedSessionDto({
    this.version = currentVersion,
    this.attemptId = '',
    required this.levelId,
    required this.nodeColors,
    required this.remainingMistakes,
    required this.mistakesCount,
    this.hintsUsed = 0,
    required this.hasUsedContinue,
    this.hasUsedUndo = false,
    required this.undoHistory,
    this.completedAtIso,
    this.earnedStars,
  });

  /// Nâng cấp lên version 4 khi bổ sung attemptId và completion metadata
  static const int currentVersion = 4;

  final int version;
  final String attemptId;
  final String levelId;
  final Map<String, String?> nodeColors;
  final int remainingMistakes;
  final int mistakesCount;
  final int hintsUsed;
  final bool hasUsedContinue;
  final bool hasUsedUndo;
  final List<SavedMoveDto> undoHistory;
  final String? completedAtIso;
  final int? earnedStars;

  /// Kiểm tra xem JSON thô có thuộc schema legacy (v1, v2, v3) chưa có attemptId không
  static bool isLegacyJson(Map<String, dynamic> json) {
    final v = json['version'] as int? ?? 1;
    final att = json['attempt_id'] as String?;
    return v < currentVersion || att == null || att.trim().isEmpty;
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'attempt_id': attemptId.isNotEmpty ? attemptId : UuidGenerator.generateAttemptId(levelId),
        'level_id': levelId,
        'node_colors': nodeColors,
        'remaining_mistakes': remainingMistakes,
        'mistakes_count': mistakesCount,
        'hints_used': hintsUsed,
        'has_used_continue': hasUsedContinue,
        'has_used_undo': hasUsedUndo,
        'undo_history': undoHistory.map((m) => m.toJson()).toList(),
        if (completedAtIso != null) 'completed_at': completedAtIso,
        if (earnedStars != null) 'earned_stars': earnedStars,
      };

  factory SavedSessionDto.fromJson(
    Map<String, dynamic> json, {
    String? assignedAttemptId,
  }) {
    final version = json['version'] as int? ?? 1;
    if (version > currentVersion) {
      throw FormatException('Không hỗ trợ schema version $version (hiện tại: $currentVersion)');
    }

    final levelId = json['level_id'] as String? ?? '';

    // Cơ chế Migration version 1..3 -> version 4:
    // Nếu có attempt_id hợp lệ thì sử dụng, nếu không dùng assignedAttemptId hoặc sinh UUID mới
    final String attemptId;
    if (json.containsKey('attempt_id') &&
        json['attempt_id'] != null &&
        (json['attempt_id'] as String).trim().isNotEmpty) {
      attemptId = json['attempt_id'] as String;
    } else if (assignedAttemptId != null && assignedAttemptId.trim().isNotEmpty) {
      attemptId = assignedAttemptId;
    } else {
      attemptId = UuidGenerator.generateAttemptId(levelId);
    }

    final rawColors = json['node_colors'] as Map<String, dynamic>? ?? {};
    final nodeColors = rawColors.map((k, v) => MapEntry(k, v as String?));

    final rawHistory = json['undo_history'] as List<dynamic>? ?? [];
    final history = rawHistory
        .map((m) => SavedMoveDto.fromJson(m as Map<String, dynamic>))
        .toList();

    final remainingMistakes = json['remaining_mistakes'] as int? ?? 2;

    // Migration version 1 -> version 2:
    final int mistakesCount;
    if (json.containsKey('mistakes_count')) {
      mistakesCount = json['mistakes_count'] as int? ?? 0;
    } else {
      mistakesCount = (2 - remainingMistakes).clamp(0, 2);
    }

    // Migration version 1 & 2 -> version 3:
    final int hintsUsed = json['hints_used'] as int? ?? 0;

    // Metadata hoàn thành (version 4)
    final completedAtIso = json['completed_at'] as String?;
    final earnedStars = json['earned_stars'] as int?;

    return SavedSessionDto(
      version: version,
      attemptId: attemptId,
      levelId: levelId,
      nodeColors: nodeColors,
      remainingMistakes: remainingMistakes,
      mistakesCount: mistakesCount,
      hintsUsed: hintsUsed,
      hasUsedContinue: json['has_used_continue'] as bool? ?? false,
      hasUsedUndo: json['has_used_undo'] as bool? ?? false,
      undoHistory: history,
      completedAtIso: completedAtIso,
      earnedStars: earnedStars,
    );
  }
}
