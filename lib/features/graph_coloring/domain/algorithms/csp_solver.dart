import '../entities/color_inventory.dart';
import '../entities/graph.dart';
import '../entities/puzzle_color.dart';
import 'solver_interface.dart';

/// Thuật toán giải tô màu đồ thị chính xác (Exact Graph Coloring Solver) bằng mô hình CSP.
///
/// Kết hợp:
/// - Backtracking Search
/// - Forward Checking
/// - MRV (Minimum Remaining Values)
/// - DSATUR heuristic
/// - Degree heuristic
/// - Exact Inventory Pruning (Cắt tỉa bảo toàn số lượng chính xác)
///
/// Tầng Domain thuần Dart, không phụ thuộc Flutter hay external packages.
class CspSolver implements GraphColoringSolver {
  const CspSolver();

  @override
  bool hasSolution({
    required Graph graph,
    required ColorInventory inventory,
  }) {
    return findSolution(graph: graph, inventory: inventory) != null;
  }

  @override
  Map<String, PuzzleColor>? findSolution({
    required Graph graph,
    required ColorInventory inventory,
  }) {
    final solutions = _solve(
      graph: graph,
      inventory: inventory,
      maxSolutions: 1,
    );
    if (solutions.isEmpty) return null;
    return solutions.first;
  }

  @override
  int countSolutions({
    required Graph graph,
    required ColorInventory inventory,
    int maxCount = 2,
  }) {
    if (maxCount <= 0) return 0;
    final solutions = _solve(
      graph: graph,
      inventory: inventory,
      maxSolutions: maxCount,
    );
    return solutions.length;
  }

  @override
  List<PuzzleColor> getValidColors({
    required Graph graph,
    required ColorInventory inventory,
    required String nodeId,
  }) {
    final node = graph.getNode(nodeId);
    if (node == null) return const [];

    if (node.isLocked && node.currentColor != null) {
      return hasSolution(graph: graph, inventory: inventory)
          ? [node.currentColor!]
          : const [];
    }

    final validColors = <PuzzleColor>[];
    for (final color in inventory.targetCounts.keys) {
      // 1. Kiểm tra nhanh ràng buộc cục bộ (Fast path)
      if (node.currentColor != color) {
        if (!inventory.isAvailable(color) ||
            graph.hasAdjacentConflict(nodeId, color) ||
            !node.allowsColor(color)) {
          continue;
        }
      }

      // 2. Kiểm tra ràng buộc toàn cục: Thử gán màu và xác nhận còn ít nhất 1 nghiệm
      final oldColor = node.currentColor;
      var tempInventory = inventory;
      if (oldColor != null) {
        tempInventory = tempInventory.releaseColor(oldColor);
      }
      tempInventory = tempInventory.useColor(color);
      final tempGraph =
          graph.withUpdatedNode(node.copyWith(currentColor: color));

      if (hasSolution(graph: tempGraph, inventory: tempInventory)) {
        validColors.add(color);
      }
    }
    return validColors;
  }

  @override
  bool validateCompletedState({
    required Graph graph,
    required ColorInventory inventory,
  }) {
    if (!graph.isAllColored) return false;
    if (graph.hasAnyConflict()) return false;
    if (!inventory.isFullySatisfied()) return false;

    // Kiểm tra ràng buộc Restricted Colors cho toàn bộ các node
    for (final node in graph.nodes.values) {
      if (node.currentColor != null && !node.allowsColor(node.currentColor!)) {
        return false;
      }
    }

    return true;
  }

  /// Bộ máy tìm kiếm CSP đệ quy
  List<Map<String, PuzzleColor>> _solve({
    required Graph graph,
    required ColorInventory inventory,
    required int maxSolutions,
  }) {
    // 1. Kiểm tra nhanh xung đột cục bộ ban đầu
    if (graph.hasAnyConflict()) return const [];

    // 2. Kiểm tra tính hợp lệ của kho màu (không được có số âm)
    for (final color in inventory.targetCounts.keys) {
      if (inventory.getRemaining(color) < 0) return const [];
    }

    // 3. Phân loại node đã gán màu và node chưa gán màu
    final assignedColors = <String, PuzzleColor>{};
    final uncoloredNodeIds = <String>{};

    for (final node in graph.nodes.values) {
      if (node.currentColor != null) {
        assignedColors[node.id] = node.currentColor!;
      } else {
        uncoloredNodeIds.add(node.id);
      }
    }

    // Trường hợp tất cả node đã có màu
    if (uncoloredNodeIds.isEmpty) {
      if (validateCompletedState(graph: graph, inventory: inventory)) {
        return [Map.unmodifiable(assignedColors)];
      }
      return const [];
    }

    // 4. Exact Inventory Sum Check:
    // Tổng số màu còn thiếu trong kho phải bằng đúng số lượng node chưa tô
    int totalRemainingNeeded = 0;
    final remainingInventory = <PuzzleColor, int>{};
    final allColors = inventory.targetCounts.keys.toList();

    for (final color in allColors) {
      final rem = inventory.getRemaining(color);
      remainingInventory[color] = rem;
      totalRemainingNeeded += rem;
    }

    if (totalRemainingNeeded != uncoloredNodeIds.length) {
      return const [];
    }

    // 5. Khởi tạo Domain ban đầu cho từng node chưa tô
    final domains = <String, Set<PuzzleColor>>{};
    for (final nodeId in uncoloredNodeIds) {
      final node = graph.getNode(nodeId);
      final nodeDomain = <PuzzleColor>{};
      for (final color in allColors) {
        if ((remainingInventory[color] ?? 0) > 0 &&
            !graph.hasAdjacentConflict(nodeId, color) &&
            (node == null || node.allowsColor(color))) {
          nodeDomain.add(color);
        }
      }
      if (nodeDomain.isEmpty) {
        // Tồn tại node không có bất kỳ màu nào hợp lệ (hoặc restrictedColors rỗng) -> Vô nghiệm ngay
        return const [];
      }
      domains[nodeId] = nodeDomain;
    }

    // 6. Exact Inventory Pruning ban đầu:
    // Với mỗi màu c, số lượng node chưa tô có thể nhận c phải >= remaining[c]
    for (final color in allColors) {
      final rem = remainingInventory[color] ?? 0;
      if (rem > 0) {
        int availableSlots = 0;
        for (final nodeId in uncoloredNodeIds) {
          if (domains[nodeId]!.contains(color)) {
            availableSlots++;
          }
        }
        if (availableSlots < rem) {
          return const []; // Không đủ node để chứa màu này
        }
      }
    }

    final context = _CspContext(
      graph: graph,
      allColors: allColors,
      assignedColors: assignedColors,
      uncoloredNodeIds: uncoloredNodeIds,
      remainingInventory: remainingInventory,
      domains: domains,
    );

    final solutions = <Map<String, PuzzleColor>>[];
    _backtrack(context: context, solutions: solutions, maxSolutions: maxSolutions);

    return solutions;
  }

  /// Thuật toán Backtracking kết hợp Forward Checking và Pruning
  bool _backtrack({
    required _CspContext context,
    required List<Map<String, PuzzleColor>> solutions,
    required int maxSolutions,
  }) {
    if (solutions.length >= maxSolutions) return true;

    // Điều kiện dừng: Đã tô màu hết tất cả node
    if (context.uncoloredNodeIds.isEmpty) {
      if (context.isInventoryCompletelySatisfied()) {
        solutions.add(Map.unmodifiable(Map.of(context.assignedColors)));
        return solutions.length >= maxSolutions;
      }
      return false;
    }

    // 1. Exact Inventory Pruning:
    // Kiểm tra từng màu có còn đủ slot để phân bổ không
    for (final color in context.allColors) {
      final rem = context.remainingInventory[color] ?? 0;
      if (rem < 0) return false;
      if (rem > 0) {
        int availableSlots = 0;
        for (final nodeId in context.uncoloredNodeIds) {
          if (context.domains[nodeId]!.contains(color)) {
            availableSlots++;
            if (availableSlots >= rem) break;
          }
        }
        if (availableSlots < rem) {
          return false; // Cắt nhánh! Không thể phân bổ đủ số lượng màu này
        }
      }
    }

    // 2. Variable Ordering: Chọn node bằng Heuristic (MRV -> DSATUR -> Degree)
    final selectedNodeId = _selectNextVariable(context);
    if (selectedNodeId == null) return false;

    final nodeDomain = context.domains[selectedNodeId]!;
    if (nodeDomain.isEmpty) return false;

    // 3. Value Ordering: Ưu tiên thử màu có inventory còn nhiều hơn
    final candidateColors = nodeDomain.toList()
      ..sort((a, b) {
        final remA = context.remainingInventory[a] ?? 0;
        final remB = context.remainingInventory[b] ?? 0;
        return remB.compareTo(remA);
      });

    for (final color in candidateColors) {
      final rem = context.remainingInventory[color] ?? 0;
      if (rem <= 0) continue;

      // Lưu lại snapshot domain của các node bị ảnh hưởng để khôi phục khi backtrack
      final savedDomains = <String, Set<PuzzleColor>>{};

      // Node kề bị ảnh hưởng bởi Forward Checking
      for (final neighborId in context.graph.getNeighbors(selectedNodeId)) {
        if (context.uncoloredNodeIds.contains(neighborId)) {
          savedDomains[neighborId] = Set<PuzzleColor>.of(context.domains[neighborId]!);
        }
      }

      // Nếu màu này sẽ cạn kiệt (rem == 1), tất cả các node chưa tô khác cũng bị ảnh hưởng
      if (rem == 1) {
        for (final otherId in context.uncoloredNodeIds) {
          if (otherId != selectedNodeId && !savedDomains.containsKey(otherId)) {
            savedDomains[otherId] = Set<PuzzleColor>.of(context.domains[otherId]!);
          }
        }
      }

      // Gán thử nghiệm màu cho node
      context.assignedColors[selectedNodeId] = color;
      context.uncoloredNodeIds.remove(selectedNodeId);
      context.remainingInventory[color] = rem - 1;

      // 4. Forward Checking: Loại màu khỏi domain của các node kề
      bool forwardCheckOk = true;
      for (final neighborId in context.graph.getNeighbors(selectedNodeId)) {
        if (context.uncoloredNodeIds.contains(neighborId)) {
          final neighborDomain = context.domains[neighborId]!;
          neighborDomain.remove(color);
          if (neighborDomain.isEmpty) {
            forwardCheckOk = false;
            break;
          }
        }
      }

      // Nếu màu đã hết inventory, loại khỏi domain của TẤT CẢ node chưa tô còn lại
      if (forwardCheckOk && rem == 1) {
        for (final otherId in context.uncoloredNodeIds) {
          final otherDomain = context.domains[otherId]!;
          otherDomain.remove(color);
          if (otherDomain.isEmpty) {
            forwardCheckOk = false;
            break;
          }
        }
      }

      // Tiếp tục đệ quy nếu Forward Checking thành công
      if (forwardCheckOk) {
        final shouldStop = _backtrack(
          context: context,
          solutions: solutions,
          maxSolutions: maxSolutions,
        );
        if (shouldStop) return true;
      }

      // Rollback (Backtracking)
      context.assignedColors.remove(selectedNodeId);
      context.uncoloredNodeIds.add(selectedNodeId);
      context.remainingInventory[color] = rem;

      for (final entry in savedDomains.entries) {
        context.domains[entry.key] = entry.value;
      }
    }

    return false;
  }

  /// Chọn node tiếp theo bằng Heuristic:
  /// 1. MRV (Minimum Remaining Values - ít màu hợp lệ nhất)
  /// 2. DSATUR (Đỉnh có nhiều màu khác nhau ở các đỉnh kề nhất)
  /// 3. Degree (Bậc kết nối cao nhất)
  String? _selectNextVariable(_CspContext context) {
    if (context.uncoloredNodeIds.isEmpty) return null;

    String? bestNode;
    int minDomainSize = 999999;
    int maxSaturation = -1;
    int maxDegree = -1;

    for (final nodeId in context.uncoloredNodeIds) {
      final domainSize = context.domains[nodeId]?.length ?? 0;
      if (domainSize == 0) return null; // Ngõ cụt ngay lập tức

      // Tiêu chí 1: MRV
      if (domainSize < minDomainSize) {
        minDomainSize = domainSize;
        bestNode = nodeId;
        maxSaturation = _computeSaturation(context, nodeId);
        maxDegree = context.graph.getNeighbors(nodeId).length;
      } else if (domainSize == minDomainSize) {
        // Tiêu chí 2: DSATUR (Tie-breaker 1)
        final sat = _computeSaturation(context, nodeId);
        if (sat > maxSaturation) {
          maxSaturation = sat;
          bestNode = nodeId;
          maxDegree = context.graph.getNeighbors(nodeId).length;
        } else if (sat == maxSaturation) {
          // Tiêu chí 3: Degree (Tie-breaker 2)
          final deg = context.graph.getNeighbors(nodeId).length;
          if (deg > maxDegree) {
            maxDegree = deg;
            bestNode = nodeId;
          }
        }
      }
    }

    return bestNode;
  }

  /// Tính độ bão hòa (Saturation) của một node: số lượng màu KHÁC NHAU xuất hiện ở các node kề đã tô.
  int _computeSaturation(_CspContext context, String nodeId) {
    final distinctColors = <PuzzleColor>{};
    for (final neighborId in context.graph.getNeighbors(nodeId)) {
      final neighborColor = context.assignedColors[neighborId];
      if (neighborColor != null) {
        distinctColors.add(neighborColor);
      }
    }
    return distinctColors.length;
  }
}

/// Lớp ngữ cảnh nội bộ lưu trạng thái tìm kiếm CSP.
class _CspContext {
  _CspContext({
    required this.graph,
    required this.allColors,
    required this.assignedColors,
    required this.uncoloredNodeIds,
    required this.remainingInventory,
    required this.domains,
  });

  final Graph graph;
  final List<PuzzleColor> allColors;
  final Map<String, PuzzleColor> assignedColors;
  final Set<String> uncoloredNodeIds;
  final Map<PuzzleColor, int> remainingInventory;
  final Map<String, Set<PuzzleColor>> domains;

  bool isInventoryCompletelySatisfied() {
    for (final rem in remainingInventory.values) {
      if (rem != 0) return false;
    }
    return true;
  }
}

