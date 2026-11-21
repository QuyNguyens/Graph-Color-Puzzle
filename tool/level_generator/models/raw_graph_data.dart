import 'dart:math';

/// Dữ liệu node thô trong quá trình sinh đồ thị offline.
class RawNodeData {
  RawNodeData(this.id, this.x, this.y);

  final String id;
  double x;
  double y;

  RawNodeData copyWith({String? id, double? x, double? y}) {
    return RawNodeData(id ?? this.id, x ?? this.x, y ?? this.y);
  }

  @override
  String toString() => '$id(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})';
}

/// Cạnh vô hướng biểu diễn bằng 2 chỉ số node trong danh sách nodes.
class RawEdgePair {
  const RawEdgePair(this.uIndex, this.vIndex) : assert(uIndex != vIndex);

  final int uIndex;
  final int vIndex;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RawEdgePair &&
        ((other.uIndex == uIndex && other.vIndex == vIndex) ||
            (other.uIndex == vIndex && other.vIndex == uIndex));
  }

  @override
  int get hashCode => uIndex < vIndex
      ? Object.hash(uIndex, vIndex)
      : Object.hash(vIndex, uIndex);

  @override
  String toString() => '($uIndex <-> $vIndex)';
}

/// Đồ thị thô chứa danh sách node và các cạnh trước khi chuyển đổi sang Domain Graph.
class RawGraphData {
  RawGraphData({
    required this.nodes,
    required this.edges,
    this.family = 'custom',
  });

  final List<RawNodeData> nodes;
  final Set<RawEdgePair> edges;
  final String family;

  int get nodeCount => nodes.length;
  int get edgeCount => edges.length;

  /// Danh sách kề dạng index
  List<Set<int>> buildAdjacencyList() {
    final adj = List.generate(nodes.length, (_) => <int>{});
    for (final e in edges) {
      adj[e.uIndex].add(e.vIndex);
      adj[e.vIndex].add(e.uIndex);
    }
    return adj;
  }

  /// Tính khoảng cách Euclid giữa 2 node
  double distanceBetween(int i, int j) {
    final dx = nodes[i].x - nodes[j].x;
    final dy = nodes[i].y - nodes[j].y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Khoảng cách tối thiểu giữa mọi cặp node
  double minNodeDistance() {
    if (nodes.length < 2) return 1.0;
    double minDist = double.infinity;
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final d = distanceBetween(i, j);
        if (d < minDist) minDist = d;
      }
    }
    return minDist;
  }
}
