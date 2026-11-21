import 'dart:math';
import 'package:graph_coloring/features/campaign/domain/entities/puzzle_level.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/graph.dart';

/// Hồ sơ độ khó định lượng (Difficulty Profile) của một level puzzle.
class DifficultyProfile {
  const DifficultyProfile({
    required this.nodeCount,
    required this.edgeCount,
    required this.density,
    required this.maxDegree,
    required this.avgDegree,
    required this.degreeVariance,
    required this.colorCount,
    required this.lockedNodeCount,
    required this.restrictedNodeCount,
    required this.solverSearchSteps,
    required this.backtrackCount,
    required this.rawDifficultyScore,
    required this.calculatedDifficultyScore,
    required this.isClamped,
  });

  final int nodeCount;
  final int edgeCount;
  final double density;
  final int maxDegree;
  final double avgDegree;
  final double degreeVariance;
  final int colorCount;
  final int lockedNodeCount;
  final int restrictedNodeCount;
  final int solverSearchSteps;
  final int backtrackCount;
  final double rawDifficultyScore;
  final double calculatedDifficultyScore;
  final bool isClamped;

  /// Đánh giá độ khó từ PuzzleLevel kết hợp thông số Solver instrumentation
  factory DifficultyProfile.evaluate({
    required PuzzleLevel level,
    int solverSearchSteps = 1,
    int backtrackCount = 0,
  }) {
    final graph = level.initialGraph;
    final v = graph.nodes.length;
    final e = graph.edges.length;

    final maxPossibleEdges = v > 1 ? (v * (v - 1)) / 2 : 1;
    final density = e / maxPossibleEdges;

    final degrees = <int>[];
    for (final node in graph.nodes.values) {
      degrees.add(graph.getNeighbors(node.id).length);
    }

    final maxDeg = degrees.isEmpty ? 0 : degrees.reduce(max);
    final avgDeg = v > 0 ? (2.0 * e) / v : 0.0;

    double variance = 0.0;
    if (v > 0) {
      for (final d in degrees) {
        variance += (d - avgDeg) * (d - avgDeg);
      }
      variance /= v;
    }

    int lockedCount = 0;
    int restrictedCount = 0;
    for (final node in graph.nodes.values) {
      if (node.isLocked) lockedCount++;
      if (node.restrictedColors != null && node.restrictedColors!.isNotEmpty) {
        restrictedCount++;
      }
    }

    final colorCount = level.targetInventory.keys.length;

    // Tính điểm độ khó tổng hợp (Composite Difficulty Score)
    // Tỉ lệ tiến trình qua 6 chapters:
    final chapterBase = 1.0 + (level.chapterId - 1) * 0.65;
    final nodeFactor = (v - 4) * 0.04;
    final densityFactor = density * 0.25;
    final constraintFactor = (lockedCount * 0.08) + (restrictedCount * 0.10);
    final solverFactor = min(0.3, (solverSearchSteps + backtrackCount * 2) * 0.01);

    final rawScore = chapterBase + nodeFactor + densityFactor + constraintFactor + solverFactor;
    final clampedScore = rawScore.clamp(1.0, 5.0);
    final isClamped = rawScore > 5.0 || rawScore < 1.0;

    return DifficultyProfile(
      nodeCount: v,
      edgeCount: e,
      density: double.parse(density.toStringAsFixed(3)),
      maxDegree: maxDeg,
      avgDegree: double.parse(avgDeg.toStringAsFixed(2)),
      degreeVariance: double.parse(variance.toStringAsFixed(3)),
      colorCount: colorCount,
      lockedNodeCount: lockedCount,
      restrictedNodeCount: restrictedCount,
      solverSearchSteps: solverSearchSteps,
      backtrackCount: backtrackCount,
      rawDifficultyScore: double.parse(rawScore.toStringAsFixed(3)),
      calculatedDifficultyScore: double.parse(clampedScore.toStringAsFixed(2)),
      isClamped: isClamped,
    );
  }

  Map<String, dynamic> toJson() => {
        'nodeCount': nodeCount,
        'edgeCount': edgeCount,
        'density': density,
        'maxDegree': maxDegree,
        'avgDegree': avgDegree,
        'degreeVariance': degreeVariance,
        'colorCount': colorCount,
        'lockedNodeCount': lockedNodeCount,
        'restrictedNodeCount': restrictedNodeCount,
        'solverSearchSteps': solverSearchSteps,
        'backtrackCount': backtrackCount,
        'rawDifficultyScore': rawDifficultyScore,
        'calculatedDifficultyScore': calculatedDifficultyScore,
        'isClamped': isClamped,
      };

  @override
  String toString() =>
      'DifficultyProfile(V=$nodeCount, E=$edgeCount, RawScore=$rawDifficultyScore, ClampedScore=$calculatedDifficultyScore, Clamped=$isClamped)';
}
