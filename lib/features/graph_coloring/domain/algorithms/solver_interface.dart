import '../entities/color_inventory.dart';
import '../entities/graph.dart';
import '../entities/puzzle_color.dart';

/// Interface trừu tượng cho Graph Coloring Solver.
/// Tầng Domain thuần Dart, không phụ thuộc Flutter hay UI.
abstract class GraphColoringSolver {
  /// Kiểm tra xem trạng thái đồ thị và inventory hiện tại có còn ít nhất một nghiệm hoàn chỉnh hay không.
  bool hasSolution({
    required Graph graph,
    required ColorInventory inventory,
  });

  /// Tìm một nghiệm hoàn chỉnh cho bài toán (nếu tồn tại).
  /// Trả về Map chứa phép gán nodeId -> PuzzleColor, hoặc null nếu vô nghiệm.
  Map<String, PuzzleColor>? findSolution({
    required Graph graph,
    required ColorInventory inventory,
  });

  /// Lấy danh sách các màu hợp lệ mà node [nodeId] có thể nhận tại trạng thái hiện tại
  /// (thỏa mãn: không trùng màu các node kề, inventory còn khả dụng, và bảo đảm còn ít nhất một lời giải toàn cục).
  List<PuzzleColor> getValidColors({
    required Graph graph,
    required ColorInventory inventory,
    required String nodeId,
  });

  /// Thẩm định xem trạng thái đồ thị và inventory hiện tại đã hoàn thành và thỏa mãn 100% ràng buộc hay chưa.
  bool validateCompletedState({
    required Graph graph,
    required ColorInventory inventory,
  });

  /// Đếm số lượng nghiệm hợp lệ (dừng khi đạt tối đa [maxCount], mặc định là 2).
  /// Kết quả:
  /// - 0: Vô nghiệm (No solution)
  /// - 1: Nghiệm duy nhất (Unique solution)
  /// - >= 2: Nhiều nghiệm (Multiple solutions)
  int countSolutions({
    required Graph graph,
    required ColorInventory inventory,
    int maxCount = 2,
  });
}

