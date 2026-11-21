import 'daily_mission.dart';
import 'level_completion_event.dart';

/// Trạng thái tổng thể Daily Challenges trong một ngày cụ thể.
/// Tầng Domain thuần Dart.
class DailyChallengeState {
  const DailyChallengeState({
    required this.date,
    required this.missions,
    this.processedAttemptIds = const [],
  });

  /// Ngày áp dụng thử thách (YYYY-MM-DD)
  final String date;

  /// Danh sách 3 nhiệm vụ trong ngày
  final List<DailyMission> missions;

  /// Danh sách attemptId đã được tính tiến trình trong ngày hôm nay (chống cộng lặp)
  final List<String> processedAttemptIds;

  /// Khởi tạo trạng thái rỗng cho một ngày mới.
  factory DailyChallengeState.initial(String date) {
    return DailyChallengeState(
      date: date,
      missions: DailyMissionType.values
          .map((type) => DailyMission(type: type))
          .toList(),
      processedAttemptIds: const [],
    );
  }

  /// Kiểm tra xem lượt chơi này đã được tính tiến trình chưa.
  bool isAttemptProcessed(String attemptId) {
    return processedAttemptIds.contains(attemptId);
  }

  /// Tổng số Energy có thể nhận ngay lúc này (các nhiệm vụ đã hoàn thành nhưng chưa claim).
  int get totalClaimableEnergy => missions
      .where((m) => m.canClaim)
      .fold(0, (sum, m) => sum + m.rewardEnergy);

  /// Tất cả nhiệm vụ trong ngày đã hoàn thành và đã nhận thưởng hết chưa.
  bool get isAllClaimed => missions.every((m) => m.isClaimed);

  /// Cập nhật tiến độ nhiệm vụ khi có sự kiện hoàn thành màn chơi (idempotent theo attemptId).
  DailyChallengeState withCompletion(LevelCompletionEvent event) {
    if (isAttemptProcessed(event.attemptId)) {
      return this;
    }

    final updatedMissions = missions.map((mission) {
      if (mission.isCompleted) return mission;
      if (event.matchesMission(mission.type)) {
        final newProgress = (mission.currentProgress + 1).clamp(0, mission.target);
        return mission.copyWith(currentProgress: newProgress);
      }
      return mission;
    }).toList();

    return DailyChallengeState(
      date: date,
      missions: updatedMissions,
      processedAttemptIds: [...processedAttemptIds, event.attemptId],
    );
  }

  /// Cập nhật trạng thái nhiệm vụ sau khi nhận thưởng thành công.
  DailyChallengeState withClaimedMission(String missionId) {
    final updatedMissions = missions.map((mission) {
      if (mission.id == missionId) {
        return mission.copyWith(isClaimed: true);
      }
      return mission;
    }).toList();

    return DailyChallengeState(
      date: date,
      missions: updatedMissions,
      processedAttemptIds: processedAttemptIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyChallengeState &&
        other.date == date &&
        _listEquals(other.missions, missions) &&
        _listEquals(other.processedAttemptIds, processedAttemptIds);
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        date,
        Object.hashAll(missions),
        Object.hashAll(processedAttemptIds),
      );
}

