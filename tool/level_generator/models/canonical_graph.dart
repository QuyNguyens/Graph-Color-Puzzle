import 'package:graph_coloring/features/graph_coloring/domain/entities/graph.dart';

/// Bộ chuẩn hóa đồ thị chính xác (Exact Canonical Graph Labeler).
///
/// Sử dụng thuật toán Individualization-Refinement trên các phân hoạch cân bằng (Equitable Partitions):
/// - Khởi tạo màu bằng bậc đỉnh (Degree).
/// - Ổn định phân hoạch lân cận cho đến khi đạt Equitable Partition.
/// - Nhánh đệ quy cá nhân hóa các đỉnh trong cell có kích thước nhỏ nhất > 1.
/// - Tìm chuỗi ma trận kề tam giác trên có thứ tự từ điển cực đại (Lexicographically Maximal Upper-Triangular Adjacency).
///
/// Bất biến toán học 100% với mọi hoán vị đỉnh, đổi tên đỉnh và thứ tự khai báo.
class ExactCanonicalGraph {
  /// Sinh mã chuẩn tắc chính xác của đồ thị
  static String computeCanonicalCode(Graph graph) {
    final nodes = graph.nodes.keys.toList()..sort();
    final n = nodes.length;
    if (n <= 1) return n == 1 ? 'V1:E0' : 'V0:E0';

    final idMap = {for (int i = 0; i < n; i++) nodes[i]: i};
    final adj = List.generate(n, (_) => <int>{});
    for (final e in graph.edges) {
      final u = idMap[e.u]!;
      final v = idMap[e.v]!;
      adj[u].add(v);
      adj[v].add(u);
    }

    // 1. Phân hoạch cân bằng ban đầu dựa trên bậc đỉnh
    final initialColors = List<int>.generate(n, (i) => adj[i].length);
    final partition = _refineToEquitable(initialColors, adj, n);

    // 2. Individualization-Refinement Search
    String bestCode = '';

    void search(List<int> colors) {
      final colorCounts = <int, List<int>>{};
      for (int i = 0; i < n; i++) {
        colorCounts.putIfAbsent(colors[i], () => []).add(i);
      }

      int? targetColor;
      int minSize = 999;
      for (final entry in colorCounts.entries) {
        if (entry.value.length > 1 && entry.value.length < minSize) {
          minSize = entry.value.length;
          targetColor = entry.key;
        }
      }

      if (targetColor == null) {
        // Tất cả các cell đều là singleton -> Đạt một total vertex ordering hoàn chỉnh
        final ordering = List<int>.generate(n, (i) => i)
          ..sort((a, b) => colors[a].compareTo(colors[b]));

        final sb = StringBuffer();
        for (int i = 0; i < n; i++) {
          for (int j = i + 1; j < n; j++) {
            final u = ordering[i];
            final v = ordering[j];
            sb.write(adj[u].contains(v) ? '1' : '0');
          }
        }
        final code = sb.toString();
        if (bestCode.isEmpty || code.compareTo(bestCode) > 0) {
          bestCode = code;
        }
        return;
      }

      // Nhánh cá nhân hóa: Lần lượt gán nhãn đơn nhất cho từng đỉnh trong target cell
      final candidateNodes = colorCounts[targetColor]!;
      for (final v in candidateNodes) {
        final newColors = List<int>.from(colors);
        final maxCol = newColors.reduce((a, b) => a > b ? a : b);
        newColors[v] = maxCol + 1;
        final refined = _refineToEquitable(newColors, adj, n);
        search(refined);
      }
    }

    search(partition);
    return 'V$n:E${graph.edges.length}:$bestCode';
  }

  /// Tinh chỉnh màu cho đến khi đạt trạng thái Equitable Partition
  static List<int> _refineToEquitable(List<int> colors, List<Set<int>> adj, int n) {
    var cur = List<int>.from(colors);
    while (true) {
      final sigs = <int, String>{};
      for (int i = 0; i < n; i++) {
        final neighborColors = adj[i].map((j) => cur[j]).toList()..sort();
        sigs[i] = '${cur[i]}:${neighborColors.join(',')}';
      }
      final uniqueSigs = sigs.values.toSet().toList()..sort();
      if (uniqueSigs.length == cur.toSet().length) {
        break; // Không còn phân tách thêm được nữa
      }
      final rankMap = {for (int k = 0; k < uniqueSigs.length; k++) uniqueSigs[k]: k + 1};
      cur = List<int>.generate(n, (i) => rankMap[sigs[i]]!);
    }
    return cur;
  }

  /// Kiểm tra đẳng cấu chính xác 100% giữa hai đồ thị
  static bool areIsomorphic(Graph g1, Graph g2) {
    if (g1.nodes.length != g2.nodes.length) return false;
    if (g1.edges.length != g2.edges.length) return false;
    return computeCanonicalCode(g1) == computeCanonicalCode(g2);
  }
}
