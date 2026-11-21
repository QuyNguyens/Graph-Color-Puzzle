import 'dart:math';
import 'package:graph_coloring/features/graph_coloring/domain/entities/graph.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/graph_edge.dart';
import 'package:graph_coloring/features/graph_coloring/domain/entities/graph_node.dart';

/// Kết quả kiểm định chất lượng hình học và thẩm mỹ của bố cục đồ thị.
class GeometricQualityReport {
  const GeometricQualityReport({
    required this.minNodeDistance,
    required this.boundaryViolations,
    required this.nonIncidentEdgeCrossings,
    required this.edgesPassingThroughUnrelatedNodes,
    required this.boundingBoxWidth,
    required this.boundingBoxHeight,
    required this.boundingBoxAreaUtilization,
    required this.centerOfMassOffset,
    required this.isCleanAndSafe,
  });

  final double minNodeDistance;
  final List<String> boundaryViolations;
  final int nonIncidentEdgeCrossings;
  final List<String> edgesPassingThroughUnrelatedNodes;
  final double boundingBoxWidth;
  final double boundingBoxHeight;
  final double boundingBoxAreaUtilization;
  final double centerOfMassOffset;
  final bool isCleanAndSafe;

  Map<String, dynamic> toJson() => {
        'minNodeDistance': minNodeDistance,
        'boundaryViolations': boundaryViolations,
        'nonIncidentEdgeCrossings': nonIncidentEdgeCrossings,
        'edgesPassingThroughUnrelatedNodes': edgesPassingThroughUnrelatedNodes,
        'boundingBoxWidth': boundingBoxWidth,
        'boundingBoxHeight': boundingBoxHeight,
        'boundingBoxAreaUtilization': boundingBoxAreaUtilization,
        'centerOfMassOffset': centerOfMassOffset,
        'isCleanAndSafe': isCleanAndSafe,
      };

  @override
  String toString() =>
      'GeoReport(MinDist=$minNodeDistance, BoundsViolations=${boundaryViolations.length}, Crossings=$nonIncidentEdgeCrossings, EdgesThroughNodes=${edgesPassingThroughUnrelatedNodes.length}, Util=${(boundingBoxAreaUtilization * 100).toStringAsFixed(1)}%, BalanceOffset=$centerOfMassOffset)';
}

/// Bộ kiểm định chất lượng hình học đồ thị (Geometric Quality Auditor).
class GeometricQualityAuditor {
  const GeometricQualityAuditor({
    this.safeMinMargin = 0.08,
    this.safeMaxMargin = 0.92,
    this.minAllowedNodeDist = 0.16,
    this.nodeSafeRadius = 0.045, // Bán kính vùng cấm của node để không bị cạnh đâm qua
  });

  final double safeMinMargin;
  final double safeMaxMargin;
  final double minAllowedNodeDist;
  final double nodeSafeRadius;

  GeometricQualityReport auditGraph(Graph graph) {
    final nodes = graph.nodes.values.toList();
    final edges = graph.edges.toList();
    final n = nodes.length;

    // 1. Khoảng cách tối thiểu giữa các node
    double minDist = double.infinity;
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final dx = nodes[i].x - nodes[j].x;
        final dy = nodes[i].y - nodes[j].y;
        final d = sqrt(dx * dx + dy * dy);
        if (d < minDist) minDist = d;
      }
    }
    if (minDist == double.infinity) minDist = 1.0;

    // 2. Vi phạm biên an toàn
    final boundaryViolations = <String>[];
    for (final node in nodes) {
      if (node.x < safeMinMargin ||
          node.x > safeMaxMargin ||
          node.y < safeMinMargin ||
          node.y > safeMaxMargin) {
        boundaryViolations.add(
          'Node ${node.id} (${node.x}, ${node.y}) nằm ngoài biên an toàn [$safeMinMargin, $safeMaxMargin]',
        );
      }
    }

    // 3. Số giao cắt cạnh không chung đỉnh (Non-incident edge crossings)
    int crossings = 0;
    for (int i = 0; i < edges.length; i++) {
      for (int j = i + 1; j < edges.length; j++) {
        final e1 = edges[i];
        final e2 = edges[j];
        // Bỏ qua các cặp cạnh kề nhau (chung 1 đỉnh)
        if (e1.u == e2.u || e1.u == e2.v || e1.v == e2.u || e1.v == e2.v) {
          continue;
        }
        final p1 = graph.getNode(e1.u)!;
        final p2 = graph.getNode(e1.v)!;
        final p3 = graph.getNode(e2.u)!;
        final p4 = graph.getNode(e2.v)!;

        if (_segmentsIntersect(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y)) {
          crossings++;
        }
      }
    }

    // 4. Cạnh đâm xuyên qua node không liên quan (Edge passing through unrelated node)
    final edgesThroughNodes = <String>[];
    for (final edge in edges) {
      final p1 = graph.getNode(edge.u)!;
      final p2 = graph.getNode(edge.v)!;

      for (final node in nodes) {
        if (node.id == edge.u || node.id == edge.v) continue;
        final distToSegment = _distancePointToSegment(
          node.x,
          node.y,
          p1.x,
          p1.y,
          p2.x,
          p2.y,
        );
        if (distToSegment < nodeSafeRadius) {
          edgesThroughNodes.add(
            'Cạnh (${edge.u}, ${edge.v}) đâm xuyên qua node ${node.id} (khoảng cách: ${distToSegment.toStringAsFixed(3)} < $nodeSafeRadius)',
          );
        }
      }
    }

    // 5. Bounding box utilization
    double minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
    double sumX = 0.0, sumY = 0.0;
    for (final node in nodes) {
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.y > maxY) maxY = node.y;
      sumX += node.x;
      sumY += node.y;
    }
    final bbWidth = double.parse((maxX - minX).toStringAsFixed(3));
    final bbHeight = double.parse((maxY - minY).toStringAsFixed(3));
    final safeSpan = safeMaxMargin - safeMinMargin;
    final maxAvailableArea = safeSpan * safeSpan;
    final actualArea = bbWidth * bbHeight;
    final areaUtil = double.parse((actualArea / maxAvailableArea).toStringAsFixed(3));

    // 6. Visual Balance (Tâm khối lượng so với 0.5, 0.5)
    final comX = n > 0 ? sumX / n : 0.5;
    final comY = n > 0 ? sumY / n : 0.5;
    final comDist = sqrt((comX - 0.5) * (comX - 0.5) + (comY - 0.5) * (comY - 0.5));
    final balanceOffset = double.parse(comDist.toStringAsFixed(3));

    final isClean = boundaryViolations.isEmpty &&
        edgesThroughNodes.isEmpty &&
        minDist >= minAllowedNodeDist;

    return GeometricQualityReport(
      minNodeDistance: double.parse(minDist.toStringAsFixed(3)),
      boundaryViolations: boundaryViolations,
      nonIncidentEdgeCrossings: crossings,
      edgesPassingThroughUnrelatedNodes: edgesThroughNodes,
      boundingBoxWidth: bbWidth,
      boundingBoxHeight: bbHeight,
      boundingBoxAreaUtilization: areaUtil,
      centerOfMassOffset: balanceOffset,
      isCleanAndSafe: isClean,
    );
  }

  /// Tính khoảng cách vuông góc từ điểm P(px, py) đến đoạn thẳng AB(ax, ay)-(bx, by)
  static double _distancePointToSegment(
    double px,
    double py,
    double ax,
    double ay,
    double bx,
    double by,
  ) {
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0.0) {
      return sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay));
    }
    // Tham số t hình chiếu
    final t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / lengthSquared));
    final projX = ax + t * dx;
    final projY = ay + t * dy;
    return sqrt((px - projX) * (px - projX) + (py - projY) * (py - projY));
  }

  /// Kiểm tra 2 đoạn thẳng AB và CD có cắt nhau trong lòng đoạn thẳng không
  static bool _segmentsIntersect(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
    double dx,
    double dy,
  ) {
    double ccw(double x1, double y1, double x2, double y2, double x3, double y3) {
      return (y3 - y1) * (x2 - x1) - (y2 - y1) * (x3 - x1);
    }

    final d1 = ccw(ax, ay, bx, by, cx, cy);
    final d2 = ccw(ax, ay, bx, by, dx, dy);
    final d3 = ccw(cx, cy, dx, dy, ax, ay);
    final d4 = ccw(cx, cy, dx, dy, bx, by);

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }
    return false;
  }
}
