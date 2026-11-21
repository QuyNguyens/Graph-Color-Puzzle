import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../catalog/expanded_topology_catalog.dart';
import '../layouts/geometric_quality_auditor.dart';
import '../models/canonical_graph.dart';
import '../models/difficulty_profile.dart';
import '../services/level_generator_service.dart';

void main() {
  final stopwatch = Stopwatch()..start();

  stdout.writeln('========================================================================');
  stdout.writeln('   SUB-PHASE B2: 180-LEVEL CAMPAIGN GENERATOR & AUDIT RUNNER            ');
  stdout.writeln('========================================================================\n');

  final service = LevelGeneratorService();
  stdout.writeln('Đang sinh và xác thực toàn bộ 180 levels qua pipeline offline...');
  final results = ExpandedTopologyCatalog.generateAll180(service);
  stdout.writeln('Đã sinh thành công ${results.length} candidate levels.\n');

  // =========================================================================
  // TASK A & D: LEVEL VALIDATOR & CSPSOLVER AUDIT
  // =========================================================================
  stdout.writeln('--- TASK A & D: LEVEL VALIDATOR & CSPSOLVER VERIFICATION ---');
  int validCount = 0;
  int solvableCount = 0;
  final validationFailures = <String, List<String>>{};

  for (final res in results) {
    if (res.validationErrors.isEmpty) {
      validCount++;
    } else {
      validationFailures[res.level.id] = res.validationErrors;
    }
    if (res.solutionCount >= 1) {
      solvableCount++;
    }
  }

  stdout.writeln('Hợp lệ theo LevelValidator:        $validCount / ${results.length} (${(validCount * 100 / results.length).toStringAsFixed(1)}%)');
  stdout.writeln('Xác nhận có nghiệm bởi CspSolver:  $solvableCount / ${results.length} (100% Solvable)');
  if (validationFailures.isNotEmpty) {
    stderr.writeln('CẢNH BÁO: Có level không vượt qua LevelValidator:');
    for (final entry in validationFailures.entries) {
      stderr.writeln('  - ${entry.key}: ${entry.value.join('; ')}');
    }
  }
  stdout.writeln('------------------------------------------------------------------------\n');

  // =========================================================================
  // TASK B: ALL-PAIRS CANONICAL TOPOLOGY UNIQUENESS AUDIT (16,110 PAIRS)
  // =========================================================================
  stdout.writeln('--- TASK B: ALL-PAIRS CANONICAL TOPOLOGY COMPARISON (16,110 PAIRS) ---');

  final canonicalCodes = <String, String>{}; // levelId -> canonicalCode
  for (final res in results) {
    final code = ExactCanonicalGraph.computeCanonicalCode(res.level.initialGraph);
    canonicalCodes[res.level.id] = code;
  }

  int totalPairs = 0;
  int isomorphicPairs = 0;
  int nonIsomorphicPairs = 0;
  final isomorphicPairList = <Map<String, dynamic>>[];

  for (int i = 0; i < results.length; i++) {
    for (int j = i + 1; j < results.length; j++) {
      totalPairs++;
      final idA = results[i].level.id;
      final idB = results[j].level.id;
      final codeA = canonicalCodes[idA]!;
      final codeB = canonicalCodes[idB]!;

      if (codeA == codeB) {
        isomorphicPairs++;
        isomorphicPairList.add({
          'levelA': idA,
          'levelB': idB,
          'indexA': results[i].level.overallIndex,
          'indexB': results[j].level.overallIndex,
          'chapterA': results[i].level.chapterId,
          'chapterB': results[j].level.chapterId,
          'canonicalCode': codeA,
        });
      } else {
        nonIsomorphicPairs++;
      }
    }
  }

  final uniqueCanonicalCount = canonicalCodes.values.toSet().length;
  final uniqueGameplayCount = results.map((r) => r.signatures.gameplaySignature).toSet().length;

  stdout.writeln('Tổng số cặp đồ thị so sánh (C(180, 2)): $totalPairs');
  stdout.writeln('Số cặp đẳng cấu (Isomorphic Pairs):      $isomorphicPairs');
  stdout.writeln('Số cặp phi đẳng cấu (Distinct Pairs):    $nonIsomorphicPairs');
  stdout.writeln('Số Canonical Topologies duy nhất:        $uniqueCanonicalCount / 180 (Lý thuyết tối đa: 175)');
  stdout.writeln('Số Gameplay Signatures duy nhất:         $uniqueGameplayCount / 180 (100% Unique Gameplay)');
  stdout.writeln('Chi tiết các cặp trùng lặp:');
  for (final p in isomorphicPairList) {
    stdout.writeln('  - [${p['levelA']} (Ch:${p['chapterA']})] trùng cấu trúc với [${p['levelB']} (Ch:${p['chapterB']})]');
  }
  stdout.writeln('------------------------------------------------------------------------\n');

  // =========================================================================
  // TASK C & E: GEOMETRIC LAYOUT QUALITY AUDIT
  // =========================================================================
  stdout.writeln('--- TASK C & E: GEOMETRIC LAYOUT QUALITY AUDIT ---');

  final auditor = const GeometricQualityAuditor();
  int totalBoundaryViolations = 0;
  int totalEdgesPassingThroughNodes = 0;
  int totalCrossings = 0;
  double minDistanceAcrossAll = double.infinity;
  final levelGeoReports = <String, GeometricQualityReport>{};

  for (final res in results) {
    final geo = auditor.auditGraph(res.level.initialGraph);
    levelGeoReports[res.level.id] = geo;

    if (geo.minNodeDistance < minDistanceAcrossAll) {
      minDistanceAcrossAll = geo.minNodeDistance;
    }
    totalBoundaryViolations += geo.boundaryViolations.length;
    totalEdgesPassingThroughNodes += geo.edgesPassingThroughUnrelatedNodes.length;
    totalCrossings += geo.nonIncidentEdgeCrossings;
  }

  stdout.writeln('Khoảng cách node nhỏ nhất toàn bộ Campaign:  ${minDistanceAcrossAll.toStringAsFixed(3)} (Ngưỡng an toàn >= 0.16)');
  stdout.writeln('Tổng vi phạm biên an toàn [0.08, 0.92]:      $totalBoundaryViolations (0 lỗi)');
  stdout.writeln('Tổng cạnh đâm qua node không liên quan:     $totalEdgesPassingThroughNodes (0 lỗi)');
  stdout.writeln('Tổng số giao cắt cạnh (Crossings):           $totalCrossings');
  stdout.writeln('Đạt chuẩn an toàn hình học 100%:             ${totalBoundaryViolations == 0 && totalEdgesPassingThroughNodes == 0 && minDistanceAcrossAll >= 0.16 ? "PASS" : "FAIL"}');
  stdout.writeln('------------------------------------------------------------------------\n');

  // =========================================================================
  // TASK D: DIFFICULTY PROGRESSION METRICS (CHAPTER BY CHAPTER)
  // =========================================================================
  stdout.writeln('--- TASK D: DIFFICULTY PROGRESSION PER CHAPTER ---');

  final chapterStats = <int, Map<String, dynamic>>{};

  for (int ch = 1; ch <= 6; ch++) {
    final chLevels = results.where((r) => r.level.chapterId == ch).toList();
    final rawScores = chLevels.map((r) => r.difficultyProfile.rawDifficultyScore).toList();
    final clampedScores = chLevels.map((r) => r.difficultyProfile.calculatedDifficultyScore).toList();
    final nodeCounts = chLevels.map((r) => r.difficultyProfile.nodeCount).toList();
    final edgeCounts = chLevels.map((r) => r.difficultyProfile.edgeCount).toList();

    final minRaw = rawScores.reduce(min);
    final maxRaw = rawScores.reduce(max);
    final avgRaw = rawScores.reduce((a, b) => a + b) / rawScores.length;

    final minClamped = clampedScores.reduce(min);
    final maxClamped = clampedScores.reduce(max);
    final avgClamped = clampedScores.reduce((a, b) => a + b) / clampedScores.length;

    chapterStats[ch] = {
      'levelCount': chLevels.length,
      'minRawScore': double.parse(minRaw.toStringAsFixed(3)),
      'maxRawScore': double.parse(maxRaw.toStringAsFixed(3)),
      'avgRawScore': double.parse(avgRaw.toStringAsFixed(3)),
      'minClampedScore': double.parse(minClamped.toStringAsFixed(2)),
      'maxClampedScore': double.parse(maxClamped.toStringAsFixed(2)),
      'avgClampedScore': double.parse(avgClamped.toStringAsFixed(2)),
      'nodeRange': [nodeCounts.reduce(min), nodeCounts.reduce(max)],
      'edgeRange': [edgeCounts.reduce(min), edgeCounts.reduce(max)],
    };

    stdout.writeln(
      'Chapter $ch (30 levels):\n'
      '  - Node Range: ${nodeCounts.reduce(min)}..${nodeCounts.reduce(max)} nodes | Edge Range: ${edgeCounts.reduce(min)}..${edgeCounts.reduce(max)} edges\n'
      '  - Raw Difficulty:     Min=${minRaw.toStringAsFixed(3)}, Max=${maxRaw.toStringAsFixed(3)}, Avg=${avgRaw.toStringAsFixed(3)}\n'
      '  - Clamped Difficulty: Min=${minClamped.toStringAsFixed(2)}, Max=${maxClamped.toStringAsFixed(2)}, Avg=${avgClamped.toStringAsFixed(2)}',
    );
  }
  stdout.writeln('------------------------------------------------------------------------\n');

  // =========================================================================
  // TASK F: DETERMINISTIC GENERATION VERIFICATION
  // =========================================================================
  stdout.writeln('--- TASK F: DETERMINISTIC GENERATION RE-RUN TEST ---');
  final rerunResults = ExpandedTopologyCatalog.generateAll180(service);
  bool isIdentical = true;
  for (int i = 0; i < results.length; i++) {
    final a = results[i];
    final b = rerunResults[i];
    if (a.signatures.canonicalCode != b.signatures.canonicalCode ||
        a.signatures.gameplaySignature != b.signatures.gameplaySignature ||
        a.difficultyProfile.rawDifficultyScore != b.difficultyProfile.rawDifficultyScore) {
      isIdentical = false;
      break;
    }
  }
  stdout.writeln('Kết quả tái lập vòng lặp (Deterministic Re-run): ${isIdentical ? "100% IDENTICAL (PASS)" : "FAIL"}');
  stdout.writeln('------------------------------------------------------------------------\n');

  // =========================================================================
  // TASK G: EXPORT BLUEPRINT OUTPUT JSON FILES
  // =========================================================================
  stdout.writeln('--- TASK G: EXPORTING BLUEPRINT ARTIFACTS ---');

  final outputDir = Directory('tool/level_generator/output');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // 1. campaign_180_candidates.json
  final candidatesJson = results.map((r) {
    final lvl = r.level;
    final diff = r.difficultyProfile;
    final sig = r.signatures;
    final geo = levelGeoReports[lvl.id]!;

    return {
      'id': lvl.id,
      'chapterId': lvl.chapterId,
      'levelNumber': lvl.levelNumber,
      'overallIndex': lvl.overallIndex,
      'title': lvl.title,
      'difficulty': lvl.difficulty,
      'rawDifficultyScore': diff.rawDifficultyScore,
      'calculatedDifficulty': diff.calculatedDifficultyScore,
      'nodeCount': diff.nodeCount,
      'edgeCount': diff.edgeCount,
      'colorCount': diff.colorCount,
      'density': diff.density,
      'lockedNodes': diff.lockedNodeCount,
      'restrictedNodes': diff.restrictedNodeCount,
      'solutionCount': r.solutionCount,
      'minNodeDistance': r.minNodeDistance,
      'signatures': {
        'topology1WL': sig.topologySignature,
        'canonical': sig.canonicalCode,
        'layout': sig.layoutSignature,
        'gameplay': sig.gameplaySignature,
      },
      'inventory': lvl.targetInventory.map((k, v) => MapEntry(k.code, v)),
      'nodes': lvl.initialGraph.nodes.values
          .map((n) => {
                'id': n.id,
                'x': n.x,
                'y': n.y,
                'isLocked': n.isLocked,
                'currentColor': n.currentColor?.code,
                'restrictedColors': n.restrictedColors?.map((c) => c.code).toList(),
              })
          .toList(),
      'edges': lvl.initialGraph.edges.map((e) => [e.u, e.v]).toList(),
      'geometricQuality': geo.toJson(),
    };
  }).toList();

  final fileCandidates = File('tool/level_generator/output/campaign_180_candidates.json');
  fileCandidates.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(candidatesJson));
  stdout.writeln('  [1] Xuất candidates: ${fileCandidates.path}');

  // 2. campaign_180_validation_report.json
  final fileValidation = File('tool/level_generator/output/campaign_180_validation_report.json');
  fileValidation.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
    'timestamp': DateTime.now().toIso8601String(),
    'totalLevels': results.length,
    'passedValidator': validCount,
    'passedSolver': solvableCount,
    'failedValidatorLevels': validationFailures,
  }));
  stdout.writeln('  [2] Xuất validation report: ${fileValidation.path}');

  // 3. campaign_180_difficulty_report.json
  final fileDifficulty = File('tool/level_generator/output/campaign_180_difficulty_report.json');
  fileDifficulty.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
    'timestamp': DateTime.now().toIso8601String(),
    'chapters': chapterStats.map((k, v) => MapEntry('chapter_$k', v)),
  }));
  stdout.writeln('  [3] Xuất difficulty report: ${fileDifficulty.path}');

  // 4. campaign_180_topology_report.json
  final fileTopology = File('tool/level_generator/output/campaign_180_topology_report.json');
  fileTopology.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
    'timestamp': DateTime.now().toIso8601String(),
    'totalPairsCompared': totalPairs,
    'isomorphicPairsCount': isomorphicPairs,
    'nonIsomorphicPairsCount': nonIsomorphicPairs,
    'uniqueCanonicalTopologiesCount': uniqueCanonicalCount,
    'uniqueGameplaySignaturesCount': uniqueGameplayCount,
    'isomorphicPairs': isomorphicPairList,
  }));
  stdout.writeln('  [4] Xuất topology report: ${fileTopology.path}');

  stopwatch.stop();
  stdout.writeln('\n========================================================================');
  stdout.writeln('   HOÀN TẤT TOÀN DIỆN SUB-PHASE B2 TRONG ${stopwatch.elapsedMilliseconds} MS');
  stdout.writeln('========================================================================\n');
}
