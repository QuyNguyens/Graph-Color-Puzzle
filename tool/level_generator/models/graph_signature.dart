import 'package:graph_coloring/features/campaign/domain/entities/puzzle_level.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/graph.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/puzzle_color.dart';
import 'canonical_graph.dart';

/// Chữ ký đồ thị (Graph Signature) hỗ trợ phân loại đa tầng:
/// A. Topology Signature (1-WL Hash): Nhận diện cấu trúc nhanh.
/// B. Exact Canonical Code: Chuỗi ma trận kề chuẩn tắc chứng minh đẳng cấu chính xác 100%.
/// C. Layout Signature: Bố cục hình học không gian.
/// D. Gameplay Signature: Trải nghiệm chơi thực tế (Topology + Inventory + Constraints).
class GraphSignatures {
  const GraphSignatures({
    required this.topologySignature,
    required this.canonicalCode,
    required this.layoutSignature,
    required this.gameplaySignature,
  });

  final String topologySignature;
  final String canonicalCode;
  final String layoutSignature;
  final String gameplaySignature;

  /// Tạo chữ ký từ PuzzleLevel
  factory GraphSignatures.fromLevel(PuzzleLevel level) {
    return GraphSignatures(
      topologySignature: computeTopologySignature(level.initialGraph),
      canonicalCode: ExactCanonicalGraph.computeCanonicalCode(level.initialGraph),
      layoutSignature: computeLayoutSignature(level.initialGraph),
      gameplaySignature: computeGameplaySignature(level),
    );
  }

  /// Tính Topology Signature bằng thuật toán Weisfeiler-Lehman (1-WL) kết hợp Degree Multiset.
  /// Bất biến với thứ tự khai báo hoặc đổi tên node (Isomorphism Invariant).
  static String computeTopologySignature(Graph graph) {
    final nodeIds = graph.nodes.keys.toList()..sort();
    final n = nodeIds.length;
    if (n == 0) return 'empty';

    final idToIndex = {for (int i = 0; i < n; i++) nodeIds[i]: i};
    final adj = List.generate(n, (_) => <int>[]);
    for (final edge in graph.edges) {
      final u = idToIndex[edge.u];
      final v = idToIndex[edge.v];
      if (u != null && v != null) {
        adj[u].add(v);
        adj[v].add(u);
      }
    }
    for (int i = 0; i < n; i++) {
      adj[i].sort();
    }

    // Khởi tạo nhãn node ban đầu bằng bậc của đỉnh (node degree)
    var labels = List<int>.generate(n, (i) => adj[i].length);

    // Thuật toán 1-WL chạy 3 vòng lặp để ổn định phân hoạch
    for (int step = 0; step < 3; step++) {
      final nextLabels = <int>[];
      final labelTuples = <String>[];
      for (int i = 0; i < n; i++) {
        final neighborLabels = adj[i].map((j) => labels[j]).toList()..sort();
        labelTuples.add('${labels[i]}:[${neighborLabels.join(',')}]');
      }

      // Đánh số lại các tuple một cách chuẩn hóa
      final sortedTuples = labelTuples.toSet().toList()..sort();
      final tupleMap = {
        for (int k = 0; k < sortedTuples.length; k++) sortedTuples[k]: k + 1
      };
      for (int i = 0; i < n; i++) {
        nextLabels.add(tupleMap[labelTuples[i]]!);
      }
      labels = nextLabels;
    }

    // Tập hợp multiset các nhãn cuối cùng
    final multiset = List<int>.from(labels)..sort();
    final degreeSeq = List<int>.generate(n, (i) => adj[i].length)..sort();

    final rawSig =
        'V:$n|E:${graph.edges.length}|DEG:${degreeSeq.join(',')}|WL:${multiset.join(',')}';
    return _fnv1aHex(rawSig);
  }

  /// Tính Layout Signature dựa trên tọa độ hình học chuẩn hóa làm tròn 2 chữ số thập phân.
  static String computeLayoutSignature(Graph graph) {
    final coords = <String>[];
    for (final node in graph.nodes.values) {
      final rx = (node.x * 100).round();
      final ry = (node.y * 100).round();
      coords.add('($rx,$ry)');
    }
    coords.sort();
    return _fnv1aHex('LAYOUT:${coords.join(';')}|N:${graph.nodes.length}');
  }

  /// Tính Gameplay Signature bao gồm:
  /// - Exact Canonical Code
  /// - Target Inventory (số lượng mỗi màu sắp xếp chuẩn hóa)
  /// - Locked Node counts và màu
  /// - Restricted Colors configuration
  static String computeGameplaySignature(PuzzleLevel level) {
    final canCode = ExactCanonicalGraph.computeCanonicalCode(level.initialGraph);

    // Chuẩn hóa Inventory
    final sortedInv = level.targetInventory.entries.toList()
      ..sort((a, b) => a.key.code.compareTo(b.key.code));
    final invStr = sortedInv.map((e) => '${e.key.code}:${e.value}').join(',');

    // Chuẩn hóa Locked Nodes
    int lockedCount = 0;
    final lockedColors = <String>[];
    for (final node in level.initialGraph.nodes.values) {
      if (node.isLocked && node.currentColor != null) {
        lockedCount++;
        lockedColors.add(node.currentColor!.code);
      }
    }
    lockedColors.sort();

    // Chuẩn hóa Restricted Colors
    int restrictedCount = 0;
    final restrictedSignatures = <String>[];
    for (final node in level.initialGraph.nodes.values) {
      if (node.restrictedColors != null && node.restrictedColors!.isNotEmpty) {
        restrictedCount++;
        final colors = node.restrictedColors!.map((c) => c.code).toList()
          ..sort();
        restrictedSignatures.add('[${colors.join(',')}]');
      }
    }
    restrictedSignatures.sort();

    final rawGameplay =
        'CAN:$canCode|INV:$invStr|LOCK:$lockedCount:${lockedColors.join(',')}|REST:$restrictedCount:${restrictedSignatures.join(';')}';
    return _fnv1aHex(rawGameplay);
  }

  /// FNV-1a 64-bit pure Dart hash
  static String _fnv1aHex(String input) {
    int hash = 0xcbf29ce484222325;
    const fnvPrime = 0x100000001b3;
    for (int i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  @override
  String toString() =>
      'GraphSignatures(topo: $topologySignature, canCode: $canonicalCode, layout: $layoutSignature, gameplay: $gameplaySignature)';
}
