import 'dart:math';
import '../models/raw_graph_data.dart';

/// Bộ công cụ tối ưu hóa và chuẩn hóa bố cục hình học đồ thị.
class LayoutEngine {
  const LayoutEngine({
    this.minSeparation = 0.165,
    this.minMargin = 0.08,
    this.maxMargin = 0.92,
    this.edgeNodeClearance = 0.055,
  });

  final double minSeparation;
  final double minMargin;
  final double maxMargin;
  final double edgeNodeClearance;

  static double _r3(double v) => double.parse(v.toStringAsFixed(3));

  /// Chuẩn hóa, căn giữa và giải phóng xung đột va chạm của đồ thị.
  RawGraphData optimizeLayout(RawGraphData raw) {
    final nodes = raw.nodes.map((n) => n.copyWith()).toList();
    final n = nodes.length;
    if (n <= 1) return raw;

    // 1. Căn giữa ban đầu
    _centerAndScale(nodes);

    // 2. Chạy Spring-Repulsion Force Relaxation (Node-to-Node và Edge-to-Node)
    for (int iter = 0; iter < 120; iter++) {
      bool hasCollision = false;

      // A. Lực đẩy giữa mọi cặp node (Node-to-Node Repulsion)
      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          final dx = nodes[i].x - nodes[j].x;
          final dy = nodes[i].y - nodes[j].y;
          final dist = sqrt(dx * dx + dy * dy);

          if (dist < minSeparation) {
            hasCollision = true;
            final overlap = (minSeparation - dist) * 0.5;
            final nx = dist > 0.001 ? (dx / dist) : 1.0;
            final ny = dist > 0.001 ? (dy / dist) : 0.0;

            nodes[i].x += nx * overlap;
            nodes[i].y += ny * overlap;
            nodes[j].x -= nx * overlap;
            nodes[j].y -= ny * overlap;
          }
        }
      }

      // B. Lực đẩy ngăn cạnh đâm xuyên qua node không liên quan (Edge-to-Node Clearance)
      for (final edge in raw.edges) {
        final a = nodes[edge.uIndex];
        final b = nodes[edge.vIndex];
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final l2 = dx * dx + dy * dy;
        if (l2 < 0.0001) continue;

        for (int k = 0; k < n; k++) {
          if (k == edge.uIndex || k == edge.vIndex) continue;
          final p = nodes[k];

          // Hình chiếu vô hướng t trên đoạn AB
          final t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / l2;
          if (t >= 0.05 && t <= 0.95) {
            final projX = a.x + t * dx;
            final projY = a.y + t * dy;
            final dist = sqrt((p.x - projX) * (p.x - projX) + (p.y - projY) * (p.y - projY));

            if (dist < edgeNodeClearance) {
              hasCollision = true;
              final push = (edgeNodeClearance - dist) * 0.5;
              final perpX = dist > 0.001 ? (p.x - projX) / dist : -dy / sqrt(l2);
              final perpY = dist > 0.001 ? (p.y - projY) / dist : dx / sqrt(l2);

              p.x += perpX * push;
              p.y += perpY * push;
              a.x -= perpX * push * 0.2;
              a.y -= perpY * push * 0.2;
              b.x -= perpX * push * 0.2;
              b.y -= perpY * push * 0.2;
            }
          }
        }
      }

      // Giới hạn biên an toàn
      for (final node in nodes) {
        node.x = node.x.clamp(minMargin, maxMargin);
        node.y = node.y.clamp(minMargin, maxMargin);
      }

      if (!hasCollision) break;
    }

    // 3. Căn giữa lần cuối
    _centerAndScale(nodes);

    // 4. Làm tròn 3 chữ số thập phân
    for (final node in nodes) {
      node.x = _r3(node.x);
      node.y = _r3(node.y);
    }

    return RawGraphData(
      nodes: nodes,
      edges: raw.edges,
      family: raw.family,
    );
  }

  void _centerAndScale(List<RawNodeData> nodes) {
    if (nodes.isEmpty) return;

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final n in nodes) {
      if (n.x < minX) minX = n.x;
      if (n.x > maxX) maxX = n.x;
      if (n.y < minY) minY = n.y;
      if (n.y > maxY) maxY = n.y;
    }

    final width = max(0.01, maxX - minX);
    final height = max(0.01, maxY - minY);

    final currentCx = minX + width / 2;
    final currentCy = minY + height / 2;

    const targetCx = 0.50;
    const targetCy = 0.50;

    final targetSpan = maxMargin - minMargin;
    final currentMaxSpan = max(width, height);
    final scale = currentMaxSpan > targetSpan ? (targetSpan / currentMaxSpan) : 1.0;

    for (final n in nodes) {
      n.x = targetCx + (n.x - currentCx) * scale;
      n.y = targetCy + (n.y - currentCy) * scale;
      n.x = n.x.clamp(minMargin, maxMargin);
      n.y = n.y.clamp(minMargin, maxMargin);
    }
  }
}
