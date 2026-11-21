import 'puzzle_color.dart';

/// Đại diện cho 1 nước đi hợp lệ đã thực hiện trên bàn cờ.
/// Phục vụ cơ chế Undo (Hoàn tác).
/// Tầng Domain thuần Dart.
class GameMove {
  const GameMove({
    required this.nodeId,
    required this.previousColor,
    required this.newColor,
    required this.timestamp,
  });

  /// ID của node vừa thực hiện thao tác.
  final String nodeId;

  /// Màu trước khi thực hiện thao tác (null nếu node trước đó chưa có màu).
  final PuzzleColor? previousColor;

  /// Màu mới được gán cho node (null nếu thao tác là xóa màu).
  final PuzzleColor? newColor;

  /// Thời điểm thực hiện nước đi.
  final DateTime timestamp;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameMove &&
        other.nodeId == nodeId &&
        other.previousColor == previousColor &&
        other.newColor == newColor &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(nodeId, previousColor, newColor, timestamp);

  @override
  String toString() =>
      'GameMove(nodeId: $nodeId, from: ${previousColor?.code} -> to: ${newColor?.code})';
}

