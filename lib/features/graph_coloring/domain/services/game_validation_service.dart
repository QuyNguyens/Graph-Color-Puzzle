import '../algorithms/csp_solver.dart';
import '../algorithms/solver_interface.dart';
import '../entities/color_inventory.dart';
import '../entities/graph.dart';
import '../entities/puzzle_color.dart';

/// Kết quả thẩm định nước đi.
enum MoveValidationResult {
  /// Nước đi hợp lệ, bảo đảm còn ít nhất một lời giải hoàn chỉnh.
  valid,

  /// Nước đi trùng với màu hiện tại của node, không cần xử lý.
  noOp,

  /// Bị từ chối: Node đã bị khóa (Locked Node), không thể thay đổi.
  rejectedLockedNode,

  /// Bị từ chối: Màu không thuộc tập giới hạn (Restricted Colors) của node.
  rejectedRestrictedColor,

  /// Bị từ chối: Màu này đã sử dụng hết số lượng trong Inventory.
  rejectedInventoryEmpty,

  /// Bị từ chối: Có ít nhất một node kề trực tiếp đang mang màu này.
  rejectedAdjacentConflict,

  /// Bị từ chối (No Solution): Nước đi khiến bài toán rơi vào ngõ cụt, không còn lời giải hợp lệ nào.
  rejectedNoSolution,
}

/// Service thẩm định tính hợp lệ của nước đi và điều kiện chiến thắng level.
/// Tầng Domain thuần Dart, không phụ thuộc Flutter.
class GameValidationService {
  const GameValidationService({GraphColoringSolver? solver})
      : _solver = solver ?? const CspSolver();

  final GraphColoringSolver _solver;

  /// Thẩm định nước đi khi người chơi muốn gán [newColor] cho [nodeId].
  ///
  /// Quy trình kiểm tra tuân thủ GDD Mục 4.2 & Requirement B:
  /// 1. Kiểm tra node có bị khóa không.
  /// 2. Kiểm tra nếu tô lại chính màu đang có.
  /// 3. Kiểm tra tập màu giới hạn của node (Restricted Colors).
  /// 4. Kiểm tra màu còn số lượng trong inventory không.
  /// 5. Kiểm tra xung đột với các node kề trực tiếp.
  /// 6. Tạo trạng thái tạm thời và chạy Solver kiểm tra khả năng hoàn thành.
  /// 7. Nếu còn ít nhất 1 nghiệm -> Chấp nhận. Nếu vô nghiệm -> rejectedNoSolution.
  MoveValidationResult validateMove({
    required Graph graph,
    required ColorInventory inventory,
    required String nodeId,
    required PuzzleColor newColor,
  }) {
    final node = graph.getNode(nodeId);
    if (node == null) {
      throw ArgumentError('Node với ID "$nodeId" không tồn tại trong đồ thị.');
    }

    // 1. Kiểm tra node có bị khóa không
    if (node.isLocked) {
      return MoveValidationResult.rejectedLockedNode;
    }

    // 2. Kiểm tra nếu tô lại chính màu đang có
    if (node.currentColor == newColor) {
      return MoveValidationResult.noOp;
    }

    // 3. Kiểm tra tập màu giới hạn của node (Restricted Colors)
    if (!node.allowsColor(newColor)) {
      return MoveValidationResult.rejectedRestrictedColor;
    }

    // 4. Kiểm tra số lượng màu trong Inventory còn không
    if (!inventory.isAvailable(newColor)) {
      return MoveValidationResult.rejectedInventoryEmpty;
    }

    // 5. Kiểm tra xung đột với các node kề trực tiếp
    if (graph.hasAdjacentConflict(nodeId, newColor)) {
      return MoveValidationResult.rejectedAdjacentConflict;
    }

    // 6. Thử nghiệm nước đi và kiểm tra tính hoàn thành bằng Solver
    final oldColor = node.currentColor;
    var tempInventory = inventory;
    if (oldColor != null) {
      tempInventory = tempInventory.releaseColor(oldColor);
    }
    tempInventory = tempInventory.useColor(newColor);
    final tempGraph = graph.withUpdatedNode(node.copyWith(currentColor: newColor));

    if (!_solver.hasSolution(graph: tempGraph, inventory: tempInventory)) {
      return MoveValidationResult.rejectedNoSolution;
    }

    return MoveValidationResult.valid;
  }

  /// Kiểm tra level đã hoàn thành trọn vẹn chưa:
  /// 1. Tất cả node đã được tô màu.
  /// 2. Không có bất kỳ cặp node kề nào cùng màu.
  /// 3. Tất cả màu trong inventory đã được sử dụng đúng chính xác số lượng mục tiêu.
  /// 4. Tất cả node tuân thủ restrictedColors nếu có.
  bool isLevelCompleted({
    required Graph graph,
    required ColorInventory inventory,
  }) {
    return _solver.validateCompletedState(
      graph: graph,
      inventory: inventory,
    );
  }
}
