/// Thông tin định nghĩa một Chapter trong chế độ Campaign.
/// Tầng Domain thuần Dart.
class ChapterInfo {
  const ChapterInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    this.levelCount = 30,
    required this.startOverallIndex,
    required this.endOverallIndex,
  });

  final int id;
  final String title;
  final String subtitle;
  final int levelCount;
  final int startOverallIndex;
  final int endOverallIndex;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ChapterInfo(id: $id, title: $title, levels: $startOverallIndex-$endOverallIndex)';
}

