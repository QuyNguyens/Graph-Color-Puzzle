import 'color_inventory.dart';
import 'graph.dart';
import 'graph_edge.dart';
import 'graph_node.dart';
import 'puzzle_color.dart';

/// Dữ liệu màn chơi mẫu phục vụ Phase 1 (Core Gameplay).
/// Thiết kế gồm 5 node, 1 Locked Node (Đỏ), 6 cạnh liên kết tạo tam giác và hình thoi.
/// Lời giải hợp lệ tồn tại: {1: Đỏ, 2: Xanh, 3: Vàng, 4: Đỏ, 5: Xanh}.
class MockLevelData {
  const MockLevelData._();

  static const String levelTitle = 'Màn chơi mẫu (Phase 1)';

  /// Khởi tạo trạng thái ban đầu của đồ thị.
  static Graph createInitialGraph() {
    final nodes = <String, GraphNode>{
      '1': const GraphNode(
        id: '1',
        x: 0.50,
        y: 0.18,
        isLocked: true,
        currentColor: PuzzleColor.red,
      ),
      '2': const GraphNode(
        id: '2',
        x: 0.22,
        y: 0.45,
      ),
      '3': const GraphNode(
        id: '3',
        x: 0.78,
        y: 0.45,
      ),
      '4': const GraphNode(
        id: '4',
        x: 0.32,
        y: 0.78,
      ),
      '5': const GraphNode(
        id: '5',
        x: 0.68,
        y: 0.78,
      ),
    };

    final edges = <GraphEdge>{
      const GraphEdge('1', '2'),
      const GraphEdge('1', '3'),
      const GraphEdge('2', '3'),
      const GraphEdge('2', '4'),
      const GraphEdge('3', '5'),
      const GraphEdge('4', '5'),
    };

    return Graph(nodes: nodes, edges: edges);
  }

  /// Khởi tạo ColorInventory chính xác cho level.
  /// Node 1 bị khóa màu Đỏ nên đã tiêu thụ 1 Đỏ ngay từ đầu.
  static ColorInventory createInitialInventory() {
    final targets = <PuzzleColor, int>{
      PuzzleColor.red: 2,
      PuzzleColor.blue: 2,
      PuzzleColor.yellow: 1,
    };

    final initialUsed = <PuzzleColor, int>{
      PuzzleColor.red: 1, // Đã gán cho Locked Node 1
      PuzzleColor.blue: 0,
      PuzzleColor.yellow: 0,
    };

    return ColorInventory(
      targetCounts: Map.unmodifiable(targets),
      usedCounts: Map.unmodifiable(initialUsed),
    );
  }
}

