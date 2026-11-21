import 'package:graph_coloring/features/graph_coloring/domain/entities/puzzle_color.dart';
import '../topologies/topology_generators.dart';
import 'level_generator_service.dart';

/// Định nghĩa và danh mục 12 candidate levels đại diện cho 6 chapter.
class PrototypeCatalog {
  static List<GeneratedLevelResult> generateAllPrototypes(LevelGeneratorService service) {
    final p2 = [PuzzleColor.red, PuzzleColor.blue];
    final p3 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow];
    final p4 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow, PuzzleColor.green];
    final p5 = [PuzzleColor.red, PuzzleColor.blue, PuzzleColor.yellow, PuzzleColor.green, PuzzleColor.purple];

    final results = <GeneratedLevelResult>[];

    // =========================================================================
    // CHAPTER 1 (Level 1, 2)
    // =========================================================================
    results.add(service.processLevel(
      id: 'proto_c1_l01',
      chapterId: 1,
      levelNumber: 1,
      overallIndex: 1,
      title: 'Nhánh Cây Đầu Tiên',
      baseDifficulty: 1.0,
      rawGraph: TopologyGenerators.makeTreeBranching5(seed: 101),
      palette: p2,
      requiredDistinctColors: 2,
      seed: 101,
    ));

    results.add(service.processLevel(
      id: 'proto_c1_l02',
      chapterId: 1,
      levelNumber: 2,
      overallIndex: 2,
      title: 'Bậc Thang Lục Điểm',
      baseDifficulty: 1.1,
      rawGraph: TopologyGenerators.makeLadderGrid6(seed: 102),
      palette: p2,
      requiredDistinctColors: 2,
      seed: 102,
    ));

    // =========================================================================
    // CHAPTER 2 (Level 31, 32)
    // =========================================================================
    results.add(service.processLevel(
      id: 'proto_c2_l01',
      chapterId: 2,
      levelNumber: 1,
      overallIndex: 31,
      title: 'Bánh Xe Tam Sắc',
      baseDifficulty: 1.8,
      rawGraph: TopologyGenerators.makeWheel7(seed: 201),
      palette: p3,
      requiredDistinctColors: 3,
      seed: 201,
    ));

    results.add(service.processLevel(
      id: 'proto_c2_l02',
      chapterId: 2,
      levelNumber: 2,
      overallIndex: 32,
      title: 'Chuỗi Tam Giác Kép',
      baseDifficulty: 2.0,
      rawGraph: TopologyGenerators.makeTriangularChain8(seed: 202),
      palette: p3,
      requiredDistinctColors: 3,
      seed: 202,
    ));

    // =========================================================================
    // CHAPTER 3 (Level 61, 62)
    // =========================================================================
    results.add(service.processLevel(
      id: 'proto_c3_l01',
      chapterId: 3,
      levelNumber: 1,
      overallIndex: 61,
      title: 'Cầu Nối Song Đỉnh',
      baseDifficulty: 2.5,
      rawGraph: TopologyGenerators.makeBridgedTwinTriangles9(seed: 301),
      palette: p3,
      requiredDistinctColors: 3,
      lockedNodeIndices: [4], // Node cầu nối ở giữa
      seed: 301,
    ));

    results.add(service.processLevel(
      id: 'proto_c3_l02',
      chapterId: 3,
      levelNumber: 2,
      overallIndex: 62,
      title: 'Bánh Xe Tinh Tú',
      baseDifficulty: 2.8,
      rawGraph: TopologyGenerators.makeStarWheelHybrid11(seed: 302),
      palette: p4,
      requiredDistinctColors: 4,
      lockedNodeIndices: [0, 7], // Tâm bánh xe và 1 node vành ngoài
      seed: 302,
    ));

    // =========================================================================
    // CHAPTER 4 (Level 91, 92)
    // =========================================================================
    results.add(service.processLevel(
      id: 'proto_c4_l01',
      chapterId: 4,
      levelNumber: 1,
      overallIndex: 91,
      title: 'Lục Giác Giao Thoa',
      baseDifficulty: 3.2,
      rawGraph: TopologyGenerators.makeInterconnectedHexagons12(seed: 401),
      palette: p4,
      requiredDistinctColors: 4,
      lockedNodeIndices: [3, 6],
      seed: 401,
    ));

    results.add(service.processLevel(
      id: 'proto_c4_l02',
      chapterId: 4,
      levelNumber: 2,
      overallIndex: 92,
      title: 'Tứ Trận Cầu Nối',
      baseDifficulty: 3.5,
      rawGraph: TopologyGenerators.makeBridgedQuadCluster14(seed: 402),
      palette: p4,
      requiredDistinctColors: 4,
      lockedNodeIndices: [0, 1],
      seed: 402,
    ));

    // =========================================================================
    // CHAPTER 5 (Level 121, 122)
    // =========================================================================
    results.add(service.processLevel(
      id: 'proto_c5_l01',
      chapterId: 5,
      levelNumber: 1,
      overallIndex: 121,
      title: 'Lưới Đa Giác Dày Đặc',
      baseDifficulty: 4.0,
      rawGraph: TopologyGenerators.makeDenseTriangularMesh13(seed: 501),
      palette: p4,
      requiredDistinctColors: 4,
      restrictedNodeIndices: [6, 12], // 2 node ở lớp trong và tâm
      seed: 501,
    ));

    results.add(service.processLevel(
      id: 'proto_c5_l02',
      chapterId: 5,
      levelNumber: 2,
      overallIndex: 122,
      title: 'Mạng Ngũ Sắc Grötzsch',
      baseDifficulty: 4.3,
      rawGraph: TopologyGenerators.makeGrotzschExtension15(seed: 502),
      palette: p5,
      requiredDistinctColors: 5,
      restrictedNodeIndices: [7, 8, 14], // 2 node vành trong và tâm
      seed: 502,
    ));

    // =========================================================================
    // CHAPTER 6 (Level 151, 152)
    // =========================================================================
    results.add(service.processLevel(
      id: 'proto_c6_l01',
      chapterId: 6,
      levelNumber: 1,
      overallIndex: 151,
      title: 'Tam Cụm Hoàng Gia',
      baseDifficulty: 4.7,
      rawGraph: TopologyGenerators.makeMasterTriCluster16(seed: 601),
      palette: p5,
      requiredDistinctColors: 5,
      lockedNodeIndices: [4, 9], // Tâm của 2 cụm bánh xe/ngũ giác
      restrictedNodeIndices: [14, 15], // 2 node cầu nối trung tâm
      seed: 601,
    ));

    results.add(service.processLevel(
      id: 'proto_c6_l02',
      chapterId: 6,
      levelNumber: 2,
      overallIndex: 152,
      title: 'Mạng Nhện Đa Tầng Bất Quy Tắc',
      baseDifficulty: 5.0,
      rawGraph: TopologyGenerators.makeComplexIrregularWeb18(seed: 602),
      palette: p5,
      requiredDistinctColors: 5,
      lockedNodeIndices: [0, 8, 14], // 1 vành ngoài, 1 vành giữa, 1 lõi trong
      restrictedNodeIndices: [9, 11, 17], // 2 vành giữa, 1 lõi
      seed: 602,
    ));

    return results;
  }
}
