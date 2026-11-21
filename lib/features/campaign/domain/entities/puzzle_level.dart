import '../../../graph_coloring/domain/entities/color_inventory.dart';
import '../../../graph_coloring/domain/entities/graph.dart';
import '../../../graph_coloring/domain/entities/puzzle_color.dart';

/// Định nghĩa một màn chơi độc lập trong Campaign.
/// Tầng Domain thuần Dart.
class PuzzleLevel {
  const PuzzleLevel({
    required this.id,
    required this.chapterId,
    required this.levelNumber,
    required this.overallIndex,
    required this.title,
    this.titleEn,
    this.difficulty = 1.0,
    required this.initialGraph,
    required this.targetInventory,
  });

  /// Định danh duy nhất và ổn định của level (ví dụ: 'c1_l01').
  final String id;

  /// Chapter chứa level này (1..6).
  final int chapterId;

  /// Số thứ tự level trong Chapter (1..30).
  final int levelNumber;

  /// Số thứ tự tổng thể xuyên suốt Campaign (1..180).
  final int overallIndex;

  /// Tên gọi hoặc nhãn của màn chơi (Tiếng Việt mặc định).
  final String title;

  /// Tên gọi màn chơi bản địa hóa Tiếng Anh (nếu có).
  final String? titleEn;

  /// Điểm độ khó tham khảo (1.0 đến 5.0).
  final double difficulty;

  /// Đồ thị ban đầu (chứa các node, edge, locked node, restricted colors).
  final Graph initialGraph;

  /// Kho màu mục tiêu yêu cầu của màn chơi.
  final Map<PuzzleColor, int> targetInventory;

  /// Khởi tạo ColorInventory chính xác, tự động tính các Locked Node ban đầu vào usedCounts.
  ColorInventory createInitialInventory() {
    final initialUsed = <PuzzleColor, int>{
      for (final color in targetInventory.keys) color: 0,
    };

    for (final node in initialGraph.nodes.values) {
      if (node.currentColor != null) {
        final c = node.currentColor!;
        initialUsed[c] = (initialUsed[c] ?? 0) + 1;
      }
    }

    return ColorInventory(
      targetCounts: Map.unmodifiable(targetInventory),
      usedCounts: Map.unmodifiable(initialUsed),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PuzzleLevel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PuzzleLevel(id: $id, ch: $chapterId, num: $levelNumber, index: $overallIndex)';
}

