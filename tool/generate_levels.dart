import 'dart:io';
import 'dart:math';

import '../lib/features/campaign/domain/entities/puzzle_level.dart';
import '../lib/features/campaign/domain/services/level_validator.dart';
import '../lib/features/graph_coloring/domain/algorithms/csp_solver.dart';
import '../lib/features/graph_coloring/domain/entities/graph.dart';
import '../lib/features/graph_coloring/domain/entities/graph_edge.dart';
import '../lib/features/graph_coloring/domain/entities/graph_node.dart';
import '../lib/features/graph_coloring/domain/entities/puzzle_color.dart';

void main() async {
  stdout.writeln('=== BẮT ĐẦU GENERATE 180 HANDCRAFTED LEVELS ===');

  final allLevels = <PuzzleLevel>[];
  final validator = const LevelValidator();

  stdout.writeln('Đang tạo Chapter 1: First Connection (Level 1..30)...');
  final ch1 = generateChapter1();
  allLevels.addAll(ch1);

  stdout.writeln('Đang tạo Chapter 2: Color Balance (Level 31..60)...');
  final ch2 = generateChapter2();
  allLevels.addAll(ch2);

  stdout.writeln('Đang tạo Chapter 3: Locked Connections (Level 61..90)...');
  final ch3 = generateChapter3();
  allLevels.addAll(ch3);

  stdout.writeln('Đang tạo Chapter 4: Complex Network (Level 91..120)...');
  final ch4 = generateChapter4();
  allLevels.addAll(ch4);

  stdout.writeln('Đang tạo Chapter 5: Restricted Choices (Level 121..150)...');
  final ch5 = generateChapter5();
  allLevels.addAll(ch5);

  stdout.writeln('Đang tạo Chapter 6: Master Network (Level 151..180)...');
  final ch6 = generateChapter6();
  allLevels.addAll(ch6);

  stdout.writeln('Tổng số level đã tạo: ${allLevels.length}');

  // Chạy LevelValidator trên toàn bộ 180 level
  stdout.writeln('Đang chạy LevelValidator kiểm tra toàn diện 180 levels...');
  final report = validator.validateAll(allLevels);
  stdout.writeln(report.toString());

  if (!report.isValid) {
    stderr.writeln('DỪNG LẠI! Có lỗi trong dữ liệu level:');
    for (final err in report.errors) {
      stderr.writeln(' - $err');
    }
    exit(1);
  }

  // Xuất 6 file Dart data
  stdout.writeln('Đang ghi 6 file dữ liệu level vào lib/features/campaign/data/levels/...');
  writeChapterFile(1, ch1);
  writeChapterFile(2, ch2);
  writeChapterFile(3, ch3);
  writeChapterFile(4, ch4);
  writeChapterFile(5, ch5);
  writeChapterFile(6, ch6);

  stdout.writeln('=== HOÀN TẤT THÀNH CÔNG TOÀN BỘ 180 LEVELS! ===');
}

// ---------------------------------------------------------------------------
// BUILDER HELPERS
// ---------------------------------------------------------------------------

class RawNode {
  RawNode(this.id, this.x, this.y);
  final String id;
  final double x;
  final double y;
}

class RawGraph {
  RawGraph(this.nodes, this.edges);
  final List<RawNode> nodes;
  final List<List<int>> edges; // Index-based pairs [i, j]
}

double r3(double v) => double.parse(v.toStringAsFixed(3));

RawGraph makePathGraph(int n, double x1, double y1, double x2, double y2) {
  final nodes = <RawNode>[];
  for (int i = 0; i < n; i++) {
    final t = i / (n - 1);
    nodes.add(RawNode('n${i + 1}', r3(x1 + t * (x2 - x1)), r3(y1 + t * (y2 - y1))));
  }
  final edges = <List<int>>[];
  for (int i = 0; i < n - 1; i++) {
    edges.add([i, i + 1]);
  }
  return RawGraph(nodes, edges);
}

RawGraph makeCycleGraph(int n, double cx, double cy, double r) {
  final nodes = <RawNode>[];
  for (int i = 0; i < n; i++) {
    final angle = -pi / 2 + (2 * pi * i / n);
    nodes.add(RawNode('n${i + 1}', r3(cx + r * cos(angle)), r3(cy + r * sin(angle))));
  }
  final edges = <List<int>>[];
  for (int i = 0; i < n; i++) {
    edges.add([i, (i + 1) % n]);
  }
  return RawGraph(nodes, edges);
}

RawGraph makeGridGraph(int rows, int cols, double x1, double y1, double x2, double y2) {
  final nodes = <RawNode>[];
  for (int r = 0; r < rows; r++) {
    final ty = rows > 1 ? r / (rows - 1) : 0.5;
    for (int c = 0; c < cols; c++) {
      final tx = cols > 1 ? c / (cols - 1) : 0.5;
      final idx = r * cols + c + 1;
      nodes.add(RawNode('n$idx', r3(x1 + tx * (x2 - x1)), r3(y1 + ty * (y2 - y1))));
    }
  }
  final edges = <List<int>>[];
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final idx = r * cols + c;
      if (c + 1 < cols) edges.add([idx, idx + 1]);
      if (r + 1 < rows) edges.add([idx, idx + cols]);
    }
  }
  return RawGraph(nodes, edges);
}

RawGraph makeWheelGraph(int rimCount, double cx, double cy, double r) {
  final nodes = <RawNode>[];
  nodes.add(RawNode('n1', r3(cx), r3(cy)));
  for (int i = 0; i < rimCount; i++) {
    final angle = -pi / 2 + (2 * pi * i / rimCount);
    nodes.add(RawNode('n${i + 2}', r3(cx + r * cos(angle)), r3(cy + r * sin(angle))));
  }
  final edges = <List<int>>[];
  for (int i = 0; i < rimCount; i++) {
    edges.add([0, i + 1]);
    edges.add([i + 1, 1 + ((i + 1) % rimCount)]);
  }
  return RawGraph(nodes, edges);
}

RawGraph makeFanGraph(int rimCount, double cx, double cy, double r, double startAngle, double span) {
  final nodes = <RawNode>[];
  nodes.add(RawNode('n1', r3(cx), r3(cy)));
  for (int i = 0; i < rimCount; i++) {
    final angle = startAngle + (span * i / (rimCount - 1));
    nodes.add(RawNode('n${i + 2}', r3(cx + r * cos(angle)), r3(cy + r * sin(angle))));
  }
  final edges = <List<int>>[];
  for (int i = 0; i < rimCount; i++) {
    edges.add([0, i + 1]);
    if (i < rimCount - 1) edges.add([i + 1, i + 2]);
  }
  return RawGraph(nodes, edges);
}

RawGraph makeStarGraph(int leaves, double cx, double cy, double r) {
  final nodes = <RawNode>[];
  nodes.add(RawNode('n1', r3(cx), r3(cy)));
  for (int i = 0; i < leaves; i++) {
    final angle = -pi / 2 + (2 * pi * i / leaves);
    nodes.add(RawNode('n${i + 2}', r3(cx + r * cos(angle)), r3(cy + r * sin(angle))));
  }
  final edges = <List<int>>[];
  for (int i = 0; i < leaves; i++) {
    edges.add([0, i + 1]);
  }
  return RawGraph(nodes, edges);
}

RawGraph makePrismGraph(int baseSides, double cx, double cy, double rOuter, double rInner) {
  final nodes = <RawNode>[];
  for (int i = 0; i < baseSides; i++) {
    final angle = -pi / 2 + (2 * pi * i / baseSides);
    nodes.add(RawNode('n${i + 1}', r3(cx + rOuter * cos(angle)), r3(cy + rOuter * sin(angle))));
  }
  for (int i = 0; i < baseSides; i++) {
    final angle = -pi / 2 + (2 * pi * i / baseSides);
    nodes.add(RawNode('n${baseSides + i + 1}', r3(cx + rInner * cos(angle)), r3(cy + rInner * sin(angle))));
  }
  final edges = <List<int>>[];
  for (int i = 0; i < baseSides; i++) {
    edges.add([i, (i + 1) % baseSides]);
    edges.add([baseSides + i, baseSides + ((i + 1) % baseSides)]);
    edges.add([i, baseSides + i]);
  }
  return RawGraph(nodes, edges);
}

// ---------------------------------------------------------------------------
// SOLVER & LEVEL FACTORY
// ---------------------------------------------------------------------------

Map<int, PuzzleColor>? findProperColoring(
  RawGraph raw,
  List<PuzzleColor> palette, {
  required int requiredDistinctColors,
}) {
  final n = raw.nodes.length;
  final adj = List.generate(n, (_) => <int>{});
  for (final e in raw.edges) {
    adj[e[0]].add(e[1]);
    adj[e[1]].add(e[0]);
  }

  final assignment = <int, PuzzleColor>{};

  bool backtrack(int u) {
    if (u == n) {
      final distinct = assignment.values.toSet().length;
      return distinct == requiredDistinctColors;
    }

    for (final color in palette) {
      bool conflict = false;
      for (final v in adj[u]) {
        if (assignment[v] == color) {
          conflict = true;
          break;
        }
      }
      if (!conflict) {
        assignment[u] = color;
        if (backtrack(u + 1)) return true;
        assignment.remove(u);
      }
    }
    return false;
  }

  if (backtrack(0)) return assignment;
  return null;
}

PuzzleLevel buildLevel({
  required String id,
  required int chapterId,
  required int levelNumber,
  required int overallIndex,
  required String title,
  required double difficulty,
  required RawGraph raw,
  required List<PuzzleColor> palette,
  required int requiredDistinctColors,
  List<int>? requestedLocked,
  List<int>? requestedRestricted,
}) {
  final coloring = findProperColoring(
    raw,
    palette,
    requiredDistinctColors: requiredDistinctColors,
  );

  if (coloring == null) {
    throw StateError('Không thể tìm thấy coloring $requiredDistinctColors màu cho $id (${raw.nodes.length} nodes, ${raw.edges.length} edges)');
  }

  final targetInventory = <PuzzleColor, int>{};
  for (final c in palette) {
    final count = coloring.values.where((col) => col == c).length;
    if (count > 0) {
      targetInventory[c] = count;
    }
  }

  final lockedSet = <int>{};
  if (requestedLocked != null) {
    final adj = List.generate(raw.nodes.length, (_) => <int>{});
    for (final e in raw.edges) {
      adj[e[0]].add(e[1]);
      adj[e[1]].add(e[0]);
    }

    for (final idx in requestedLocked) {
      if (idx < raw.nodes.length) {
        bool hasLockedNeighbor = false;
        for (final neighbor in adj[idx]) {
          if (lockedSet.contains(neighbor)) {
            hasLockedNeighbor = true;
            break;
          }
        }
        if (!hasLockedNeighbor) {
          lockedSet.add(idx);
        }
      }
    }
  }

  final restrictedMap = <int, Set<PuzzleColor>>{};
  if (requestedRestricted != null) {
    final targetColorsList = targetInventory.keys.toList();
    for (final idx in requestedRestricted) {
      if (idx < raw.nodes.length && !lockedSet.contains(idx)) {
        final correctColor = coloring[idx]!;
        final otherColors = targetColorsList.where((c) => c != correctColor).toList();
        if (otherColors.isNotEmpty) {
          final distractor = otherColors[(idx) % otherColors.length];
          restrictedMap[idx] = {correctColor, distractor};
        }
      }
    }
  }

  final nodes = <String, GraphNode>{};
  for (int i = 0; i < raw.nodes.length; i++) {
    final rn = raw.nodes[i];
    final isLocked = lockedSet.contains(i);
    final restricted = restrictedMap[i];

    nodes[rn.id] = GraphNode(
      id: rn.id,
      x: rn.x,
      y: rn.y,
      isLocked: isLocked,
      currentColor: isLocked ? coloring[i] : null,
      restrictedColors: restricted,
    );
  }

  final edges = <GraphEdge>{};
  for (final e in raw.edges) {
    final uId = raw.nodes[e[0]].id;
    final vId = raw.nodes[e[1]].id;
    edges.add(GraphEdge(uId, vId));
  }

  final graph = Graph(nodes: nodes, edges: edges);

  return PuzzleLevel(
    id: id,
    chapterId: chapterId,
    levelNumber: levelNumber,
    overallIndex: overallIndex,
    title: title,
    difficulty: difficulty,
    initialGraph: graph,
    targetInventory: targetInventory,
  );
}

// ---------------------------------------------------------------------------
// CHAPTER 1 (Level 1..30)
// ---------------------------------------------------------------------------

List<PuzzleLevel> generateChapter1() {
  final levels = <PuzzleLevel>[];
  final p2 = [PuzzleColor.red, PuzzleColor.blue];

  final titles = [
    'Bước Chân Đầu Tiên', 'Đường Đôi', 'Vòng Tròn Giao Hòa', 'Giao Điểm 1', 'Ngôi Sao Nhỏ',
    'Chữ Thập Đơn', 'Cánh Cung', 'Lưới 4 Đỉnh', 'Cầu Nối Nhẹ', 'Gió Thoảng',
    'Đường Dài 5', 'Nhánh Đôi', 'Cây Ba Lá', 'Hình Quạt 5', 'Chong Chóng',
    'Ngôi Sao 5 Cánh', 'Cầu Nhịp 5', 'Lưới Bậc Thang', 'Bình Minh', 'Sóng Đôi',
    'Lục Giác Tròn', 'Bậc Thang 6', 'Đường Xuyên 6', 'Mắt Kính', 'Hoa Sáu Cánh',
    'Cặp Tam Giác Mở', 'Lưới 2x3', 'Cánh Bướm', 'Cây Lục Điểm', 'Cầu Vồng Đôi'
  ];

  for (int i = 1; i <= 30; i++) {
    final id = 'c1_l${i.toString().padLeft(2, '0')}';
    final diff = r3(1.0 + (i - 1) * (0.5 / 29));
    final title = titles[i - 1];
    RawGraph raw;

    if (i <= 10) {
      if (i % 3 == 1) {
        raw = makePathGraph(4, 0.2, 0.5, 0.8, 0.5);
      } else if (i % 3 == 2) {
        raw = makeCycleGraph(4, 0.5, 0.5, 0.28);
      } else {
        raw = makeStarGraph(3, 0.5, 0.5, 0.3);
      }
    } else if (i <= 20) {
      if (i % 3 == 1) {
        raw = makePathGraph(5, 0.15, 0.5, 0.85, 0.5);
      } else if (i % 3 == 2) {
        raw = makeStarGraph(4, 0.5, 0.5, 0.32);
      } else {
        raw = RawGraph([
          RawNode('n1', 0.2, 0.5),
          RawNode('n2', 0.5, 0.5),
          RawNode('n3', 0.8, 0.5),
          RawNode('n4', 0.5, 0.2),
          RawNode('n5', 0.5, 0.8),
        ], [
          [0, 1], [1, 2], [1, 3], [1, 4]
        ]);
      }
    } else {
      if (i % 4 == 1) {
        raw = makeCycleGraph(6, 0.5, 0.5, 0.32);
      } else if (i % 4 == 2) {
        raw = makeGridGraph(2, 3, 0.25, 0.3, 0.75, 0.7);
      } else if (i % 4 == 3) {
        raw = makePathGraph(6, 0.15, 0.5, 0.85, 0.5);
      } else {
        raw = makeStarGraph(5, 0.5, 0.5, 0.34);
      }
    }

    levels.add(buildLevel(
      id: id,
      chapterId: 1,
      levelNumber: i,
      overallIndex: i,
      title: title,
      difficulty: diff,
      raw: raw,
      palette: p2,
      requiredDistinctColors: 2,
    ));
  }

  return levels;
}

// ---------------------------------------------------------------------------
// CHAPTER 2 (Level 31..60)
// ---------------------------------------------------------------------------

List<PuzzleLevel> generateChapter2() {
  final levels = <PuzzleLevel>[];
  final p2 = [PuzzleColor.red, PuzzleColor.blue];
  final p3 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow];

  final titles = [
    'Cân Bằng Nhẹ', 'Hai Nhánh', 'Lục Giác Kép', 'Dây Chuyền Đôi', 'Cột Chống',
    'Thước Thợ', 'Thang Đứng', 'Lưới 6 Cân', 'Khởi Sắc Tam Giác', 'Bánh Xe Tam Giác',
    'Lăng Kính 3', 'Hình Quạt 7', 'Quạt Bảy Cánh', 'Cầu Vồng Ba Màu', 'Tia Nắng',
    'Đĩa Bay 7', 'Tam Giác Lồng', 'Vòng Tròn Ba Màu', 'Kim Tự Tháp Nhỏ', 'Ngã Ba Đường',
    'Bát Giác Phẳng', 'Lăng Kính 4', 'Quạt Tám Cánh', 'Lưới 2x4', 'Sao Tám Cánh',
    'Cánh Hoa Kép', 'Khung Nhà 8', 'Mạng Đôi 8', 'Lưới 3x3', 'Đỉnh Cao Cân Bằng'
  ];

  for (int i = 1; i <= 30; i++) {
    final overall = 30 + i;
    final id = 'c2_l${i.toString().padLeft(2, '0')}';
    final diff = r3(1.5 + (i - 1) * (0.7 / 29));
    final title = titles[i - 1];
    RawGraph raw;
    List<PuzzleColor> palette;
    int requiredColors;

    if (i <= 8) {
      palette = p2;
      requiredColors = 2;
      if (i <= 4) {
        raw = makeGridGraph(2, 3, 0.25, 0.3, 0.75, 0.7);
      } else {
        raw = makeStarGraph(6, 0.5, 0.5, 0.35);
      }
    } else if (i <= 20) {
      palette = p3;
      requiredColors = 3;
      if (i % 3 == 1) {
        raw = makeWheelGraph(6, 0.5, 0.5, 0.34);
      } else if (i % 3 == 2) {
        raw = makeFanGraph(6, 0.5, 0.7, 0.45, -pi * 0.8, pi * 0.6);
      } else {
        final prism = makePrismGraph(3, 0.5, 0.5, 0.36, 0.18);
        prism.nodes.add(RawNode('n7', 0.5, 0.88));
        prism.edges.add([0, 6]);
        prism.edges.add([1, 6]);
        raw = prism;
      }
    } else {
      palette = p3;
      requiredColors = 3;
      if (i % 3 == 1) {
        raw = makePrismGraph(4, 0.5, 0.5, 0.36, 0.2);
      } else if (i % 3 == 2) {
        raw = makeFanGraph(7, 0.5, 0.7, 0.45, -pi * 0.85, pi * 0.7);
      } else {
        raw = makeGridGraph(3, 3, 0.2, 0.2, 0.8, 0.8);
      }
    }

    levels.add(buildLevel(
      id: id,
      chapterId: 2,
      levelNumber: i,
      overallIndex: overall,
      title: title,
      difficulty: diff,
      raw: raw,
      palette: palette,
      requiredDistinctColors: requiredColors,
    ));
  }

  return levels;
}

// ---------------------------------------------------------------------------
// CHAPTER 3 (Level 61..90)
// ---------------------------------------------------------------------------

List<PuzzleLevel> generateChapter3() {
  final levels = <PuzzleLevel>[];
  final p3 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow];
  final p4 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow, PuzzleColor.green];

  final titles = [
    'Điểm Tựa Ban Đầu', 'Khóa Chân Cầu', 'Mỏ Neo Đỏ', 'Tâm Bánh Xe', 'Mắt Kính Cố Định',
    'Trục Giữa', 'Cột Mốc Vàng', 'Giao Điểm Khóa', 'Neo Đôi', 'Song Trụ',
    'Tam Trụ 10', 'Bánh Xe Kép', 'Cầu Treo 10', 'Khung Đỡ', 'Lăng Kính Khóa',
    'Tâm Bão 10', 'Vành Đai Cố Định', 'Hai Đầu Cầu', 'Đỉnh Tháp Khóa', 'Hòn Đá Tảng',
    'Lưới Khóa 11', 'Trận Đồ 11', 'Cột Cờ 11', 'Thành Trì 12', 'Vòng Tròn Đá',
    'Thập Tự Khóa', 'Tháp Đôi 12', 'Mắt Bão Tứ Trụ', 'Vương Miện', 'Pháo Đài Bất Khả'
  ];

  for (int i = 1; i <= 30; i++) {
    final overall = 60 + i;
    final id = 'c3_l${i.toString().padLeft(2, '0')}';
    final diff = r3(2.2 + (i - 1) * (0.8 / 29));
    final title = titles[i - 1];
    RawGraph raw;
    List<PuzzleColor> palette;
    int requiredColors;
    List<int> locked;

    if (i <= 10) {
      palette = p3;
      requiredColors = 3;
      raw = makeFanGraph(i <= 5 ? 7 : 8, 0.5, 0.7, 0.45, -pi * 0.85, pi * 0.7);
      locked = [0];
    } else if (i <= 20) {
      if (i % 2 == 0) {
        palette = p4;
        requiredColors = 4;
        raw = makePrismGraph(5, 0.5, 0.5, 0.36, 0.2); // 10 nodes
        locked = [0, 6];
      } else {
        palette = p3;
        requiredColors = 3;
        raw = makeFanGraph(9, 0.5, 0.7, 0.45, -pi * 0.85, pi * 0.7); // 10 nodes
        locked = [0, 2];
      }
    } else {
      palette = p4;
      requiredColors = 4;
      if (i % 2 == 0) {
        raw = makePrismGraph(6, 0.5, 0.5, 0.36, 0.2); // 12 nodes
        locked = [0, 4, 8];
      } else {
        final p5Graph = makePrismGraph(5, 0.5, 0.5, 0.36, 0.2);
        p5Graph.nodes.add(RawNode('n11', 0.5, 0.88));
        p5Graph.edges.add([0, 10]);
        p5Graph.edges.add([1, 10]);
        raw = p5Graph;
        locked = [0, 6];
      }
    }

    levels.add(buildLevel(
      id: id,
      chapterId: 3,
      levelNumber: i,
      overallIndex: overall,
      title: title,
      difficulty: diff,
      raw: raw,
      palette: palette,
      requiredDistinctColors: requiredColors,
      requestedLocked: locked,
    ));
  }

  return levels;
}

// ---------------------------------------------------------------------------
// CHAPTER 4 (Level 91..120)
// ---------------------------------------------------------------------------

List<PuzzleLevel> generateChapter4() {
  final levels = <PuzzleLevel>[];
  final p3 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow];
  final p4 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow, PuzzleColor.green];

  final titles = [
    'Mạng Nhện Đan Chéo', 'Cầu Nối Kép', 'Điểm Nghẽn Mạch', 'Vòng Hoa Lồng', 'Ma Trận 10',
    'Vành Đai Kép', 'Mạng Tinh Thể', 'Lưới Đan 11', 'Trục Xoay 11', 'Gút Thắt 11',
    'Mê Cung Dây', 'Bát Giác Liên Hoàn', 'Hai Cụm Sao', 'Ốc Đảo Nối', 'Lăng Kính Lục Giác',
    'Lưới Kim Cương', 'Cột Chống Kép', 'Vòng Xoáy 12', 'Mạng Lưới Thoi', 'Mắt Xích 13',
    'Tổ Ong 13', 'Liên Mạng 13', 'Xương Cá 13', 'Mạng Đa Tầng 14', 'Bánh Xe Đôi 14',
    'Ma Trận Lưới 14', 'Cầu Ghép 14', 'Lăng Trụ Thất Giác', 'Bát Quái Trận', 'Mạng Phức Hợp Cuối'
  ];

  for (int i = 1; i <= 30; i++) {
    final overall = 90 + i;
    final id = 'c4_l${i.toString().padLeft(2, '0')}';
    final diff = r3(3.0 + (i - 1) * (0.8 / 29));
    final title = titles[i - 1];
    RawGraph raw;
    List<PuzzleColor> palette;
    int requiredColors;
    List<int> locked;

    if (i <= 10) {
      if (i % 2 == 1) {
        palette = p4;
        requiredColors = 4;
        raw = makePrismGraph(5, 0.5, 0.5, 0.36, 0.2);
        raw.edges.add([0, 2]);
        raw.edges.add([1, 3]);
        locked = [0, 6];
      } else {
        palette = p3;
        requiredColors = 3;
        raw = makeFanGraph(10, 0.5, 0.7, 0.45, -pi * 0.85, pi * 0.7);
        locked = [0, 3];
      }
    } else if (i <= 20) {
      palette = p4;
      requiredColors = 4;
      raw = makePrismGraph(6, 0.5, 0.5, 0.36, 0.2);
      raw.edges.add([0, 3]);
      raw.edges.add([6, 9]);
      locked = [0, 4, 8];
    } else {
      palette = p4;
      requiredColors = 4;
      raw = makePrismGraph(7, 0.5, 0.5, 0.36, 0.2);
      raw.edges.add([0, 2]);
      raw.edges.add([7, 9]);
      locked = [0, 5, 10];
    }

    levels.add(buildLevel(
      id: id,
      chapterId: 4,
      levelNumber: i,
      overallIndex: overall,
      title: title,
      difficulty: diff,
      raw: raw,
      palette: palette,
      requiredDistinctColors: requiredColors,
      requestedLocked: locked,
    ));
  }

  return levels;
}

// ---------------------------------------------------------------------------
// CHAPTER 5 (Level 121..150)
// ---------------------------------------------------------------------------

List<PuzzleLevel> generateChapter5() {
  final levels = <PuzzleLevel>[];
  final p4 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow, PuzzleColor.green];
  final p5 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow, PuzzleColor.green, PuzzleColor.purple];

  final titles = [
    'Lựa Chọn Hẹp', 'Cánh Cửa Khép', 'Ma Trận Nhị Sắc', 'Điểm Giới Hạn', 'Lối Đi Độc Đạo',
    'Tập Màu Đóng', 'Ràng Buộc Kép', 'Khe Hẹp 12', 'Mắt Kính Hạn Chế', 'Ngõ Cụt Thắt',
    'Thử Thách Tím', 'Ngũ Sắc Khởi Đầu', 'Màng Lọc 13', 'Khu Rừng Màu', 'Lăng Kính Ngũ Sắc',
    'Đường Cùng Hẹp', 'Bánh Xe Hạn Chế', 'Nút Thắt Tím', 'Tam Giác Giới Hạn', 'Ma Trận Lọc 14',
    'Mạng Lưới Thắt', 'Tường Lửa', 'Mê Cung Hẹp', 'Đường Một Chiều', 'Cổng Ngũ Sắc',
    'Lưới Giới Hạn 15', 'Tổ Ong Thắt', 'Mạng Kim Cương Hẹp', 'Vành Đai Lọc', 'Khúc Ca Hẹp Nhất'
  ];

  for (int i = 1; i <= 30; i++) {
    final overall = 120 + i;
    final id = 'c5_l${i.toString().padLeft(2, '0')}';
    final diff = r3(3.8 + (i - 1) * (0.7 / 29));
    final title = titles[i - 1];
    RawGraph raw;
    List<PuzzleColor> palette;
    int requiredColors;
    List<int> locked;
    List<int> restricted;

    if (i <= 10) {
      palette = p4;
      requiredColors = 4;
      raw = makePrismGraph(6, 0.5, 0.5, 0.36, 0.2); // 12 nodes
      locked = [0, 4];
      restricted = [2, 8];
    } else if (i <= 20) {
      if (i % 2 == 1) {
        palette = p5;
        requiredColors = 5;
      } else {
        palette = p4;
        requiredColors = 4;
      }
      raw = makePrismGraph(7, 0.5, 0.5, 0.36, 0.2); // 14 nodes
      locked = [0, 5];
      restricted = [2, 9];
    } else {
      palette = p5;
      requiredColors = 5;
      raw = makePrismGraph(8, 0.5, 0.5, 0.36, 0.2); // 16 nodes
      locked = [0, 6, 12];
      restricted = [2, 8, 14];
    }

    levels.add(buildLevel(
      id: id,
      chapterId: 5,
      levelNumber: i,
      overallIndex: overall,
      title: title,
      difficulty: diff,
      raw: raw,
      palette: palette,
      requiredDistinctColors: requiredColors,
      requestedLocked: locked,
      requestedRestricted: restricted,
    ));
  }

  return levels;
}

// ---------------------------------------------------------------------------
// CHAPTER 6 (Level 151..180)
// ---------------------------------------------------------------------------

List<PuzzleLevel> generateChapter6() {
  final levels = <PuzzleLevel>[];
  final p4 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow, PuzzleColor.green];
  final p5 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow, PuzzleColor.green, PuzzleColor.purple];

  final titles = [
    'Đỉnh Cao Trí Tuệ', 'Mạng Bậc Thầy 1', 'Mê Cung Tinh Thể', 'Vòng Xoáy Vô Tận', 'Thập Trận Đồ',
    'Kim Tự Tháp Lớn', 'Trục Xoay Ngũ Sắc', 'Cổng Địa Ngục', 'Khúc Quanh Tử Thần', 'Lưới Siêu Phức',
    'Bàn Cờ Vua', 'Mắt Bão Hỗn Mang', 'Tòa Tháp Đôi 16', 'Mạng Sao Kép', 'Vành Đai Asteroid',
    'Bát Giác Hoàn Hảo', 'Tổ Ong Khổng Lồ', 'Mê Cung Ngũ Hành', 'Lăng Kính Đa Chiều', 'Cầu Nối Không Gian',
    'Thử Thách Thần Thánh', 'Ma Trận 18 Đỉnh', 'Vòng Xoáy Lượng Tử', 'Đỉnh Mù Sương', 'Cực Hạn Tư Duy',
    'Thành Trì Cuối Cùng', 'Hố Đen Vũ Trụ', 'Vòng Hoa Vĩnh Cửu', 'Trận Đồ Bát Quái', 'Đại Kết Mạng 180'
  ];

  for (int i = 1; i <= 30; i++) {
    final overall = 150 + i;
    final id = 'c6_l${i.toString().padLeft(2, '0')}';
    final diff = r3(4.5 + (i - 1) * (0.5 / 29));
    final title = titles[i - 1];
    RawGraph raw;
    List<PuzzleColor> palette;
    int requiredColors;
    List<int> locked;
    List<int> restricted;

    if (i <= 10) {
      if (i % 2 == 1) {
        palette = p5;
        requiredColors = 5;
      } else {
        palette = p4;
        requiredColors = 4;
      }
      raw = makePrismGraph(7, 0.5, 0.5, 0.36, 0.2); // 14 nodes
      locked = [0, 4, 9];
      restricted = [2, 11];
    } else if (i <= 20) {
      palette = p5;
      requiredColors = 5;
      raw = makePrismGraph(8, 0.5, 0.5, 0.36, 0.2); // 16 nodes
      locked = [0, 5, 11];
      restricted = [2, 8, 14];
    } else {
      palette = p5;
      requiredColors = 5;
      final sides = (i <= 25) ? 9 : 10; // 18 hoặc 20 nodes
      raw = makePrismGraph(sides, 0.5, 0.5, 0.37, 0.22);
      locked = [0, sides ~/ 2, sides + 2];
      restricted = [2, 6, sides + 4];
    }

    levels.add(buildLevel(
      id: id,
      chapterId: 6,
      levelNumber: i,
      overallIndex: overall,
      title: title,
      difficulty: diff,
      raw: raw,
      palette: palette,
      requiredDistinctColors: requiredColors,
      requestedLocked: locked,
      requestedRestricted: restricted,
    ));
  }

  return levels;
}

// ---------------------------------------------------------------------------
// FILE SERIALIZER
// ---------------------------------------------------------------------------

String colorIdent(PuzzleColor c) {
  switch (c.code) {
    case 'RED':
      return 'red';
    case 'BLUE':
      return 'blue';
    case 'YELLOW':
      return 'yellow';
    case 'GREEN':
      return 'green';
    case 'PURPLE':
      return 'purple';
    default:
      return 'red';
  }
}

void writeChapterFile(int chapterId, List<PuzzleLevel> levels) {
  final file = File('lib/features/campaign/data/levels/chapter_${chapterId}_levels.dart');
  file.parent.createSync(recursive: true);

  final sb = StringBuffer();
  sb.writeln("import '../../../graph_coloring/domain/entities/graph.dart';");
  sb.writeln("import '../../../graph_coloring/domain/entities/graph_edge.dart';");
  sb.writeln("import '../../../graph_coloring/domain/entities/graph_node.dart';");
  sb.writeln("import '../../../graph_coloring/domain/entities/puzzle_color.dart';");
  sb.writeln("import '../../domain/entities/puzzle_level.dart';");
  sb.writeln();
  sb.writeln("/// Dữ liệu 30 màn chơi của Chapter $chapterId.");
  sb.writeln("final List<PuzzleLevel> chapter${chapterId}Levels = [");

  for (final level in levels) {
    sb.writeln("  PuzzleLevel(");
    sb.writeln("    id: '${level.id}',");
    sb.writeln("    chapterId: ${level.chapterId},");
    sb.writeln("    levelNumber: ${level.levelNumber},");
    sb.writeln("    overallIndex: ${level.overallIndex},");
    sb.writeln("    title: '${level.title}',");
    sb.writeln("    difficulty: ${level.difficulty},");
    sb.writeln("    initialGraph: Graph(");
    sb.writeln("      nodes: {");
    for (final node in level.initialGraph.nodes.values) {
      final lockedPart = node.isLocked ? ", isLocked: true" : "";
      final colorPart = node.currentColor != null
          ? ", currentColor: PuzzleColor.${colorIdent(node.currentColor!)}"
          : "";
      final restrictedPart = node.restrictedColors != null
          ? ", restrictedColors: {${node.restrictedColors!.map((c) => 'PuzzleColor.${colorIdent(c)}').join(', ')}}"
          : "";
      sb.writeln(
          "        '${node.id}': GraphNode(id: '${node.id}', x: ${node.x}, y: ${node.y}$lockedPart$colorPart$restrictedPart),");
    }
    sb.writeln("      },");
    sb.writeln("      edges: {");
    for (final edge in level.initialGraph.edges) {
      sb.writeln("        GraphEdge('${edge.u}', '${edge.v}'),");
    }
    sb.writeln("      },");
    sb.writeln("    ),");
    sb.writeln("    targetInventory: {");
    for (final entry in level.targetInventory.entries) {
      sb.writeln("      PuzzleColor.${colorIdent(entry.key)}: ${entry.value},");
    }
    sb.writeln("    },");
    sb.writeln("  ),");
  }

  sb.writeln("];");

  file.writeAsStringSync(sb.toString());
  stdout.writeln('Đã ghi file: ${file.path} (${levels.length} levels)');
}
