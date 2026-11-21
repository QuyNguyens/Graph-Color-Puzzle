import '../../domain/entities/campaign_progress.dart';
import '../../domain/entities/level_progress.dart';

/// DTO tuần tự hóa tiến trình của một màn chơi cụ thể.
class LevelProgressDto {
  const LevelProgressDto({
    required this.levelId,
    required this.isUnlocked,
    required this.isCompleted,
    required this.bestStars,
  });

  final String levelId;
  final bool isUnlocked;
  final bool isCompleted;
  final int bestStars;

  factory LevelProgressDto.fromEntity(LevelProgress entity) {
    return LevelProgressDto(
      levelId: entity.levelId,
      isUnlocked: entity.isUnlocked,
      isCompleted: entity.isCompleted,
      bestStars: entity.bestStars,
    );
  }

  LevelProgress toEntity() {
    return LevelProgress(
      levelId: levelId,
      isUnlocked: isUnlocked,
      isCompleted: isCompleted,
      bestStars: bestStars.clamp(0, 3),
    );
  }

  Map<String, dynamic> toJson() => {
        'level_id': levelId,
        'is_unlocked': isUnlocked,
        'is_completed': isCompleted,
        'best_stars': bestStars,
      };

  factory LevelProgressDto.fromJson(Map<String, dynamic> json) {
    final id = json['level_id'] as String? ?? '';
    final isUnlocked = json['is_unlocked'] as bool? ?? (id == 'c1_l01');
    final isCompleted = json['is_completed'] as bool? ?? false;
    final bestStars = (json['best_stars'] as int? ?? 0).clamp(0, 3);

    return LevelProgressDto(
      levelId: id,
      isUnlocked: isUnlocked,
      isCompleted: isCompleted,
      bestStars: bestStars,
    );
  }
}

/// DTO tuần tự hóa toàn bộ tiến trình Campaign kèm quản lý schema version.
class CampaignProgressDto {
  const CampaignProgressDto({
    this.version = currentVersion,
    required this.highestUnlockedLevelId,
    required this.levels,
  });

  static const int currentVersion = 1;

  final int version;
  final String highestUnlockedLevelId;
  final Map<String, LevelProgressDto> levels;

  factory CampaignProgressDto.fromEntity(CampaignProgress entity) {
    final levelsDto = entity.progressMap.map(
      (k, v) => MapEntry(k, LevelProgressDto.fromEntity(v)),
    );

    return CampaignProgressDto(
      version: currentVersion,
      highestUnlockedLevelId: entity.highestUnlockedLevelId,
      levels: levelsDto,
    );
  }

  CampaignProgress toEntity() {
    final progressMap = levels.map((k, v) => MapEntry(k, v.toEntity()));

    // Đảm bảo Level 1 luôn tồn tại và mở khóa
    if (!progressMap.containsKey('c1_l01')) {
      progressMap['c1_l01'] = const LevelProgress(
        levelId: 'c1_l01',
        isUnlocked: true,
        isCompleted: false,
        bestStars: 0,
      );
    }

    final highestId = highestUnlockedLevelId.isNotEmpty
        ? highestUnlockedLevelId
        : 'c1_l01';

    return CampaignProgress(
      progressMap: progressMap,
      highestUnlockedLevelId: highestId,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': currentVersion,
        'highest_unlocked_level_id': highestUnlockedLevelId,
        'levels': levels.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory CampaignProgressDto.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    final highestUnlocked =
        json['highest_unlocked_level_id'] as String? ?? 'c1_l01';

    final rawLevels = json['levels'];
    final levels = <String, LevelProgressDto>{};

    if (rawLevels is Map<String, dynamic>) {
      for (final entry in rawLevels.entries) {
        if (entry.value is Map<String, dynamic>) {
          levels[entry.key] =
              LevelProgressDto.fromJson(entry.value as Map<String, dynamic>);
        }
      }
    }

    return CampaignProgressDto(
      version: version,
      highestUnlockedLevelId: highestUnlocked,
      levels: levels,
    );
  }
}

