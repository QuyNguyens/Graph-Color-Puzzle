import '../algorithms/csp_solver.dart';
import '../algorithms/solver_interface.dart';
import '../entities/color_inventory.dart';
import '../entities/graph.dart';
import '../entities/graph_node.dart';
import '../entities/hint_result.dart';
import '../entities/puzzle_color.dart';

/// Service tạo gợi ý nước đi tối ưu cho người chơi dựa trên CSP Solver.
///
/// Tuân thủ quy tắc GDD Mục 6.2 & 6.3:
/// - Dựa trên nghiệm hợp lệ tìm bởi CSP Solver từ trạng thái bàn cờ hiện tại.
/// - Chỉ chọn node chưa tô màu và không bị khóa.
/// - Áp dụng Heuristic: MRV (Minimum Remaining Values) -> DSATUR -> Degree.
/// - Lấy màu gợi ý từ nghiệm đã tìm được.
/// - Tầng Domain thuần Dart, không phụ thuộc Flutter.
class HintService {
  const HintService({
    GraphColoringSolver? solver,
  }) : _solver = solver ?? const CspSolver();

  final GraphColoringSolver _solver;

  /// Tạo gợi ý nước đi từ trạng thái hiện tại của bàn cờ.
  /// Trả về [HintResult] nếu tìm thấy nghiệm hợp lệ, hoặc `null` nếu:
  /// - Không còn node nào chưa tô màu phù hợp.
  /// - Bàn cờ đang rơi vào ngõ cụt, không còn lời giải hợp lệ.
  HintResult? generateHint({
    required Graph graph,
    required ColorInventory inventory,
  }) {
    // 1. Lọc danh sách các node chưa tô màu và không bị khóa
    final candidateNodes = graph.nodes.values
        .where((node) => node.currentColor == null && !node.isLocked)
        .toList();

    if (candidateNodes.isEmpty) {
      return null;
    }

    // 2. Chạy Solver 1 lần duy nhất để tìm nghiệm toàn cục từ trạng thái hiện tại
    final solution = _solver.findSolution(
      graph: graph,
      inventory: inventory,
    );

    // Nếu không còn nghiệm hợp lệ nào -> trả về null
    if (solution == null) {
      return null;
    }

    // 3. Sắp xếp các node ứng viên theo Heuristic:
    // Tiêu chí 1: MRV (Số màu hợp lệ cục bộ còn lại ít nhất)
    // Tiêu chí 2: DSATUR (Số màu khác nhau xuất hiện ở các đỉnh kề nhiều nhất)
    // Tiêu chí 3: Degree (Bậc kết nối cao nhất)
    candidateNodes.sort((a, b) {
      final domainSizeA = _calculateLocalDomainSize(graph, inventory, a);
      final domainSizeB = _calculateLocalDomainSize(graph, inventory, b);
      final mrvComparison = domainSizeA.compareTo(domainSizeB);
      if (mrvComparison != 0) return mrvComparison;

      final satA = _calculateSaturationDegree(graph, a.id);
      final satB = _calculateSaturationDegree(graph, b.id);
      final satComparison = satB.compareTo(satA); // Giảm dần
      if (satComparison != 0) return satComparison;

      final degA = graph.getNeighbors(a.id).length;
      final degB = graph.getNeighbors(b.id).length;
      return degB.compareTo(degA); // Giảm dần
    });

    final bestNode = candidateNodes.first;
    final suggestedColor = solution[bestNode.id];

    if (suggestedColor == null) {
      return null;
    }

    return HintResult(
      nodeId: bestNode.id,
      color: suggestedColor,
    );
  }

  /// Tính kích thước Domain cục bộ của node (MRV Heuristic):
  /// Đếm số màu còn trong kho, không xung đột với các đỉnh kề và được node cho phép.
  int _calculateLocalDomainSize(
    Graph graph,
    ColorInventory inventory,
    GraphNode node,
  ) {
    int validCount = 0;
    for (final color in inventory.targetCounts.keys) {
      if (inventory.isAvailable(color) &&
          node.allowsColor(color) &&
          !graph.hasAdjacentConflict(node.id, color)) {
        validCount++;
      }
    }
    return validCount;
  }

  /// Tính bậc bão hòa màu của node (DSATUR Heuristic):
  /// Đếm số lượng màu khác nhau đã được tô ở các đỉnh kề trực tiếp.
  int _calculateSaturationDegree(Graph graph, String nodeId) {
    final neighborColors = <PuzzleColor>{};
    for (final neighborId in graph.getNeighbors(nodeId)) {
      final neighborNode = graph.getNode(neighborId);
      if (neighborNode?.currentColor != null) {
        neighborColors.add(neighborNode!.currentColor!);
      }
    }
    return neighborColors.length;
  }
}
