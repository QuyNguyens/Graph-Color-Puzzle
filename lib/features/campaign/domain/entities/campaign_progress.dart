import 'level_progress.dart';

/// Tiến trình toàn bộ Campaign của người chơi.
/// Tầng Domain thuần Dart.
class CampaignProgress {
  const CampaignProgress({
    required this.progressMap,
    required this.highestUnlockedLevelId,
  });

  /// Khởi tạo mặc định khi bắt đầu game: Level 1 mở sẵn, chưa có sao.
  factory CampaignProgress.initial() {
    return const CampaignProgress(
      progressMap: {
        'c1_l01': LevelProgress(
          levelId: 'c1_l01',
          isUnlocked: true,
          isCompleted: false,
          bestStars: 0,
        ),
      },
      highestUnlockedLevelId: 'c1_l01',
    );
  }

  /// Bảng tra cứu tiến trình từng màn chơi: Map<levelId, LevelProgress>.
  final Map<String, LevelProgress> progressMap;

  /// ID của level cao nhất đã mở khóa.
  final String highestUnlockedLevelId;

  /// Tổng số sao đã tích lũy được trên toàn bộ Campaign.
  int get totalStars =>
      progressMap.values.fold(0, (sum, p) => sum + p.bestStars);

  /// Tổng số màn đã hoàn thành.
  int get completedLevelsCount =>
      progressMap.values.where((p) => p.isCompleted).length;

  /// Lấy tiến trình của một màn chơi cụ thể (nếu chưa có trong map thì mặc định khóa, trừ c1_l01).
  LevelProgress getLevelProgress(String levelId) {
    return progressMap[levelId] ??
        LevelProgress(levelId: levelId, isUnlocked: levelId == 'c1_l01');
  }

  CampaignProgress copyWith({
    Map<String, LevelProgress>? progressMap,
    String? highestUnlockedLevelId,
  }) {
    return CampaignProgress(
      progressMap: progressMap ?? this.progressMap,
      highestUnlockedLevelId:
          highestUnlockedLevelId ?? this.highestUnlockedLevelId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CampaignProgress &&
        other.highestUnlockedLevelId == highestUnlockedLevelId &&
        _mapsEqual(other.progressMap, progressMap);
  }

  static bool _mapsEqual(Map<String, LevelProgress> a, Map<String, LevelProgress> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        highestUnlockedLevelId,
        Object.hashAll(progressMap.entries),
      );
}

