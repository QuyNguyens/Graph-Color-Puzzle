import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_coloring/features/campaign/domain/services/star_rating_calculator.dart';
import 'package:graph_coloring/features/graph_coloring/data/datasources/daily_hint_local_datasource.dart';
import 'package:graph_coloring/features/graph_coloring/data/models/saved_session_dto.dart';
import 'package:graph_coloring/features/graph_coloring/data/repositories/daily_hint_repository_impl.dart';
import 'package:graph_coloring/features/graph_coloring/domain/algorithms/csp_solver.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/color_inventory.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/graph.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/graph_edge.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/graph_node.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/puzzle_color.dart';
import 'package:graph_coloring/features/graph_coloring/domain/services/hint_service.dart';
import 'package:graph_coloring/features/graph_coloring/application/game_view_state.dart';

class FakeDailyHintDataSource extends DailyHintLocalDataSource {
  String? _raw;

  @override
  Future<String?> getRawQuota() async => _raw;

  @override
  Future<void> saveRawQuota(String jsonString) async {
    _raw = jsonString;
  }

  @override
  Future<void> clearRawQuota() async {
    _raw = null;
  }
}

void main() {
  group('HintService Tests', () {
    const hintService = HintService(solver: CspSolver());

    test('Tạo gợi ý hợp lệ cho đồ thị đơn giản', () {
      final nodes = {
        'A': const GraphNode(id: 'A', x: 0.2, y: 0.2),
        'B': const GraphNode(id: 'B', x: 0.8, y: 0.2),
        'C': const GraphNode(id: 'C', x: 0.5, y: 0.8),
      };
      final edges = {
        const GraphEdge(u: 'A', v: 'B'),
        const GraphEdge(u: 'B', v: 'C'),
        const GraphEdge(u: 'C', v: 'A'),
      };
      final graph = Graph(nodes: nodes, edges: edges);
      final inventory = ColorInventory.initial({
        PuzzleColor.red: 1,
        PuzzleColor.blue: 1,
        PuzzleColor.yellow: 1,
      });

      final hint = hintService.generateHint(graph: graph, inventory: inventory);
      expect(hint, isNotNull);
      expect(['A', 'B', 'C'].contains(hint!.nodeId), isTrue);
      expect(
        [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow]
            .contains(hint.color),
        isTrue,
      );
    });

    test('Không gợi ý cho đồ thị bế tắc (vô nghiệm)', () {
      // Đồ thị tam giác K3 nhưng chỉ có 2 màu
      final nodes = {
        'A': const GraphNode(id: 'A', x: 0.2, y: 0.2),
        'B': const GraphNode(id: 'B', x: 0.8, y: 0.2),
        'C': const GraphNode(id: 'C', x: 0.5, y: 0.8),
      };
      final edges = {
        const GraphEdge(u: 'A', v: 'B'),
        const GraphEdge(u: 'B', v: 'C'),
        const GraphEdge(u: 'C', v: 'A'),
      };
      final graph = Graph(nodes: nodes, edges: edges);
      final inventory = ColorInventory.initial({
        PuzzleColor.red: 2,
        PuzzleColor.blue: 1,
      });

      final hint = hintService.generateHint(graph: graph, inventory: inventory);
      expect(hint, isNull);
    });

    test('Không gợi ý khi đồ thị đã được tô hoàn tất', () {
      final nodes = {
        'A': const GraphNode(
          id: 'A',
          x: 0.2,
          y: 0.2,
          currentColor: PuzzleColor.red,
        ),
        'B': const GraphNode(
          id: 'B',
          x: 0.8,
          y: 0.2,
          currentColor: PuzzleColor.blue,
        ),
      };
      final edges = {const GraphEdge(u: 'A', v: 'B')};
      final graph = Graph(nodes: nodes, edges: edges);
      const inventory = ColorInventory(
        targetCounts: {PuzzleColor.red: 1, PuzzleColor.blue: 1},
        usedCounts: {PuzzleColor.red: 1, PuzzleColor.blue: 1},
      );

      final hint = hintService.generateHint(graph: graph, inventory: inventory);
      expect(hint, isNull);
    });

    test('Không gợi ý các Locked Nodes', () {
      final nodes = {
        'A': const GraphNode(
          id: 'A',
          x: 0.2,
          y: 0.2,
          isLocked: true,
          currentColor: PuzzleColor.red,
        ),
        'B': const GraphNode(id: 'B', x: 0.8, y: 0.2),
      };
      final edges = {const GraphEdge(u: 'A', v: 'B')};
      final graph = Graph(nodes: nodes, edges: edges);
      const inventory = ColorInventory(
        targetCounts: {PuzzleColor.red: 1, PuzzleColor.blue: 1},
        usedCounts: {PuzzleColor.red: 1, PuzzleColor.blue: 0},
      );

      final hint = hintService.generateHint(graph: graph, inventory: inventory);
      expect(hint, isNotNull);
      expect(hint!.nodeId, 'B');
      expect(hint.color, PuzzleColor.blue);
    });

    test('MRV Heuristic: Ưu tiên node có domain khả thi nhỏ nhất (Restricted Colors)', () {
      // Node A bị giới hạn chỉ được dùng Yellow -> domain size 1
      // Node B được dùng Red hoặc Yellow -> domain size 2
      final nodes = {
        'A': const GraphNode(
          id: 'A',
          x: 0.2,
          y: 0.2,
          restrictedColors: {PuzzleColor.yellow},
        ),
        'B': const GraphNode(id: 'B', x: 0.8, y: 0.2),
      };
      final edges = {const GraphEdge(u: 'A', v: 'B')};
      final graph = Graph(nodes: nodes, edges: edges);
      final inventory = ColorInventory.initial({
        PuzzleColor.red: 1,
        PuzzleColor.yellow: 1,
      });

      final hint = hintService.generateHint(graph: graph, inventory: inventory);
      expect(hint, isNotNull);
      // Node A phải được chọn vì MRV domain size (1) < Node B domain size (2)
      expect(hint!.nodeId, 'A');
      expect(hint.color, PuzzleColor.yellow);
    });

    test('DSATUR Heuristic: Phân xử khi MRV bằng nhau, ưu tiên node có đỉnh kề nhiều màu khác nhau nhất', () {
      // Đồ thị: Center1 kề 2 node (Red, Blue) -> saturation = 2
      // Center2 kề 1 node (Red) -> saturation = 1
      // Cả hai đều có domain kích thước 1 (chỉ còn Yellow)
      final nodes = {
        'R1': const GraphNode(id: 'R1', x: 0.1, y: 0.1, currentColor: PuzzleColor.red),
        'B1': const GraphNode(id: 'B1', x: 0.1, y: 0.5, currentColor: PuzzleColor.blue),
        'C1': const GraphNode(id: 'C1', x: 0.3, y: 0.3), // Saturation = 2
        'R2': const GraphNode(id: 'R2', x: 0.7, y: 0.1, currentColor: PuzzleColor.red),
        'C2': const GraphNode(id: 'C2', x: 0.7, y: 0.3), // Saturation = 1
      };
      final edges = {
        const GraphEdge(u: 'R1', v: 'C1'),
        const GraphEdge(u: 'B1', v: 'C1'),
        const GraphEdge(u: 'R2', v: 'C2'),
      };
      final graph = Graph(nodes: nodes, edges: edges);
      const inventory = ColorInventory(
        targetCounts: {
          PuzzleColor.red: 2,
          PuzzleColor.blue: 1,
          PuzzleColor.yellow: 2,
        },
        usedCounts: {
          PuzzleColor.red: 2,
          PuzzleColor.blue: 1,
          PuzzleColor.yellow: 0,
        },
      );

      final hint = hintService.generateHint(graph: graph, inventory: inventory);
      expect(hint, isNotNull);
      // C1 có saturation cao hơn C2 -> được chọn trước
      expect(hint!.nodeId, 'C1');
      expect(hint.color, PuzzleColor.yellow);
    });
  });

  group('DailyHintRepository Tests', () {
    late FakeDailyHintDataSource dataSource;
    late DateTime currentDate;

    setUp(() {
      dataSource = FakeDailyHintDataSource();
      currentDate = DateTime(2026, 11, 13, 10, 0);
    });

    DailyHintRepositoryImpl createRepo() {
      return DailyHintRepositoryImpl(
        localDataSource: dataSource,
        nowProvider: () => currentDate,
      );
    }

    test('Khởi tạo mặc định có 1 hint mỗi ngày', () async {
      final repo = createRepo();
      final quota = await repo.getRemainingHints();
      expect(quota, 1);
    });

    test('Tiêu thụ nguyên tử 1 -> 0 -> null', () async {
      final repo = createRepo();

      final q1 = await repo.consumeHint();
      expect(q1, 0);

      // Khi hết lượt, trả về null
      final q2 = await repo.consumeHint();
      expect(q2, isNull);

      final remaining = await repo.getRemainingHints();
      expect(remaining, 0);
    });

    test('Tự động reset về 1 khi bước sang ngày mới', () async {
      final repo = createRepo();
      await repo.consumeHint();
      expect(await repo.getRemainingHints(), 0);

      // Chuyển sang ngày hôm sau
      currentDate = DateTime(2026, 11, 14, 8, 30);

      // Đọc lại quota ở ngày mới phải được reset cứng về 1
      expect(await repo.getRemainingHints(), 1);
    });

    test('Không cộng dồn quota ngày mới (tối đa 1 miễn phí)', () async {
      final repo = createRepo();
      // Không dùng hint nào trong ngày 13 (còn 1)
      expect(await repo.getRemainingHints(), 1);

      // Chuyển sang ngày 14
      currentDate = DateTime(2026, 11, 14, 8, 30);
      expect(await repo.getRemainingHints(), 1); // Vẫn là 1, không thành 2
    });

    test('Xem quảng cáo nhận thưởng cộng thêm +1 hint', () async {
      final repo = createRepo();
      await repo.consumeHint();
      expect(await repo.getRemainingHints(), 0);

      // Xem quảng cáo nhận thưởng +1 hint
      final rewarded = await repo.addHintReward(amount: 1);
      expect(rewarded, 1);
      expect(await repo.getRemainingHints(), 1);

      // Tiêu thụ hint vừa nhận
      final consumed = await repo.consumeHint();
      expect(consumed, 0);
    });

    test('Serialize thao tác gọi consumeHint đồng thời không gây race condition', () async {
      final repo = createRepo();

      // Gọi đồng thời 5 lần consumeHint
      final results = await Future.wait([
        repo.consumeHint(),
        repo.consumeHint(),
        repo.consumeHint(),
        repo.consumeHint(),
        repo.consumeHint(),
      ]);

      // Phải có đúng 1 lần thành công (về 0) và 4 lần trả về null
      final successful = results.where((r) => r != null).toList();
      final failed = results.where((r) => r == null).toList();

      expect(successful.length, 1);
      expect(failed.length, 4);
      expect(successful.first, 0);
      expect(await repo.getRemainingHints(), 0);
    });
  });

  group('SavedSessionDto Schema Migration Tests', () {
    test('Migration Version 1 -> Version 3: hints_used mặc định 0', () {
      final jsonV1 = {
        'version': 1,
        'level_id': 'c1_l01',
        'node_colors': {'A': 'red', 'B': null},
        'remaining_mistakes': 1,
        'has_used_continue': false,
        'undo_history': [],
      };

      final dto = SavedSessionDto.fromJson(jsonV1);
      expect(dto.version, 1);
      expect(dto.mistakesCount, 1); // 2 - 1 = 1
      expect(dto.hintsUsed, 0); // Mặc định 0
    });

    test('Migration Version 2 -> Version 3: hints_used mặc định 0', () {
      final jsonV2 = {
        'version': 2,
        'level_id': 'c2_l05',
        'node_colors': {'A': 'blue'},
        'remaining_mistakes': 2,
        'mistakes_count': 1,
        'has_used_continue': false,
        'undo_history': [],
      };

      final dto = SavedSessionDto.fromJson(jsonV2);
      expect(dto.version, 2);
      expect(dto.mistakesCount, 1);
      expect(dto.hintsUsed, 0);
    });

    test('Version 3 tuần tự hóa và giải mã đầy đủ hints_used', () {
      const dto = SavedSessionDto(
        version: SavedSessionDto.currentVersion,
        levelId: 'c3_l10',
        nodeColors: {'A': 'yellow'},
        remainingMistakes: 2,
        mistakesCount: 0,
        hintsUsed: 2,
        hasUsedContinue: false,
        undoHistory: [],
      );

      final jsonMap = dto.toJson();
      expect(jsonMap['version'], 3);
      expect(jsonMap['hints_used'], 2);

      final restored = SavedSessionDto.fromJson(jsonMap);
      expect(restored.version, 3);
      expect(restored.hintsUsed, 2);
    });

    test('Tuần tự hóa và giải mã has_used_undo chính xác', () {
      const dto = SavedSessionDto(
        version: SavedSessionDto.currentVersion,
        levelId: 'c1_l01',
        nodeColors: {'A': 'yellow'},
        remainingMistakes: 2,
        mistakesCount: 0,
        hintsUsed: 0,
        hasUsedContinue: false,
        hasUsedUndo: true,
        undoHistory: [],
      );

      final jsonMap = dto.toJson();
      expect(jsonMap['has_used_undo'], isTrue);

      final restored = SavedSessionDto.fromJson(jsonMap);
      expect(restored.hasUsedUndo, isTrue);
    });
  });

  group('StarRatingCalculator Tests', () {
    test('Dùng Hint (hintsUsed > 0) luôn nhận tối đa 1 sao', () {
      expect(
        StarRatingCalculator.calculateStars(
          isCompleted: true,
          hintsUsed: 1,
          mistakesCount: 0,
        ),
        1,
      );

      expect(
        StarRatingCalculator.calculateStars(
          isCompleted: true,
          hintsUsed: 2,
          mistakesCount: 1,
        ),
        1,
      );
    });

    test('Không dùng Hint (hintsUsed == 0), có lỗi nhận 2 sao', () {
      expect(
        StarRatingCalculator.calculateStars(
          isCompleted: true,
          hintsUsed: 0,
          mistakesCount: 1,
        ),
        2,
      );

      expect(
        StarRatingCalculator.calculateStars(
          isCompleted: true,
          hintsUsed: 0,
          mistakesCount: 2,
        ),
        2,
      );
    });

    test('Không dùng Hint (hintsUsed == 0) và 0 lỗi nhận 3 sao', () {
      expect(
        StarRatingCalculator.calculateStars(
          isCompleted: true,
          hintsUsed: 0,
          mistakesCount: 0,
        ),
        3,
      );
    });

    test('Chưa hoàn thành nhận 0 sao', () {
      expect(
        StarRatingCalculator.calculateStars(
          isCompleted: false,
          hintsUsed: 0,
          mistakesCount: 0,
        ),
        0,
      );
    });
  });

  group('hasPlacedBalls Tests', () {
    test('Bàn cờ ban đầu với các node chưa tô và node bị khóa -> hasPlacedBalls = false', () {
      final graph = Graph(
        nodes: {
          'n1': const GraphNode(id: 'n1', x: 0, y: 0, isLocked: true, currentColor: PuzzleColor.red),
          'n2': const GraphNode(id: 'n2', x: 1, y: 1),
          'n3': const GraphNode(id: 'n3', x: 0, y: 1),
        },
        edges: const [],
      );

      final state = GameViewState(
        levelId: 'c1_l01',
        graph: graph,
        inventory: const ColorInventory(targetCounts: {}, usedCounts: {}),
      );

      expect(state.hasPlacedBalls, isFalse);
    });

    test('Khi đặt ít nhất 1 quả bóng vào node không khóa -> hasPlacedBalls = true', () {
      final graph = Graph(
        nodes: {
          'n1': const GraphNode(id: 'n1', x: 0, y: 0, isLocked: true, currentColor: PuzzleColor.red),
          'n2': const GraphNode(id: 'n2', x: 1, y: 1, currentColor: PuzzleColor.blue),
          'n3': const GraphNode(id: 'n3', x: 0, y: 1),
        },
        edges: const [],
      );

      final state = GameViewState(
        levelId: 'c1_l01',
        graph: graph,
        inventory: const ColorInventory(targetCounts: {}, usedCounts: {}),
      );

      expect(state.hasPlacedBalls, isTrue);
    });

    test('Khi hoàn tác quả bóng vừa đặt -> hasPlacedBalls = false', () {
      final graph = Graph(
        nodes: {
          'n1': const GraphNode(id: 'n1', x: 0, y: 0, isLocked: true, currentColor: PuzzleColor.red),
          'n2': const GraphNode(id: 'n2', x: 1, y: 1, currentColor: null),
          'n3': const GraphNode(id: 'n3', x: 0, y: 1),
        },
        edges: const [],
      );

      final state = GameViewState(
        levelId: 'c1_l01',
        graph: graph,
        inventory: const ColorInventory(targetCounts: {}, usedCounts: {}),
        hasUsedUndo: true,
      );

      expect(state.hasPlacedBalls, isFalse);
    });
  });
}
