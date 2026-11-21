import '../../../graph_coloring/domain/algorithms/csp_solver.dart';
import '../../../graph_coloring/domain/algorithms/solver_interface.dart';
import '../../../graph_coloring/domain/entities/puzzle_color.dart';
import '../entities/puzzle_level.dart';

/// Kết quả kiểm định một danh sách màn chơi.
class LevelValidationReport {
  const LevelValidationReport({
    required this.isValid,
    required this.errors,
    required this.totalLevels,
  });

  final bool isValid;
  final List<String> errors;
  final int totalLevels;

  @override
  String toString() {
    if (isValid) {
      return 'LevelValidationReport: THÀNH CÔNG! Đã xác thực toàn bộ $totalLevels levels không có lỗi nào.';
    }
    return 'LevelValidationReport: THẤT BẠI! Có ${errors.length} lỗi trên tổng số $totalLevels levels:\n'
        '${errors.map((e) => ' - $e').join('\n')}';
  }
}

/// Pipeline kiểm tra tính toàn vẹn và hợp lệ của toàn bộ dữ liệu 180 levels.
/// Tầng Domain thuần Dart.
class LevelValidator {
  const LevelValidator({GraphColoringSolver? solver})
      : _solver = solver ?? const CspSolver();

  final GraphColoringSolver _solver;

  /// Thực hiện kiểm tra toàn diện danh sách các màn chơi.
  LevelValidationReport validateAll(List<PuzzleLevel> levels) {
    final errors = <String>[];

    // 1. Kiểm tra tổng số lượng
    if (levels.length != 180) {
      errors.add('Tổng số level phải đúng 180, hiện có: ${levels.length}');
    }

    // 2. Kiểm tra tính liên tục của overallIndex và tính duy nhất của ID
    final seenIds = <String>{};
    final seenOverallIndexes = <int>{};

    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];
      final expectedOverall = i + 1;

      if (level.overallIndex != expectedOverall) {
        errors.add(
          'Level tại vị trí $i có overallIndex=${level.overallIndex}, kỳ vọng $expectedOverall',
        );
      }
      if (seenOverallIndexes.contains(level.overallIndex)) {
        errors.add('overallIndex trùng lặp: ${level.overallIndex}');
      }
      seenOverallIndexes.add(level.overallIndex);

      if (seenIds.contains(level.id)) {
        errors.add('ID level trùng lặp: ${level.id}');
      }
      seenIds.add(level.id);

      // Kiểm tra chi tiết từng level
      final levelErrors = validateSingleLevel(level);
      errors.addAll(levelErrors);
    }

    return LevelValidationReport(
      isValid: errors.isEmpty,
      errors: errors,
      totalLevels: levels.length,
    );
  }

  /// Kiểm tra một level đơn lẻ theo toàn bộ các quy tắc GDD & Architecture.
  List<String> validateSingleLevel(PuzzleLevel level) {
    final errors = <String>[];
    final id = level.id;
    final graph = level.initialGraph;
    final nodeCount = graph.nodes.length;
    final edgeCount = graph.edges.length;

    // A. Chapter ID và Level Number
    final expectedChapterId = ((level.overallIndex - 1) ~/ 30) + 1;
    final expectedLevelNum = ((level.overallIndex - 1) % 30) + 1;
    if (level.chapterId != expectedChapterId) {
      errors.add(
          '[$id] Chapter ID không khớp: có ${level.chapterId}, kỳ vọng $expectedChapterId');
    }
    if (level.levelNumber != expectedLevelNum) {
      errors.add(
          '[$id] Level number không khớp: có ${level.levelNumber}, kỳ vọng $expectedLevelNum');
    }

    // B. Giới hạn số node và màu theo từng Chapter
    final targetColors = level.targetInventory.keys.toSet();
    final colorCount = targetColors.length;

    int lockedCount = 0;
    int restrictedCount = 0;
    for (final node in graph.nodes.values) {
      if (node.isLocked) lockedCount++;
      if (node.restrictedColors != null) restrictedCount++;
    }

    switch (level.chapterId) {
      case 1:
        // Hỗ trợ tiến trình mở khóa màu lũy tiến tại các Milestone:
        // - L1-4: 2 màu, 4-5 nodes
        // - L5-9: 2-3 màu, 5-7 nodes (L5 milestone: màu Vàng)
        // - L10-19: 2-4 màu, 6-8 nodes (L10 milestone: màu Xanh lá)
        // - L20-30: 2-5 màu, 7-10 nodes (L20 milestone: màu Tím, L30 Finale)
        if (nodeCount < 4 || nodeCount > 10) {
          errors.add(
              '[$id] Chapter 1 yêu cầu 4-10 nodes theo tiến trình cột mốc, hiện có $nodeCount nodes');
        }
        final maxAllowedColors = level.levelNumber < 5
            ? 2
            : (level.levelNumber < 10
                ? 3
                : (level.levelNumber < 20 ? 4 : 5));
        if (colorCount < 2 || colorCount > maxAllowedColors) {
          errors.add(
              '[$id] Màn ${level.levelNumber} của Chapter 1 cho phép từ 2 đến $maxAllowedColors màu, hiện có $colorCount màu');
        }
        if (lockedCount != 0) {
          errors.add('[$id] Chapter 1 không được có Locked Node');
        }
        if (restrictedCount != 0) {
          errors.add('[$id] Chapter 1 không được có Restricted Colors');
        }
        break;

      case 2:
        if (nodeCount < 6 || nodeCount > 9) {
          errors.add(
              '[$id] Chapter 2 yêu cầu 6-9 nodes, hiện có $nodeCount nodes');
        }
        if (colorCount < 2 || colorCount > 3) {
          errors.add(
              '[$id] Chapter 2 yêu cầu 2-3 màu, hiện có $colorCount màu');
        }
        if (lockedCount != 0) {
          errors.add('[$id] Chapter 2 không được có Locked Node');
        }
        if (restrictedCount != 0) {
          errors.add('[$id] Chapter 2 không được có Restricted Colors');
        }
        break;

      case 3:
        if (nodeCount < 8 || nodeCount > 12) {
          errors.add(
              '[$id] Chapter 3 yêu cầu 8-12 nodes, hiện có $nodeCount nodes');
        }
        if (colorCount < 3 || colorCount > 4) {
          errors.add(
              '[$id] Chapter 3 yêu cầu 3-4 màu, hiện có $colorCount màu');
        }
        if (lockedCount < 1) {
          errors.add(
              '[$id] Chapter 3 bắt buộc phải có ít nhất 1 Locked Node');
        }
        if (restrictedCount != 0) {
          errors.add('[$id] Chapter 3 không được có Restricted Colors');
        }
        break;

      case 4:
        if (nodeCount < 10 || nodeCount > 14) {
          errors.add(
              '[$id] Chapter 4 yêu cầu 10-14 nodes, hiện có $nodeCount nodes');
        }
        if (colorCount < 3 || colorCount > 4) {
          errors.add(
              '[$id] Chapter 4 yêu cầu 3-4 màu, hiện có $colorCount màu');
        }
        if (lockedCount < 1) {
          errors.add(
              '[$id] Chapter 4 bắt buộc phải có ít nhất 1 Locked Node');
        }
        if (restrictedCount != 0) {
          errors.add('[$id] Chapter 4 không được có Restricted Colors');
        }
        break;

      case 5:
        if (nodeCount < 12 || nodeCount > 16) {
          errors.add(
              '[$id] Chapter 5 yêu cầu 12-16 nodes, hiện có $nodeCount nodes');
        }
        if (colorCount < 4 || colorCount > 5) {
          errors.add(
              '[$id] Chapter 5 yêu cầu 4-5 màu, hiện có $colorCount màu');
        }
        if (restrictedCount < 1) {
          errors.add(
              '[$id] Chapter 5 bắt buộc phải có ít nhất 1 Node có Restricted Colors');
        }
        break;

      case 6:
        if (nodeCount < 14 || nodeCount > 20) {
          errors.add(
              '[$id] Chapter 6 yêu cầu 14-20 nodes, hiện có $nodeCount nodes');
        }
        if (colorCount < 4 || colorCount > 5) {
          errors.add(
              '[$id] Chapter 6 yêu cầu 4-5 màu, hiện có $colorCount màu');
        }
        if (lockedCount < 1) {
          errors.add(
              '[$id] Chapter 6 bắt buộc phải có Locked Node');
        }
        if (restrictedCount < 1) {
          errors.add(
              '[$id] Chapter 6 bắt buộc phải có Restricted Colors');
        }
        break;
    }

    // C. Đồ thị liên thông, không có node cô lập
    for (final nodeEntry in graph.nodes.entries) {
      final nodeId = nodeEntry.key;
      final neighbors = graph.getNeighbors(nodeId);
      if (neighbors.isEmpty) {
        errors.add('[$id] Node $nodeId bị cô lập (degree = 0)');
      }
    }

    if (!_isGraphConnected(graph.nodes.keys, graph.adjacencyList)) {
      errors.add('[$id] Đồ thị không liên thông (có nhiều thành phần rời rạc)');
    }

    // D. Không có self-loop và cạnh trùng lặp
    final seenEdges = <String>{};
    for (final edge in graph.edges) {
      if (edge.u == edge.v) {
        errors.add('[$id] Phát hiện self-loop tại node ${edge.u}');
      }
      final canonical = edge.u.compareTo(edge.v) < 0
          ? '${edge.u}_${edge.v}'
          : '${edge.v}_${edge.u}';
      if (seenEdges.contains(canonical)) {
        errors.add('[$id] Phát hiện cạnh vô hướng trùng lặp: (${edge.u}, ${edge.v})');
      }
      seenEdges.add(canonical);

      if (!graph.nodes.containsKey(edge.u) || !graph.nodes.containsKey(edge.v)) {
        errors.add('[$id] Cạnh (${edge.u}, ${edge.v}) tham chiếu node không tồn tại');
      }
    }

    // E. Tọa độ node nằm trong vùng hợp lệ [0.05, 0.95]
    final nodePositions = <String>[];
    for (final node in graph.nodes.values) {
      if (node.x < 0.05 || node.x > 0.95 || node.y < 0.05 || node.y > 0.95) {
        errors.add(
          '[$id] Node ${node.id} có tọa độ ngoài biên hợp lệ [0.05, 0.95]: (${node.x}, ${node.y})',
        );
      }
      // Kiểm tra trùng khít tọa độ
      for (final other in graph.nodes.values) {
        if (node.id != other.id) {
          final dx = (node.x - other.x).abs();
          final dy = (node.y - other.y).abs();
          if (dx < 0.02 && dy < 0.02) {
            errors.add(
              '[$id] Hai node ${node.id} và ${other.id} có tọa độ quá gần/trùng khít: (${node.x}, ${node.y}) vs (${other.x}, ${other.y})',
            );
          }
        }
      }
    }

    // F. Locked Nodes: Không có 2 locked node kề nhau cùng màu
    for (final edge in graph.edges) {
      final u = graph.getNode(edge.u);
      final v = graph.getNode(edge.v);
      if (u != null && v != null && u.isLocked && v.isLocked) {
        if (u.currentColor != null && u.currentColor == v.currentColor) {
          errors.add(
            '[$id] Hai Locked Node kề nhau (${u.id}, ${v.id}) có cùng màu: ${u.currentColor}',
          );
        }
      }
    }

    // Locked node phải có currentColor và thuộc targetInventory
    for (final node in graph.nodes.values) {
      if (node.isLocked) {
        if (node.currentColor == null) {
          errors.add('[$id] Locked Node ${node.id} không có currentColor');
        } else if (!targetColors.contains(node.currentColor)) {
          errors.add(
            '[$id] Locked Node ${node.id} có màu ${node.currentColor} không nằm trong targetInventory',
          );
        }
      }
    }

    // G. Restricted Colors: Không được rỗng
    for (final node in graph.nodes.values) {
      if (node.restrictedColors != null) {
        if (node.restrictedColors!.isEmpty) {
          errors.add('[$id] Node ${node.id} có restrictedColors rỗng');
        }
        for (final c in node.restrictedColors!) {
          if (!targetColors.contains(c)) {
            errors.add(
              '[$id] Node ${node.id} có restricted color $c không thuộc targetInventory',
            );
          }
        }
      }
    }

    // H. Tổng Inventory bằng đúng số lượng node
    final inventorySum = level.targetInventory.values.fold(0, (a, b) => a + b);
    if (inventorySum != nodeCount) {
      errors.add(
        '[$id] Tổng inventory ($inventorySum) không bằng số lượng node ($nodeCount)',
      );
    }
    for (final entry in level.targetInventory.entries) {
      if (entry.value <= 0) {
        errors.add(
          '[$id] Màu ${entry.key} trong inventory có số lượng không dương: ${entry.value}',
        );
      }
    }

    // I. Kiểm tra Solvability bằng Solver CSP
    final inventory = level.createInitialInventory();
    final hasSolution = _solver.hasSolution(
      graph: graph,
      inventory: inventory,
    );
    if (!hasSolution) {
      errors.add('[$id] CSP Solver không tìm thấy lời giải hợp lệ cho màn chơi này!');
    }

    return errors;
  }

  /// Kiểm tra tính liên thông của đồ thị bằng thuật toán BFS.
  bool _isGraphConnected(
    Iterable<String> nodeIds,
    Map<String, Set<String>> adjacencyList,
  ) {
    final list = nodeIds.toList();
    if (list.isEmpty) return true;

    final visited = <String>{};
    final queue = <String>[list.first];
    visited.add(list.first);

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final neighbors = adjacencyList[current] ?? const <String>{};
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    return visited.length == list.length;
  }
}

