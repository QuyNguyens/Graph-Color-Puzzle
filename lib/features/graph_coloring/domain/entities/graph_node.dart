import 'puzzle_color.dart';

/// Đại diện cho 1 đỉnh trong đồ thị.
/// Tọa độ (x, y) là giá trị chuẩn hóa trong khoảng [0.0, 1.0] để co giãn responsive.
/// Hỗ trợ [restrictedColors] (tập màu giới hạn) cho Chapter 5 theo GDD.
/// Tầng Domain thuần Dart.
class GraphNode {
  const GraphNode({
    required this.id,
    required this.x,
    required this.y,
    this.isLocked = false,
    this.currentColor,
    this.restrictedColors,
  });

  final String id;
  final double x;
  final double y;
  final bool isLocked;
  final PuzzleColor? currentColor;

  /// Tập màu giới hạn mà node này được phép nhận.
  /// - Nếu null: cho phép mọi màu hợp lệ theo Inventory.
  /// - Nếu có giá trị: chỉ cho phép các màu nằm trong tập hợp này.
  final Set<PuzzleColor>? restrictedColors;

  bool get isColored => currentColor != null;

  /// Kiểm tra xem node có chấp nhận màu [color] theo tập giới hạn hay không.
  bool allowsColor(PuzzleColor color) {
    if (restrictedColors == null) return true;
    return restrictedColors!.contains(color);
  }

  GraphNode copyWith({
    PuzzleColor? currentColor,
    bool clearColor = false,
    Set<PuzzleColor>? restrictedColors,
  }) {
    return GraphNode(
      id: id,
      x: x,
      y: y,
      isLocked: isLocked,
      currentColor: clearColor ? null : (currentColor ?? this.currentColor),
      restrictedColors: restrictedColors ?? this.restrictedColors,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphNode &&
        other.id == id &&
        other.x == x &&
        other.y == y &&
        other.isLocked == isLocked &&
        other.currentColor == currentColor &&
        _setsEqual(other.restrictedColors, restrictedColors);
  }

  static bool _setsEqual(Set<PuzzleColor>? a, Set<PuzzleColor>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.length == b.length && a.containsAll(b);
  }

  @override
  int get hashCode => Object.hash(
        id,
        x,
        y,
        isLocked,
        currentColor,
        restrictedColors != null ? Object.hashAll(restrictedColors!) : null,
      );

  @override
  String toString() =>
      'GraphNode(id: $id, pos: ($x, $y), locked: $isLocked, color: $currentColor, restricted: $restrictedColors)';
}
