import '../../domain/entities/daily_challenge_state.dart';
import '../../domain/entities/daily_mission.dart';

/// DTO tuần tự hóa tiến độ từng nhiệm vụ.
class DailyMissionProgressDto {
  const DailyMissionProgressDto({
    required this.id,
    required this.progress,
    required this.isClaimed,
  });

  final String id;
  final int progress;
  final bool isClaimed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'progress': progress,
        'is_claimed': isClaimed,
      };

  factory DailyMissionProgressDto.fromJson(Map<String, dynamic> json) {
    return DailyMissionProgressDto(
      id: json['id'] as String? ?? '',
      progress: json['progress'] as int? ?? 0,
      isClaimed: json['is_claimed'] as bool? ?? false,
    );
  }
}

/// DTO tuần tự hóa toàn bộ trạng thái Daily Challenge của một ngày.
/// Hỗ trợ schema versioning và tiến hóa danh mục nhiệm vụ không làm mất tiến trình đang dở.
class DailyChallengeDto {
  const DailyChallengeDto({
    this.version = currentVersion,
    required this.date,
    required this.processedAttemptIds,
    required this.missions,
  });

  static const int currentVersion = 1;

  final int version;
  final String date;
  final List<String> processedAttemptIds;
  final List<DailyMissionProgressDto> missions;

  factory DailyChallengeDto.fromEntity(DailyChallengeState state) {
    return DailyChallengeDto(
      date: state.date,
      processedAttemptIds: state.processedAttemptIds,
      missions: state.missions
          .map((m) => DailyMissionProgressDto(
                id: m.id,
                progress: m.currentProgress,
                isClaimed: m.isClaimed,
              ))
          .toList(),
    );
  }

  DailyChallengeState toEntity() {
    final missionMap = <String, DailyMissionProgressDto>{
      for (final m in missions) m.id: m,
    };

    // Dung hòa an toàn với danh mục enum code hiện tại:
    // Các nhiệm vụ mới chưa có trong JSON sẽ được khởi tạo 0 tiến độ, không mất tiến độ cũ.
    final entityMissions = DailyMissionType.values.map((type) {
      final saved = missionMap[type.id];
      if (saved != null) {
        return DailyMission(
          type: type,
          currentProgress: saved.progress,
          isClaimed: saved.isClaimed,
        );
      }
      return DailyMission(type: type);
    }).toList();

    return DailyChallengeState(
      date: date,
      missions: entityMissions,
      processedAttemptIds: processedAttemptIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': currentVersion,
        'date': date,
        'processed_attempt_ids': processedAttemptIds,
        'missions': missions.map((m) => m.toJson()).toList(),
      };

  factory DailyChallengeDto.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String? ?? '';
    final rawAttempts = json['processed_attempt_ids'] as List<dynamic>? ?? [];
    final processedAttempts = rawAttempts.map((e) => e.toString()).toList();

    final rawMissions = json['missions'] as List<dynamic>? ?? [];
    final missions = rawMissions
        .map((m) => DailyMissionProgressDto.fromJson(m as Map<String, dynamic>))
        .toList();

    return DailyChallengeDto(
      version: json['version'] as int? ?? 1,
      date: rawDate,
      processedAttemptIds: processedAttempts,
      missions: missions,
    );
  }
}

