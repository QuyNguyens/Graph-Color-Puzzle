import 'graph_edge.dart';
import 'graph_node.dart';
import 'puzzle_color.dart';

/// Cấu trúc đồ thị vô hướng trong bài toán tô màu.
/// Đảm bảo tính bất biến (immutable) và tra cứu lân cận O(1).
/// Tầng Domain thuần Dart.
class Graph {
  Graph({
    required Map<String, GraphNode> nodes,
    required Set<GraphEdge> edges,
  })  : nodes = Map.unmodifiable(nodes),
        edges = Set.unmodifiable(edges),
        adjacencyList = _buildAdjacencyList(nodes.keys, edges);

  final Map<String, GraphNode> nodes;
  final Set<GraphEdge> edges;
  final Map<String, Set<String>> adjacencyList;

  static Map<String, Set<String>> _buildAdjacencyList(
    Iterable<String> nodeIds,
    Set<GraphEdge> edges,
  ) {
    final adj = <String, Set<String>>{
      for (final id in nodeIds) id: <String>{},
    };
    for (final edge in edges) {
      adj[edge.u]?.add(edge.v);
      adj[edge.v]?.add(edge.u);
    }
    return Map.unmodifiable(
      adj.map((key, value) => MapEntry(key, Set.unmodifiable(value))),
    );
  }

  Set<String> getNeighbors(String nodeId) =>
      adjacencyList[nodeId] ?? const <String>{};

  GraphNode? getNode(String nodeId) => nodes[nodeId];

  /// Kiểm tra xem nếu gán màu [color] cho node [nodeId] thì có bị trùng màu với bất kỳ node kề nào không.
  bool hasAdjacentConflict(String nodeId, PuzzleColor color) {
    final neighbors = getNeighbors(nodeId);
    for (final neighborId in neighbors) {
      final neighbor = nodes[neighborId];
      if (neighbor != null && neighbor.currentColor == color) {
        return true;
      }
    }
    return false;
  }

  /// Kiểm tra xem đồ thị hiện tại có tồn tại bất kỳ cặp node kề nào cùng màu không.
  bool hasAnyConflict() {
    for (final edge in edges) {
      final nodeU = nodes[edge.u];
      final nodeV = nodes[edge.v];
      if (nodeU != null &&
          nodeV != null &&
          nodeU.currentColor != null &&
          nodeU.currentColor == nodeV.currentColor) {
        return true;
      }
    }
    return false;
  }

  /// Kiểm tra tất cả các node trong đồ thị đã được tô màu hay chưa.
  bool get isAllColored => nodes.values.every((node) => node.isColored);

  /// Tạo một phiên bản đồ thị mới với node được cập nhật.
  Graph withUpdatedNode(GraphNode updatedNode) {
    final newNodes = Map<String, GraphNode>.from(nodes);
    newNodes[updatedNode.id] = updatedNode;
    return Graph(nodes: newNodes, edges: edges);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Graph) return false;
    if (nodes.length != other.nodes.length || edges.length != other.edges.length) {
      return false;
    }
    for (final entry in nodes.entries) {
      if (other.nodes[entry.key] != entry.value) return false;
    }
    return edges.containsAll(other.edges);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(nodes.entries),
        Object.hashAll(edges),
      );
}

