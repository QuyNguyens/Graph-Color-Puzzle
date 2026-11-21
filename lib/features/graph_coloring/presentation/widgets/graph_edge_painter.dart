import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/entities/graph.dart';
import '../../domain/entities/graph_edge.dart';
import '../../domain/entities/puzzle_color.dart';
import '../models/active_edge_animation.dart';
import '../theme/puzzle_color_palette.dart';

/// CustomPainter vẽ các cạnh nối giữa các đỉnh trong đồ thị.
/// Hỗ trợ:
/// 1. Tô màu cạnh tĩnh theo màu của 2 đỉnh đầu mút (Phase A1).
/// 2. Hoạt họa lan tỏa màu sắc dạng thác nước (Staggered Waterfall) và va chạm đa sóng (Phase A2 + A3).
class GraphEdgePainter extends CustomPainter {
  GraphEdgePainter({
    required this.graph,
    this.highlightedNodeId,
    this.activeAnimations,
    this.getElapsedMs,
    this.showColoredLines = true,
    super.repaint,
  });

  final Graph graph;
  final String? highlightedNodeId;
  final Map<GraphEdge, ActiveEdgeAnimation>? activeAnimations;
  final int Function()? getElapsedMs;
  final bool showColoredLines;

  static const double _normalStrokeWidth = 2.4;
  static const double _highlightStrokeWidth = 2.8;

  // Reusable Paint instances owned by this painter instance to eliminate per-frame allocations
  final Paint _roundPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final Paint _buttPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.butt;

  @override
  void paint(Canvas canvas, Size size) {
    final currentElapsedMs = getElapsedMs != null ? getElapsedMs!() : 0;

    for (final edge in graph.edges) {
      final nodeU = graph.getNode(edge.u);
      final nodeV = graph.getNode(edge.v);

      if (nodeU == null || nodeV == null) continue;

      final start = Offset(nodeU.x * size.width, nodeU.y * size.height);
      final end = Offset(nodeV.x * size.width, nodeV.y * size.height);

      final isEdgeHighlighted = highlightedNodeId != null &&
          (edge.u == highlightedNodeId || edge.v == highlightedNodeId);
      final strokeWidth =
          isEdgeHighlighted ? _highlightStrokeWidth : _normalStrokeWidth;

      // Nếu cơ chế đường nối màu bị TẮT: Vẽ đường nối trung tính đơn sắc, không vẽ màu các đỉnh
      if (!showColoredLines) {
        _roundPaint
          ..color = isEdgeHighlighted
              ? AppColors.graphEdgeHighlight
              : AppColors.graphEdge
          ..strokeWidth = strokeWidth;
        canvas.drawLine(start, end, _roundPaint);
        continue;
      }

      final activeAnim = activeAnimations?[edge];
      if (activeAnim != null) {
        // Cạnh đang trong quá trình hoạt họa lan tỏa màu (Phase A2 + A3)
        _paintActiveEdge(
          canvas: canvas,
          start: start,
          end: end,
          anim: activeAnim,
          strokeWidth: strokeWidth,
          isEdgeHighlighted: isEdgeHighlighted,
          currentElapsedMs: currentElapsedMs,
        );
      } else {
        // Cạnh tĩnh bình thường (Phase A1 contract)
        final colorU = nodeU.currentColor;
        final colorV = nodeV.currentColor;

        _paintStaticEdge(
          canvas: canvas,
          start: start,
          end: end,
          colorU: colorU,
          colorV: colorV,
          strokeWidth: strokeWidth,
          isEdgeHighlighted: isEdgeHighlighted,
        );
      }
    }
  }

  /// Vẽ cạnh đang hoạt họa với khả năng lan tỏa đa sóng, va chạm và trễ thác nước.
  void _paintActiveEdge({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required ActiveEdgeAnimation anim,
    required double strokeWidth,
    required bool isEdgeHighlighted,
    required int currentElapsedMs,
  }) {
    final diff = end - start;
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    // 1. Vị trí đầu sóng s_U (từ phía U, tăng dần từ 0.0 -> target)
    double sU = 0.0;
    if (anim.waveU != null) {
      sU = anim.waveU!.getPosition(currentElapsedMs);
    } else if (anim.frozenOvershootU != null) {
      sU = anim.frozenOvershootU!;
    }

    // 2. Vị trí đầu sóng s_V (từ phía V, giảm dần từ 1.0 -> target)
    double sV = 1.0;
    if (anim.waveV != null) {
      sV = anim.waveV!.getPosition(currentElapsedMs);
    } else if (anim.frozenOvershootV != null) {
      sV = anim.frozenOvershootV!;
    }

    // 3. Vẽ lớp nền cơ sở (underlying base snapshot)
    // Đảm bảo các cạnh đang chờ (delay pending) hoặc các đoạn chưa lan tới giữ đúng màu snapshot
    if (anim.underlyingColorU == anim.underlyingColorV) {
      _roundPaint
        ..color = anim.underlyingColorU
        ..strokeWidth = strokeWidth;
      canvas.drawLine(start, end, _roundPaint);
    } else {
      _roundPaint
        ..color = anim.underlyingColorU
        ..strokeWidth = strokeWidth;
      canvas.drawLine(start, mid, _roundPaint);

      _buttPaint
        ..color = anim.underlyingColorV
        ..strokeWidth = strokeWidth;
      canvas.drawLine(mid, end, _buttPaint);
    }

    // 4. Vẽ sóng U lan tỏa từ start (s = 0.0) đến P(redFront)
    // Nếu có sóng V tràn qua che Red overshoot thì redFront bị kẹp bởi sV
    final redFront = anim.frozenOvershootU != null ? sU.clamp(0.0, sV) : sU;
    if (redFront > 0.0) {
      final waveColorU = anim.waveU?.color ?? anim.underlyingColorU;
      final pFrontU = start + diff * redFront;
      _roundPaint
        ..color = waveColorU
        ..strokeWidth = strokeWidth;
      canvas.drawLine(start, pFrontU, _roundPaint);
    }

    // 5. Vẽ sóng V lan tỏa từ P(blueFront) đến end (s = 1.0)
    // Nếu có sóng U tràn qua che Blue overshoot thì blueFront bị kẹp bởi sU
    final blueFront = anim.frozenOvershootV != null ? sV.clamp(sU, 1.0) : sV;
    if (blueFront < 1.0) {
      final waveColorV = anim.waveV?.color ?? anim.underlyingColorV;
      final pFrontV = start + diff * blueFront;
      _buttPaint
        ..color = waveColorV
        ..strokeWidth = strokeWidth;
      canvas.drawLine(pFrontV, end, _buttPaint);
    }
  }

  /// Vẽ cạnh tĩnh theo màu hiện tại của 2 đỉnh (bảo toàn 100% hợp đồng Phase A1).
  void _paintStaticEdge({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required PuzzleColor? colorU,
    required PuzzleColor? colorV,
    required double strokeWidth,
    required bool isEdgeHighlighted,
  }) {
    final defaultEdgeColor = isEdgeHighlighted
        ? AppColors.graphEdgeHighlight
        : AppColors.graphEdge;

    // Case A: Cả 2 đỉnh đều chưa tô màu -> 100% màu mặc định
    if (colorU == null && colorV == null) {
      _roundPaint
        ..color = defaultEdgeColor
        ..strokeWidth = strokeWidth;
      canvas.drawLine(start, end, _roundPaint);
      return;
    }

    // Case B: Chỉ đỉnh U có màu -> 100% màu của U
    if (colorU != null && colorV == null) {
      _roundPaint
        ..color = PuzzleColorPalette.getColor(colorU)
        ..strokeWidth = strokeWidth;
      canvas.drawLine(start, end, _roundPaint);
      return;
    }

    // Case C: Chỉ đỉnh V có màu -> 100% màu của V
    if (colorU == null && colorV != null) {
      _roundPaint
        ..color = PuzzleColorPalette.getColor(colorV)
        ..strokeWidth = strokeWidth;
      canvas.drawLine(start, end, _roundPaint);
      return;
    }

    // Case E: Cả 2 đỉnh cùng màu (phục hồi hoặc đồ thị đặc biệt) -> 100% màu đó
    if (colorU == colorV) {
      _roundPaint
        ..color = PuzzleColorPalette.getColor(colorU)
        ..strokeWidth = strokeWidth;
      canvas.drawLine(start, end, _roundPaint);
      return;
    }

    // Case D: Cả 2 đỉnh có màu khác nhau -> Tách đôi 50% / 50% tại trung điểm hình học P(0.5)
    final mid = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    // 1. Vẽ nền trải dài toàn bộ đoạn nối bằng màu U để đảm bảo không bị hở khe subpixel tại trung điểm
    _roundPaint
      ..color = PuzzleColorPalette.getColor(colorU)
      ..strokeWidth = strokeWidth;
    canvas.drawLine(start, end, _roundPaint);

    // 2. Phủ nửa đoạn từ trung điểm P(0.5) đến end bằng màu V với StrokeCap.butt phẳng tại trung điểm
    _buttPaint
      ..color = PuzzleColorPalette.getColor(colorV)
      ..strokeWidth = strokeWidth;
    canvas.drawLine(mid, end, _buttPaint);
  }

  @override
  bool shouldRepaint(covariant GraphEdgePainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.showColoredLines != showColoredLines ||
        oldDelegate.highlightedNodeId != highlightedNodeId ||
        oldDelegate.activeAnimations != activeAnimations ||
        oldDelegate.getElapsedMs != getElapsedMs;
  }
}
