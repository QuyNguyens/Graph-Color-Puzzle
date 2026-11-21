import 'dart:math';
import '../models/raw_graph_data.dart';

/// Bộ sinh các cấu trúc đồ thị (Topology Generators) theo họ hình học và đặc trưng từng Chapter.
class TopologyGenerators {
  static double _r3(double v) => double.parse(v.toStringAsFixed(3));

  // =========================================================================
  // CHAPTER 1 TOPOLOGIES (Bipartite, 4-6 nodes, 2 colors)
  // =========================================================================

  /// Cây phân nhánh (Tree / Branching): Bipartite tuyệt đối, 5 nodes
  static RawGraphData makeTreeBranching5({int seed = 101}) {
    final nodes = [
      RawNodeData('n1', 0.50, 0.20), // Gốc
      RawNodeData('n2', 0.30, 0.50), // Nhánh trái
      RawNodeData('n3', 0.70, 0.50), // Nhánh phải
      RawNodeData('n4', 0.20, 0.80), // Lá trái
      RawNodeData('n5', 0.40, 0.80), // Lá giữa
    ];
    final edges = {
      const RawEdgePair(0, 1),
      const RawEdgePair(0, 2),
      const RawEdgePair(1, 3),
      const RawEdgePair(1, 4),
    };
    return RawGraphData(nodes: nodes, edges: edges, family: 'tree_branching');
  }

  /// Bậc thang lưới Bipartite (Ladder / Grid): 6 nodes (2x3)
  static RawGraphData makeLadderGrid6({int seed = 102}) {
    final nodes = [
      RawNodeData('n1', 0.25, 0.30),
      RawNodeData('n2', 0.50, 0.30),
      RawNodeData('n3', 0.75, 0.30),
      RawNodeData('n4', 0.25, 0.70),
      RawNodeData('n5', 0.50, 0.70),
      RawNodeData('n6', 0.75, 0.70),
    ];
    final edges = {
      const RawEdgePair(0, 1),
      const RawEdgePair(1, 2),
      const RawEdgePair(3, 4),
      const RawEdgePair(4, 5),
      const RawEdgePair(0, 3),
      const RawEdgePair(1, 4),
      const RawEdgePair(2, 5),
    };
    return RawGraphData(nodes: nodes, edges: edges, family: 'ladder_grid');
  }

  // =========================================================================
  // CHAPTER 2 TOPOLOGIES (Geometric & Cycles, 6-9 nodes, 2-3 colors)
  // =========================================================================

  /// Bánh xe bậc 7 (Wheel W7 / K1 * C6): 7 đỉnh (1 tâm + 6 đỉnh trên vành chu trình C6), 12 cạnh
  static RawGraphData makeWheel7({int seed = 201}) {
    const rimCount = 6;
    const cx = 0.50;
    const cy = 0.50;
    const r = 0.34;

    final nodes = <RawNodeData>[RawNodeData('n1', cx, cy)];
    for (int i = 0; i < rimCount; i++) {
      final angle = -pi / 2 + (2 * pi * i / rimCount);
      nodes.add(RawNodeData(
        'n${i + 2}',
        _r3(cx + r * cos(angle)),
        _r3(cy + r * sin(angle)),
      ));
    }

    final edges = <RawEdgePair>{};
    for (int i = 0; i < rimCount; i++) {
      edges.add(RawEdgePair(0, i + 1));
      edges.add(RawEdgePair(i + 1, 1 + ((i + 1) % rimCount)));
    }
    return RawGraphData(nodes: nodes, edges: edges, family: 'wheel');
  }

  /// Chuỗi tam giác liên tiếp (Triangular Chain): 8 nodes
  static RawGraphData makeTriangularChain8({int seed = 202}) {
    final nodes = [
      RawNodeData('n1', 0.15, 0.50),
      RawNodeData('n2', 0.28, 0.25),
      RawNodeData('n3', 0.40, 0.75),
      RawNodeData('n4', 0.50, 0.25),
      RawNodeData('n5', 0.60, 0.75),
      RawNodeData('n6', 0.72, 0.25),
      RawNodeData('n7', 0.85, 0.50),
      RawNodeData('n8', 0.50, 0.50), // Node trung tâm nối với các đỉnh
    ];
    final edges = {
      const RawEdgePair(0, 1),
      const RawEdgePair(0, 2),
      const RawEdgePair(1, 2),
      const RawEdgePair(1, 3),
      const RawEdgePair(2, 4),
      const RawEdgePair(3, 4),
      const RawEdgePair(3, 5),
      const RawEdgePair(4, 5),
      const RawEdgePair(5, 6),
      const RawEdgePair(3, 7),
      const RawEdgePair(4, 7),
    };
    return RawGraphData(nodes: nodes, edges: edges, family: 'triangular_chain');
  }

  // =========================================================================
  // CHAPTER 3 TOPOLOGIES (Bridged & Constrained, 8-12 nodes, 3-4 colors)
  // =========================================================================

  /// Cặp cụm tam giác nối qua cầu (Bridged Twin Triangles): 9 nodes
  static RawGraphData makeBridgedTwinTriangles9({int seed = 301}) {
    final nodes = [
      // Cụm trái (tam giác + cánh trên)
      RawNodeData('n1', 0.15, 0.40),
      RawNodeData('n2', 0.15, 0.70),
      RawNodeData('n3', 0.35, 0.50),
      RawNodeData('n4', 0.25, 0.22), // Đỉnh cánh trên (tránh thẳng hàng với n1-n2)
      // Cầu nối
      RawNodeData('n5', 0.50, 0.50),
      // Cụm phải
      RawNodeData('n6', 0.65, 0.50),
      RawNodeData('n7', 0.85, 0.30),
      RawNodeData('n8', 0.85, 0.60),
      RawNodeData('n9', 0.75, 0.78), // Đỉnh cánh dưới (tránh thẳng hàng với n7-n8)
    ];
    final edges = {
      // Cụm trái (2 tam giác ghép chung cạnh 0-2)
      const RawEdgePair(0, 1),
      const RawEdgePair(0, 2),
      const RawEdgePair(1, 2),
      const RawEdgePair(0, 3),
      const RawEdgePair(2, 3),
      // Cầu nối
      const RawEdgePair(2, 4),
      const RawEdgePair(4, 5),
      // Cụm phải
      const RawEdgePair(5, 6),
      const RawEdgePair(6, 7),
      const RawEdgePair(6, 8),
      const RawEdgePair(7, 8),
      const RawEdgePair(5, 8),
    };
    return RawGraphData(nodes: nodes, edges: edges, family: 'bridged_twin_triangles');
  }

  /// Tổ hợp Star-Wheel Hybrid: 11 nodes (Wheel trung tâm + nhánh vệ tinh)
  static RawGraphData makeStarWheelHybrid11({int seed = 302}) {
    const cx = 0.45;
    const cy = 0.50;
    const r = 0.25;

    final nodes = <RawNodeData>[
      RawNodeData('n1', cx, cy), // Tâm bánh xe
    ];
    // Vành 5 đỉnh
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (2 * pi * i / 5);
      nodes.add(RawNodeData(
        'n${i + 2}',
        _r3(cx + r * cos(angle)),
        _r3(cy + r * sin(angle)),
      ));
    }
    // 5 đỉnh vệ tinh phía ngoài
    nodes.addAll([
      RawNodeData('n7', 0.80, 0.20),
      RawNodeData('n8', 0.85, 0.50),
      RawNodeData('n9', 0.80, 0.80),
      RawNodeData('n10', 0.20, 0.85),
      RawNodeData('n11', 0.15, 0.20),
    ]);

    final edges = <RawEdgePair>{};
    // Wheel core
    for (int i = 0; i < 5; i++) {
      edges.add(RawEdgePair(0, i + 1));
      edges.add(RawEdgePair(i + 1, 1 + ((i + 1) % 5)));
    }
    // Nối vệ tinh
    edges.add(const RawEdgePair(1, 6));
    edges.add(const RawEdgePair(2, 7));
    edges.add(const RawEdgePair(3, 8));
    edges.add(const RawEdgePair(4, 9));
    edges.add(const RawEdgePair(5, 10));
    // Cạnh liên kết ngoài
    edges.add(const RawEdgePair(6, 7));
    edges.add(const RawEdgePair(7, 8));

    return RawGraphData(nodes: nodes, edges: edges, family: 'star_wheel_hybrid');
  }

  // =========================================================================
  // CHAPTER 4 TOPOLOGIES (Interconnected Clusters, 10-14 nodes, 3-4 colors)
  // =========================================================================

  /// Cặp lục giác liên kết (Interconnected Dual Hexagons): 12 nodes
  static RawGraphData makeInterconnectedHexagons12({int seed = 401}) {
    // 2 vòng lục giác xếp cạnh nhau và có 2 cạnh nối chéo
    final nodes = [
      // Hexagon A (trái)
      RawNodeData('n1', 0.15, 0.50),
      RawNodeData('n2', 0.25, 0.25),
      RawNodeData('n3', 0.40, 0.25),
      RawNodeData('n4', 0.48, 0.40),
      RawNodeData('n5', 0.40, 0.75),
      RawNodeData('n6', 0.25, 0.75),
      // Hexagon B (phải)
      RawNodeData('n7', 0.52, 0.60),
      RawNodeData('n8', 0.60, 0.25),
      RawNodeData('n9', 0.75, 0.25),
      RawNodeData('n10', 0.85, 0.50),
      RawNodeData('n11', 0.75, 0.75),
      RawNodeData('n12', 0.60, 0.75),
    ];
    final edges = {
      // Hexagon A
      const RawEdgePair(0, 1),
      const RawEdgePair(1, 2),
      const RawEdgePair(2, 3),
      const RawEdgePair(3, 4),
      const RawEdgePair(4, 5),
      const RawEdgePair(5, 0),
      // Hexagon B
      const RawEdgePair(6, 7),
      const RawEdgePair(7, 8),
      const RawEdgePair(8, 9),
      const RawEdgePair(9, 10),
      const RawEdgePair(10, 11),
      const RawEdgePair(11, 6),
      // Liên kết chéo giữa 2 lục giác
      const RawEdgePair(3, 6),
      const RawEdgePair(2, 7),
      const RawEdgePair(4, 11),
    };
    return RawGraphData(nodes: nodes, edges: edges, family: 'interconnected_hexagons');
  }

  /// Mạng 4 cụm liên hoàn (Bridged Quad Cluster): 14 nodes
  static RawGraphData makeBridgedQuadCluster14({int seed = 402}) {
    final nodes = [
      // Cụm trung tâm 2 node
      RawNodeData('n1', 0.45, 0.50),
      RawNodeData('n2', 0.55, 0.50),
      // Cụm trên (3 nodes)
      RawNodeData('n3', 0.50, 0.15),
      RawNodeData('n4', 0.38, 0.28),
      RawNodeData('n5', 0.62, 0.28),
      // Cụm dưới (3 nodes)
      RawNodeData('n6', 0.50, 0.85),
      RawNodeData('n7', 0.38, 0.72),
      RawNodeData('n8', 0.62, 0.72),
      // Cụm trái (3 nodes)
      RawNodeData('n9', 0.15, 0.50),
      RawNodeData('n10', 0.28, 0.38),
      RawNodeData('n11', 0.28, 0.62),
      // Cụm phải (3 nodes)
      RawNodeData('n12', 0.85, 0.50),
      RawNodeData('n13', 0.72, 0.38),
      RawNodeData('n14', 0.72, 0.62),
    ];
    final edges = {
      // Trung tâm
      const RawEdgePair(0, 1),
      // Cụm trên
      const RawEdgePair(2, 3),
      const RawEdgePair(2, 4),
      const RawEdgePair(3, 4),
      const RawEdgePair(0, 3),
      const RawEdgePair(1, 4),
      // Cụm dưới
      const RawEdgePair(5, 6),
      const RawEdgePair(5, 7),
      const RawEdgePair(6, 7),
      const RawEdgePair(0, 6),
      const RawEdgePair(1, 7),
      // Cụm trái
      const RawEdgePair(8, 9),
      const RawEdgePair(8, 10),
      const RawEdgePair(9, 10),
      const RawEdgePair(0, 9),
      const RawEdgePair(0, 10),
      // Cụm phải
      const RawEdgePair(11, 12),
      const RawEdgePair(11, 13),
      const RawEdgePair(12, 13),
      const RawEdgePair(1, 12),
      const RawEdgePair(1, 13),
    };
    return RawGraphData(nodes: nodes, edges: edges, family: 'bridged_quad_cluster');
  }

  // =========================================================================
  // CHAPTER 5 TOPOLOGIES (Dense & Restricted, 12-16 nodes, 4-5 colors)
  // =========================================================================

  /// Lưới tam giác dày đặc (Dense Triangular Mesh): 13 nodes
  static RawGraphData makeDenseTriangularMesh13({int seed = 501}) {
    final nodes = [
      // Lớp ngoài hình lục giác
      RawNodeData('n1', 0.50, 0.12),
      RawNodeData('n2', 0.82, 0.28),
      RawNodeData('n3', 0.82, 0.72),
      RawNodeData('n4', 0.50, 0.88),
      RawNodeData('n5', 0.18, 0.72),
      RawNodeData('n6', 0.18, 0.28),
      // Lớp giữa
      RawNodeData('n7', 0.50, 0.32),
      RawNodeData('n8', 0.66, 0.40),
      RawNodeData('n9', 0.66, 0.60),
      RawNodeData('n10', 0.50, 0.68),
      RawNodeData('n11', 0.34, 0.60),
      RawNodeData('n12', 0.34, 0.40),
      // Tâm
      RawNodeData('n13', 0.50, 0.50),
    ];
    final edges = {
      // Vành ngoài
      const RawEdgePair(0, 1),
      const RawEdgePair(1, 2),
      const RawEdgePair(2, 3),
      const RawEdgePair(3, 4),
      const RawEdgePair(4, 5),
      const RawEdgePair(5, 0),
      // Vành giữa
      const RawEdgePair(6, 7),
      const RawEdgePair(7, 8),
      const RawEdgePair(8, 9),
      const RawEdgePair(9, 10),
      const RawEdgePair(10, 11),
      const RawEdgePair(11, 6),
      // Nối ngoài với giữa
      const RawEdgePair(0, 6),
      const RawEdgePair(1, 7),
      const RawEdgePair(2, 8),
      const RawEdgePair(3, 9),
      const RawEdgePair(4, 10),
      const RawEdgePair(5, 11),
      // Nối tam giác chéo
      const RawEdgePair(0, 7),
      const RawEdgePair(1, 8),
      const RawEdgePair(2, 9),
      const RawEdgePair(3, 10),
      const RawEdgePair(4, 11),
      const RawEdgePair(5, 6),
      // Tâm nối vành giữa
      const RawEdgePair(12, 6),
      const RawEdgePair(12, 7),
      const RawEdgePair(12, 8),
      const RawEdgePair(12, 9),
      const RawEdgePair(12, 10),
      const RawEdgePair(12, 11),
    };
    return RawGraphData(nodes: nodes, edges: edges, family: 'dense_triangular_mesh');
  }

  /// Biến thể Grötzsch 15 đỉnh (Grotzsch Extension): 15 nodes
  static RawGraphData makeGrotzschExtension15({int seed = 502}) {
    // Vành ngoài 7 đỉnh, vành trong 7 đỉnh, 1 tâm
    final nodes = <RawNodeData>[];
    const n = 7;
    const cx = 0.50;
    const cy = 0.50;
    const rOuter = 0.38;
    const rInner = 0.22;

    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi * i / n);
      nodes.add(RawNodeData('n${i + 1}', _r3(cx + rOuter * cos(angle)), _r3(cy + rOuter * sin(angle))));
    }
    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi * (i + 0.5) / n);
      nodes.add(RawNodeData('n${n + i + 1}', _r3(cx + rInner * cos(angle)), _r3(cy + rInner * sin(angle))));
    }
    nodes.add(RawNodeData('n15', cx, cy)); // Tâm

    final edges = <RawEdgePair>{};
    // Vành ngoài
    for (int i = 0; i < n; i++) {
      edges.add(RawEdgePair(i, (i + 1) % n));
    }
    // Nối vành trong với vành ngoài đan xen
    for (int i = 0; i < n; i++) {
      edges.add(RawEdgePair(n + i, i));
      edges.add(RawEdgePair(n + i, (i + 1) % n));
      // Tâm nối vành trong
      edges.add(RawEdgePair(2 * n, n + i));
    }

    return RawGraphData(nodes: nodes, edges: edges, family: 'grotzsch_extension');
  }

  // =========================================================================
  // CHAPTER 6 TOPOLOGIES (Master Network & Irregular Web, 14-20 nodes, 4-5 colors)
  // =========================================================================

  /// Mạng 3 cụm phức hợp (Master Tri-Cluster Network): 16 nodes
  static RawGraphData makeMasterTriCluster16({int seed = 601}) {
    // 3 cụm lớn (đỉnh tam giác, bánh xe 5 đỉnh, tứ giác chéo) nối qua 3 bridge nodes
    final nodes = [
      // Cụm 1: Tam giác mở rộng (trên)
      RawNodeData('n1', 0.50, 0.12),
      RawNodeData('n2', 0.40, 0.25),
      RawNodeData('n3', 0.60, 0.25),
      RawNodeData('n4', 0.50, 0.32),
      // Cụm 2: Bánh xe (dưới trái)
      RawNodeData('n5', 0.22, 0.65), // Tâm
      RawNodeData('n6', 0.12, 0.52),
      RawNodeData('n7', 0.32, 0.52),
      RawNodeData('n8', 0.32, 0.78),
      RawNodeData('n9', 0.12, 0.78),
      // Cụm 3: Ngũ giác có đường chéo (dưới phải)
      RawNodeData('n10', 0.78, 0.65),
      RawNodeData('n11', 0.68, 0.52),
      RawNodeData('n12', 0.88, 0.52),
      RawNodeData('n13', 0.88, 0.78),
      RawNodeData('n14', 0.68, 0.78),
      // 2 Bridge nodes ở trung tâm liên kết 3 cụm
      RawNodeData('n15', 0.42, 0.44),
      RawNodeData('n16', 0.58, 0.44),
    ];
    final edges = {
      // Cụm 1
      const RawEdgePair(0, 1),
      const RawEdgePair(0, 2),
      const RawEdgePair(1, 2),
      const RawEdgePair(1, 3),
      const RawEdgePair(2, 3),
      // Cụm 2
      const RawEdgePair(4, 5),
      const RawEdgePair(4, 6),
      const RawEdgePair(4, 7),
      const RawEdgePair(4, 8),
      const RawEdgePair(5, 6),
      const RawEdgePair(6, 7),
      const RawEdgePair(7, 8),
      const RawEdgePair(8, 5),
      // Cụm 3
      const RawEdgePair(9, 10),
      const RawEdgePair(9, 11),
      const RawEdgePair(9, 12),
      const RawEdgePair(9, 13),
      const RawEdgePair(10, 11),
      const RawEdgePair(11, 12),
      const RawEdgePair(12, 13),
      const RawEdgePair(13, 10),
      // Bridges liên kết
      const RawEdgePair(3, 14),
      const RawEdgePair(3, 15),
      const RawEdgePair(14, 15),
      const RawEdgePair(14, 6),
      const RawEdgePair(15, 10),
      const RawEdgePair(7, 13), // Cầu ngang đáy giữa Cụm 2 và Cụm 3
    };
    return RawGraphData(nodes: nodes, edges: edges, family: 'master_tri_cluster');
  }

  /// Mạng lưới mạng nhện đa chiều (Complex Irregular Web): 18 nodes
  static RawGraphData makeComplexIrregularWeb18({int seed = 602}) {
    // Đồ thị 18 node với nhiều vòng lồng nhau và các liên kết bất đối xứng
    final nodes = <RawNodeData>[];
    const nOuter = 8;
    const nMid = 6;
    const cx = 0.50;
    const cy = 0.50;

    // Vành ngoài 8
    for (int i = 0; i < nOuter; i++) {
      final angle = -pi / 2 + (2 * pi * i / nOuter);
      nodes.add(RawNodeData('n${i + 1}', _r3(cx + 0.38 * cos(angle)), _r3(cy + 0.38 * sin(angle))));
    }
    // Vành giữa 6
    for (int i = 0; i < nMid; i++) {
      final angle = -pi / 2 + (2 * pi * (i + 0.3) / nMid);
      nodes.add(RawNodeData('n${nOuter + i + 1}', _r3(cx + 0.24 * cos(angle)), _r3(cy + 0.24 * sin(angle))));
    }
    // Lõi trong 4 nodes
    nodes.addAll([
      RawNodeData('n15', 0.42, 0.42),
      RawNodeData('n16', 0.58, 0.42),
      RawNodeData('n17', 0.58, 0.58),
      RawNodeData('n18', 0.42, 0.58),
    ]);

    final edges = <RawEdgePair>{};
    // Vành ngoài
    for (int i = 0; i < nOuter; i++) {
      edges.add(RawEdgePair(i, (i + 1) % nOuter));
    }
    // Vành giữa
    for (int i = 0; i < nMid; i++) {
      edges.add(RawEdgePair(nOuter + i, nOuter + ((i + 1) % nMid)));
    }
    // Lõi trong
    edges.add(const RawEdgePair(14, 15));
    edges.add(const RawEdgePair(15, 16));
    edges.add(const RawEdgePair(16, 17));
    edges.add(const RawEdgePair(17, 14));
    edges.add(const RawEdgePair(14, 16)); // Đường chéo lõi

    // Nối vành ngoài với vành giữa theo góc lân cận tự nhiên
    for (int i = 0; i < nMid; i++) {
      final nearestOuter = (i * nOuter / nMid).round() % nOuter;
      edges.add(RawEdgePair(nOuter + i, nearestOuter));
      edges.add(RawEdgePair(nOuter + i, (nearestOuter + 1) % nOuter));
    }
    // Nối vành giữa với 4 đỉnh lõi trung tâm tương ứng
    edges.add(const RawEdgePair(8, 14)); // Mid top -> Core top-left
    edges.add(const RawEdgePair(9, 15)); // Mid right-top -> Core top-right
    edges.add(const RawEdgePair(11, 16)); // Mid bottom -> Core bottom-right
    edges.add(const RawEdgePair(13, 17)); // Mid left -> Core bottom-left

    return RawGraphData(nodes: nodes, edges: edges, family: 'complex_irregular_web');
  }
}
