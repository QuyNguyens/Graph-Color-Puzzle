import 'dart:convert';
import 'dart:io';

import 'package:graph_coloring/features/graph_coloring/domain/entities/puzzle_color.dart';
import '../models/raw_graph_data.dart';
import '../services/level_generator_service.dart';

/// Danh mục đồ thị mở rộng 180 levels (30 levels x 6 Chapters).
class ExpandedTopologyCatalog {
  static const Map<String, PuzzleColor> _colorMap = {
    'RED': PuzzleColor.red,
    'BLUE': PuzzleColor.blue,
    'YELLOW': PuzzleColor.yellow,
    'GREEN': PuzzleColor.green,
    'PURPLE': PuzzleColor.purple,
  };

  /// Tải toàn bộ 180 level specifications và sinh ra các GeneratedLevelResult qua pipeline
  static List<GeneratedLevelResult> generateAll180(
    LevelGeneratorService service, {
    String specsPath = 'tool/level_generator/data/campaign_180_specs.json',
  }) {
    final file = File(specsPath);
    if (!file.existsSync()) {
      throw StateError('Không tìm thấy file blueprint cấu hình: $specsPath');
    }

    final jsonContent = file.readAsStringSync();
    final List<dynamic> rawList = jsonDecode(jsonContent);

    final results = <GeneratedLevelResult>[];

    for (final dynamic item in rawList) {
      final map = item as Map<String, dynamic>;

      final id = map['id'] as String;
      final chapterId = map['chapterId'] as int;
      final levelNumber = map['levelNumber'] as int;
      final overallIndex = map['overallIndex'] as int;
      final title = map['title'] as String;
      final nodeCount = map['nodeCount'] as int;

      // Đọc danh sách nodes
      final rawNodesJson = map['nodes'] as List<dynamic>;
      final rawNodes = <RawNodeData>[];
      for (int i = 0; i < rawNodesJson.length; i++) {
        final pair = rawNodesJson[i] as List<dynamic>;
        final x = (pair[0] as num).toDouble();
        final y = (pair[1] as num).toDouble();
        rawNodes.add(RawNodeData('n${i + 1}', x, y));
      }

      // Đọc danh sách edges
      final rawEdgesJson = map['edges'] as List<dynamic>;
      final rawEdges = <RawEdgePair>{};
      for (final dynamic edgeItem in rawEdgesJson) {
        final edgePair = edgeItem as List<dynamic>;
        final u = edgePair[0] as int;
        final v = edgePair[1] as int;
        rawEdges.add(RawEdgePair(u, v));
      }

      final rawGraph = RawGraphData(
        nodes: rawNodes,
        edges: rawEdges,
        family: 'campaign_ch${chapterId}',
      );

      // Bảng màu
      final paletteCodes = (map['palette'] as List<dynamic>).cast<String>();
      final palette = paletteCodes.map((code) => _colorMap[code]!).toList();
      final reqColors = map['requiredColors'] as int;

      // Ràng buộc
      final locked = (map['lockedNodeIndices'] as List<dynamic>?)?.cast<int>();
      final restricted = (map['restrictedNodeIndices'] as List<dynamic>?)?.cast<int>();

      // Base difficulty theo Chapter và level number
      final baseDiff = 1.0 + (chapterId - 1) * 0.7 + (levelNumber - 1) * (0.6 / 29);

      final result = service.processLevel(
        id: id,
        chapterId: chapterId,
        levelNumber: levelNumber,
        overallIndex: overallIndex,
        title: title,
        baseDifficulty: double.parse(baseDiff.toStringAsFixed(2)),
        rawGraph: rawGraph,
        palette: palette,
        requiredDistinctColors: reqColors,
        lockedNodeIndices: locked,
        restrictedNodeIndices: restricted,
        seed: 1000 + overallIndex,
      );

      results.add(result);
    }

    return results;
  }
}
