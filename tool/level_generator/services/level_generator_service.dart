import 'package:graph_coloring/features/campaign/domain/entities/puzzle_level.dart';
import 'package:graph_coloring/features/campaign/domain/services/level_validator.dart';
import 'package:graph_coloring/features/graph_coloring/domain/algorithms/csp_solver.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/puzzle_color.dart';
import '../constraints/constraint_synthesizer.dart';
import '../layouts/layout_engine.dart';
import '../models/difficulty_profile.dart';
import '../models/graph_signature.dart';
import '../models/raw_graph_data.dart';

/// Kết quả của một level được sinh và kiểm định.
class GeneratedLevelResult {
  const GeneratedLevelResult({
    required this.level,
    required this.signatures,
    required this.difficultyProfile,
    required this.validationErrors,
    required this.solutionCount,
    required this.minNodeDistance,
  });

  final PuzzleLevel level;
  final GraphSignatures signatures;
  final DifficultyProfile difficultyProfile;
  final List<String> validationErrors;
  final int solutionCount;
  final double minNodeDistance;

  bool get isValid => validationErrors.isEmpty && solutionCount >= 1;
}

/// Dịch vụ điều phối toàn diện quá trình sinh level offline (Level Generator Service).
class LevelGeneratorService {
  LevelGeneratorService({
    this.layoutEngine = const LayoutEngine(),
    this.constraintSynthesizer = const ConstraintSynthesizer(),
    this.validator = const LevelValidator(),
    this.solver = const CspSolver(),
  });

  final LayoutEngine layoutEngine;
  final ConstraintSynthesizer constraintSynthesizer;
  final LevelValidator validator;
  final CspSolver solver;

  /// Xử lý tạo và xác thực một level hoàn chỉnh từ RawGraphData
  GeneratedLevelResult processLevel({
    required String id,
    required int chapterId,
    required int levelNumber,
    required int overallIndex,
    required String title,
    required double baseDifficulty,
    required RawGraphData rawGraph,
    required List<PuzzleColor> palette,
    required int requiredDistinctColors,
    List<int>? lockedNodeIndices,
    List<int>? restrictedNodeIndices,
    int seed = 42,
  }) {
    // 1. Tối ưu hóa bố cục hình học và khử va chạm
    final optimizedRaw = layoutEngine.optimizeLayout(rawGraph);
    final minDist = optimizedRaw.minNodeDistance();

    // 2. Tổng hợp lời giải, kho màu và các ràng buộc
    final puzzleLevel = constraintSynthesizer.synthesizeLevel(
      id: id,
      chapterId: chapterId,
      levelNumber: levelNumber,
      overallIndex: overallIndex,
      title: title,
      difficulty: baseDifficulty,
      raw: optimizedRaw,
      palette: palette,
      requiredDistinctColors: requiredDistinctColors,
      lockedNodeIndices: lockedNodeIndices,
      restrictedNodeIndices: restrictedNodeIndices,
      seed: seed,
    );

    // 3. Thẩm định độc lập bằng LevelValidator
    final validationErrors = validator.validateSingleLevel(puzzleLevel);

    // 4. Đo số lượng nghiệm và kiểm tra solvability
    final initialInventory = puzzleLevel.createInitialInventory();
    final solCount = solver.countSolutions(
      graph: puzzleLevel.initialGraph,
      inventory: initialInventory,
      maxCount: 2,
    );

    // 5. Tính toán các chữ ký đa tầng (Topology, Layout, Gameplay)
    final signatures = GraphSignatures.fromLevel(puzzleLevel);

    // 6. Tính toán hồ sơ độ khó định lượng
    final difficultyProfile = DifficultyProfile.evaluate(
      level: puzzleLevel,
      solverSearchSteps: puzzleLevel.initialGraph.nodes.length,
      backtrackCount: 0,
    );

    return GeneratedLevelResult(
      level: puzzleLevel,
      signatures: signatures,
      difficultyProfile: difficultyProfile,
      validationErrors: validationErrors,
      solutionCount: solCount,
      minNodeDistance: minDist,
    );
  }
}
