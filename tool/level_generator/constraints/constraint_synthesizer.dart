import 'dart:math';
import 'package:graph_coloring/features/campaign/domain/entities/puzzle_level.dart';
import 'package:graph_coloring/features/graph_coloring/domain/algorithms/csp_solver.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/graph.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/graph_edge.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/graph_node.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/puzzle_color.dart';
import '../models/raw_graph_data.dart';

/// Bộ phận tổng hợp lời giải, kho màu (Inventory) và các ràng buộc (Locked & Restricted)
/// đảm bảo nghiệm tuyệt đối tồn tại và tuân thủ chặt chẽ Domain Rules.
class ConstraintSynthesizer {
  const ConstraintSynthesizer({
    this.solver = const CspSolver(),
  });

  final CspSolver solver;

  /// Tìm một phép tô màu hợp lệ (Proper Vertex Coloring) dùng đủ số lượng màu yêu cầu.
  Map<int, PuzzleColor>? findProperColoring(
    RawGraphData raw,
    List<PuzzleColor> palette, {
    required int requiredDistinctColors,
    int seed = 42,
  }) {
    final n = raw.nodes.length;
    final adj = raw.buildAdjacencyList();
    final assignment = <int, PuzzleColor>{};
    final rand = Random(seed);

    // Xáo trộn thứ tự thử màu theo seed để tăng tính đa dạng
    final shuffledPalette = List<PuzzleColor>.from(palette)..shuffle(rand);

    // DSATUR / MRV ordering: Ưu tiên node có bậc lớn nhất
    final nodeOrder = List<int>.generate(n, (i) => i)
      ..sort((a, b) => adj[b].length.compareTo(adj[a].length));

    bool backtrack(int orderIdx) {
      if (orderIdx == n) {
        final distinct = assignment.values.toSet().length;
        return distinct == requiredDistinctColors;
      }

      final u = nodeOrder[orderIdx];
      for (final color in shuffledPalette) {
        bool conflict = false;
        for (final v in adj[u]) {
          if (assignment[v] == color) {
            conflict = true;
            break;
          }
        }
        if (!conflict) {
          assignment[u] = color;
          if (backtrack(orderIdx + 1)) return true;
          assignment.remove(u);
        }
      }
      return false;
    }

    if (backtrack(0)) return assignment;
    return null;
  }

  /// Tổng hợp và tạo đối tượng PuzzleLevel hoàn chỉnh.
  PuzzleLevel synthesizeLevel({
    required String id,
    required int chapterId,
    required int levelNumber,
    required int overallIndex,
    required String title,
    required double difficulty,
    required RawGraphData raw,
    required List<PuzzleColor> palette,
    required int requiredDistinctColors,
    List<int>? lockedNodeIndices,
    List<int>? restrictedNodeIndices,
    int seed = 42,
  }) {
    final coloring = findProperColoring(
      raw,
      palette,
      requiredDistinctColors: requiredDistinctColors,
      seed: seed,
    );

    if (coloring == null) {
      throw StateError(
        'Không thể tìm thấy Proper Coloring cho $id với $requiredDistinctColors màu trên ${raw.nodeCount} nodes.',
      );
    }

    // 1. Tạo Target Inventory từ nghiệm
    final targetInventory = <PuzzleColor, int>{};
    for (final color in palette) {
      final count = coloring.values.where((c) => c == color).length;
      if (count > 0) {
        targetInventory[color] = count;
      }
    }

    // 2. Xử lý Locked Nodes
    final lockedSet = <int>{};
    if (lockedNodeIndices != null && lockedNodeIndices.isNotEmpty) {
      final adj = raw.buildAdjacencyList();
      for (final idx in lockedNodeIndices) {
        if (idx < raw.nodes.length) {
          // Kiểm tra xem có node kề nào đã locked có cùng màu không
          bool conflict = false;
          for (final neighbor in adj[idx]) {
            if (lockedSet.contains(neighbor) && coloring[neighbor] == coloring[idx]) {
              conflict = true;
              break;
            }
          }
          if (!conflict) {
            lockedSet.add(idx);
          }
        }
      }
    }

    // Đảm bảo Chapter 3, 4, 6 luôn có ít nhất 1 Locked Node hợp lệ theo quy định GDD
    if ((chapterId == 3 || chapterId == 4 || chapterId == 6) && lockedSet.isEmpty) {
      lockedSet.add(0);
    }

    // 3. Xử lý Restricted Colors
    final restrictedMap = <int, Set<PuzzleColor>>{};
    if (restrictedNodeIndices != null && restrictedNodeIndices.isNotEmpty) {
      final targetColorsList = targetInventory.keys.toList();
      for (final idx in restrictedNodeIndices) {
        if (idx < raw.nodes.length && !lockedSet.contains(idx)) {
          final validColor = coloring[idx]!;
          // Tập restricted bao gồm validColor + 1 hoặc 2 màu khác từ targetInventory (nhưng không phải tất cả)
          if (targetColorsList.length >= 3) {
            final allowed = <PuzzleColor>{validColor};
            for (final c in targetColorsList) {
              if (c != validColor && allowed.length < targetColorsList.length - 1) {
                allowed.add(c);
              }
            }
            restrictedMap[idx] = allowed;
          }
        }
      }
    }

    // Đảm bảo Chapter 5, 6 luôn có ít nhất 1 Restricted Node hợp lệ theo quy định GDD
    if ((chapterId == 5 || chapterId == 6) && restrictedMap.isEmpty) {
      final targetColorsList = targetInventory.keys.toList();
      for (int i = 0; i < raw.nodes.length; i++) {
        if (!lockedSet.contains(i)) {
          final validColor = coloring[i]!;
          if (targetColorsList.length >= 3) {
            final allowed = <PuzzleColor>{validColor};
            for (final c in targetColorsList) {
              if (c != validColor && allowed.length < targetColorsList.length - 1) {
                allowed.add(c);
              }
            }
            restrictedMap[i] = allowed;
            break;
          }
        }
      }
    }

    // 4. Tạo các domain GraphNode
    final domainNodes = <String, GraphNode>{};
    for (int i = 0; i < raw.nodes.length; i++) {
      final rn = raw.nodes[i];
      final isLocked = lockedSet.contains(i);
      domainNodes[rn.id] = GraphNode(
        id: rn.id,
        x: rn.x,
        y: rn.y,
        isLocked: isLocked,
        currentColor: isLocked ? coloring[i] : null,
        restrictedColors: restrictedMap[i],
      );
    }

    // 5. Tạo các domain GraphEdge
    final domainEdges = <GraphEdge>{};
    for (final e in raw.edges) {
      final uId = raw.nodes[e.uIndex].id;
      final vId = raw.nodes[e.vIndex].id;
      domainEdges.add(GraphEdge(uId, vId));
    }

    final initialGraph = Graph(nodes: domainNodes, edges: domainEdges);

    return PuzzleLevel(
      id: id,
      chapterId: chapterId,
      levelNumber: levelNumber,
      overallIndex: overallIndex,
      title: title,
      difficulty: difficulty,
      initialGraph: initialGraph,
      targetInventory: targetInventory,
    );
  }
}
