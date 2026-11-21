/// Định nghĩa 3 loại nhiệm vụ cố định của Daily Challenges.
enum DailyMissionType {
  completeLevels(
    id: 'mission_complete_levels',
    title: 'Chinh phục Đồ thị',
    description: 'Hoàn thành 2 màn chơi bất kỳ',
    target: 2,
    rewardEnergy: 1,
  ),
  noHint(
    id: 'mission_no_hint',
    title: 'Tự lực Cánh sinh',
    description: 'Hoàn thành 2 màn chơi không dùng Gợi ý',
    target: 2,
    rewardEnergy: 2,
  ),
  perfectGame(
    id: 'mission_perfect_game',
    title: 'Bậc thầy Hoàn hảo',
    description: 'Hoàn thành 1 màn chơi đạt 3 sao',
    target: 1,
    rewardEnergy: 3,
  );

  const DailyMissionType({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.rewardEnergy,
  });

  final String id;
  final String title;
  final String description;
  final int target;
  final int rewardEnergy;

  static DailyMissionType? fromId(String id) {
    for (final type in DailyMissionType.values) {
      if (type.id == id) return type;
    }
    return null;
  }
}

/// Thực thể nhiệm vụ hằng ngày bất biến (immutable entity).
/// Tầng Domain thuần Dart.
class DailyMission {
  const DailyMission({
    required this.type,
    this.currentProgress = 0,
    this.isClaimed = false,
  });

  final DailyMissionType type;
  final int currentProgress;
  final bool isClaimed;

  String get id => type.id;
  String get title => type.title;
  String get description => type.description;
  int get target => type.target;
  int get rewardEnergy => type.rewardEnergy;

  bool get isCompleted => currentProgress >= target;
  bool get canClaim => isCompleted && !isClaimed;

  DailyMission copyWith({
    int? currentProgress,
    bool? isClaimed,
  }) {
    return DailyMission(
      type: type,
      currentProgress: currentProgress ?? this.currentProgress,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyMission &&
        other.type == type &&
        other.currentProgress == currentProgress &&
        other.isClaimed == isClaimed;
  }

  @override
  int get hashCode => Object.hash(type, currentProgress, isClaimed);
}

