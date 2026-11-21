import '../entities/puzzle_color.dart';

/// Kết quả gợi ý nước đi cho người chơi.
/// Tầng Domain thuần Dart.
class HintResult {
  const HintResult({
    required this.nodeId,
    required this.color,
  });

  /// ID của node chưa tô màu được hệ thống chọn để gợi ý.
  final String nodeId;

  /// Màu sắc hợp lệ được đề xuất cho node này (lấy từ nghiệm hợp lệ của CSP Solver).
  final PuzzleColor color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HintResult &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          color == other.color;

  @override
  int get hashCode => nodeId.hashCode ^ color.hashCode;

  @override
  String toString() => 'HintResult(nodeId: $nodeId, color: ${color.label})';
}
