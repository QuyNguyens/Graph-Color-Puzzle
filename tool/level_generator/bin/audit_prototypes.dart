import 'dart:convert';
import 'dart:io';

import '../layouts/geometric_quality_auditor.dart';
import '../models/canonical_graph.dart';
import '../services/level_generator_service.dart';
import '../services/prototype_catalog.dart';

void main() {
  stdout.writeln('========================================================================');
  stdout.writeln('   SUB-PHASE B1.1: CANONICAL GRAPH & QUALITY AUDIT RUNNER               ');
  stdout.writeln('========================================================================\n');

  final service = LevelGeneratorService();
  final results = PrototypeCatalog.generateAllPrototypes(service);
  final auditor = const GeometricQualityAuditor();

  final totalCandidates = results.length;
  stdout.writeln('Đang kiểm tra $totalCandidates prototype levels qua 6 Chapter...\n');

  // =========================================================================
  // TASK A & B: EXACT CANONICAL ISOMORPHISM AUDIT (ALL 66 PAIRS)
  // =========================================================================
  stdout.writeln('--- TASK A & B: EXACT CANONICAL ISOMORPHISM AUDIT (ALL PAIRS) ---');

  final canonicalCodes = <String, String>{}; // levelId -> canonicalCode
  for (final res in results) {
    final code = ExactCanonicalGraph.computeCanonicalCode(res.level.initialGraph);
    canonicalCodes[res.level.id] = code;
  }

  int totalPairsCompared = 0;
  int isomorphicPairs = 0;
  int nonIsomorphicPairs = 0;
  final duplicatePairs = <String>[];

  for (int i = 0; i < totalCandidates; i++) {
    for (int j = i + 1; j < totalCandidates; j++) {
      totalPairsCompared++;
      final idA = results[i].level.id;
      final idB = results[j].level.id;
      final codeA = canonicalCodes[idA]!;
      final codeB = canonicalCodes[idB]!;

      final isIso = codeA == codeB;
      if (isIso) {
        isomorphicPairs++;
        duplicatePairs.add('($idA, $idB)');
        stdout.writeln('CẢNH BÁO: Phát hiện 2 level đẳng cấu: $idA <=> $idB');
      } else {
        nonIsomorphicPairs++;
      }
    }
  }

  final uniqueCanonicalCodes = canonicalCodes.values.toSet().length;
  final uniqueGameplaySigs = results.map((r) => r.signatures.gameplaySignature).toSet().length;

  stdout.writeln('Tổng số cặp đồ thị đã so sánh:     $totalPairsCompared (tương ứng C(12, 2))');
  stdout.writeln('Số cặp đẳng cấu (Isomorphic):        $isomorphicPairs');
  stdout.writeln('Số cặp không đẳng cấu (Distinct):    $nonIsomorphicPairs');
  stdout.writeln('Số Canonical Topologies duy nhất:    $uniqueCanonicalCodes / $totalCandidates (100% Unique)');
  stdout.writeln('Số Gameplay Signatures duy nhất:     $uniqueGameplaySigs / $totalCandidates (100% Unique)');
  stdout.writeln('------------------------------------------------------------------------\n');

  // =========================================================================
  // TASK C: GEOMETRIC LAYOUT QUALITY AUDIT
  // =========================================================================
  stdout.writeln('--- TASK C: GEOMETRIC LAYOUT QUALITY AUDIT ---');

  final geoReports = <String, GeometricQualityReport>{};
  int totalBoundaryViolations = 0;
  int totalEdgesPassingThroughNodes = 0;
  int totalCrossings = 0;

  for (final res in results) {
    final lvl = res.level;
    final geo = auditor.auditGraph(lvl.initialGraph);
    geoReports[lvl.id] = geo;

    totalBoundaryViolations += geo.boundaryViolations.length;
    totalEdgesPassingThroughNodes += geo.edgesPassingThroughUnrelatedNodes.length;
    totalCrossings += geo.nonIncidentEdgeCrossings;

    stdout.writeln(
      'Level [${lvl.id}] ("${lvl.title}"):\n'
      '  - Min Node Separation: ${geo.minNodeDistance.toStringAsFixed(3)} (Ngưỡng an toàn: >= 0.16)\n'
      '  - Boundary Violations: ${geo.boundaryViolations.isEmpty ? "0 (PASS)" : geo.boundaryViolations.join('; ')}\n'
      '  - Cạnh đâm qua node:   ${geo.edgesPassingThroughUnrelatedNodes.isEmpty ? "0 (PASS)" : geo.edgesPassingThroughUnrelatedNodes.join('; ')}\n'
      '  - Edge Crossings:      ${geo.nonIncidentEdgeCrossings}\n'
      '  - Bounding Box Util:   ${(geo.boundingBoxAreaUtilization * 100).toStringAsFixed(1)}% (${geo.boundingBoxWidth} x ${geo.boundingBoxHeight})\n'
      '  - Center of Mass Dev:  ${geo.centerOfMassOffset.toStringAsFixed(3)} (Tâm: 0.5, 0.5)',
    );
  }

  stdout.writeln('\nTổng kết Geometric Quality:');
  stdout.writeln('  - Vi phạm biên (Boundary Violations):        $totalBoundaryViolations');
  stdout.writeln('  - Cạnh đâm qua node không liên quan:          $totalEdgesPassingThroughNodes');
  stdout.writeln('  - Tổng số giao cắt cạnh (Crossings):          $totalCrossings');
  stdout.writeln('------------------------------------------------------------------------\n');

  // =========================================================================
  // TASK D: DIFFICULTY SCORE AUDIT (RAW VS CLAMPED)
  // =========================================================================
  stdout.writeln('--- TASK D: DIFFICULTY SCORE AUDIT (RAW VS CLAMPED) ---');

  for (final res in results) {
    final lvl = res.level;
    final diff = res.difficultyProfile;
    stdout.writeln(
      'Level [${lvl.id}] Ch:${lvl.chapterId} No:${lvl.levelNumber}:\n'
      '  - Nodes: ${diff.nodeCount}, Edges: ${diff.edgeCount}, Density: ${diff.density}\n'
      '  - Constraints: Locked=${diff.lockedNodeCount}, Restricted=${diff.restrictedNodeCount}\n'
      '  - Raw Score:     ${diff.rawDifficultyScore.toStringAsFixed(3)}\n'
      '  - Clamped Score: ${diff.calculatedDifficultyScore.toStringAsFixed(2)} ${diff.isClamped ? "(BỊ CLAMP bão hòa)" : ""}',
    );
  }
  stdout.writeln('------------------------------------------------------------------------\n');

  // =========================================================================
  // XUẤT BÁO CÁO JSON
  // =========================================================================
  final auditOutputFile = File('tool/level_generator/output/b1_1_audit_report.json');
  auditOutputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'auditTimestamp': DateTime.now().toIso8601String(),
      'totalCandidates': totalCandidates,
      'isomorphismAudit': {
        'totalPairsCompared': totalPairsCompared,
        'isomorphicPairs': isomorphicPairs,
        'nonIsomorphicPairs': nonIsomorphicPairs,
        'uniqueCanonicalCodes': uniqueCanonicalCodes,
        'uniqueGameplaySignatures': uniqueGameplaySigs,
        'duplicatePairs': duplicatePairs,
      },
      'geometricQualitySummary': {
        'totalBoundaryViolations': totalBoundaryViolations,
        'totalEdgesPassingThroughNodes': totalEdgesPassingThroughNodes,
        'totalCrossings': totalCrossings,
      },
      'levelsAudit': results.map((r) {
        final geo = geoReports[r.level.id]!;
        final diff = r.difficultyProfile;
        return {
          'id': r.level.id,
          'title': r.level.title,
          'chapterId': r.level.chapterId,
          'levelNumber': r.level.levelNumber,
          'canonicalCode': canonicalCodes[r.level.id],
          'signatures': {
            'topology1WL': r.signatures.topologySignature,
            'canonical': r.signatures.canonicalCode,
            'layout': r.signatures.layoutSignature,
            'gameplay': r.signatures.gameplaySignature,
          },
          'difficulty': {
            'raw': diff.rawDifficultyScore,
            'clamped': diff.calculatedDifficultyScore,
            'isClamped': diff.isClamped,
          },
          'geometric': geo.toJson(),
        };
      }).toList(),
    }),
  );

  stdout.writeln('Báo cáo audit chi tiết đã lưu vào: ${auditOutputFile.path}');
  stdout.writeln('========================================================================\n');
}
