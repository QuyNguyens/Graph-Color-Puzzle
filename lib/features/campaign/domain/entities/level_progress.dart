/// Tiến trình của một màn chơi cụ thể trong Campaign.
/// Tầng Domain thuần Dart.
class LevelProgress {
  const LevelProgress({
    required this.levelId,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.bestStars = 0,
  });

  /// Định danh level.
  final String levelId;

  /// Đã được mở khóa hay chưa.
  final bool isUnlocked;

  /// Đã hoàn thành ít nhất một lần hay chưa.
  final bool isCompleted;

  /// Số sao cao nhất đã đạt được (0 đến 3).
  final int bestStars;

  LevelProgress copyWith({
    bool? isUnlocked,
    bool? isCompleted,
    int? bestStars,
  }) {
    return LevelProgress(
      levelId: levelId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      bestStars: bestStars ?? this.bestStars,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelProgress &&
        other.levelId == levelId &&
        other.isUnlocked == isUnlocked &&
        other.isCompleted == isCompleted &&
        other.bestStars == bestStars;
  }

  @override
  int get hashCode => Object.hash(levelId, isUnlocked, isCompleted, bestStars);

  @override
  String toString() =>
      'LevelProgress($levelId, unlocked: $isUnlocked, completed: $isCompleted, stars: $bestStars)';
}

