import 'package:flutter/material.dart';

/// Widget nền không gian đồ thị phong cách Midnight Slate / Deep Navy.
/// Mang lại phong cách giải đố tối giản, cao cấp (như Monument Valley / The Room),
/// giúp các đỉnh màu bão hòa (Đỏ, Xanh, Vàng, Tím, Lục) tỏa sáng với độ tương phản cao nhất.
class GameBackgroundWidget extends StatelessWidget {
  const GameBackgroundWidget({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(
            painter: _MidnightSlateBackgroundPainter(),
          ),
        ),
        child,
      ],
    );
  }
}

class _MidnightSlateBackgroundPainter extends CustomPainter {
  const _MidnightSlateBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Dải màu nền chủ đạo: Deep Navy / Midnight Slate 900 -> 950
    // Hoàn toàn trung tính, êm dịu, không cạnh tranh màu sắc với các đỉnh đồ thị
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F172A), // Slate 900 - Deep Midnight Navy
          Color(0xFF131D33), // Deep Midnight Blue
          Color(0xFF0B1120), // Obsidian Slate 950
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Vùng chiều sâu ánh sáng tỏa tâm (Soft Radial Ambient Depth)
    // Tỏa sáng mờ phía sau bàn cờ giúp nâng bàn cờ nổi bật khỏi nền
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.15),
        radius: 0.85,
        colors: [
          const Color(0xFF1E293B).withValues(alpha: 0.5), // Slate 800 ambient
          Colors.transparent,
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, glowPaint);

    // 3. Mạng lưới điểm kỷ hà vi mô (Low-opacity Micro Dot Grid Pattern)
    const double step = 28.0;
    final dotPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.35) // Slate 700
      ..style = PaintingStyle.fill;

    final cols = (size.width / step).ceil() + 1;
    final rows = (size.height / step).ceil() + 1;

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final cx = i * step;
        final cy = j * step;
        canvas.drawCircle(Offset(cx, cy), 1.0, dotPaint);
      }
    }

    // 4. Họa tiết đồ thị kỷ hà trừu tượng góc nền (Constellation watermark)
    _drawConstellationWatermark(canvas, size);
  }

  void _drawConstellationWatermark(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF475569).withValues(alpha: 0.12) // Slate 600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final nodePaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.16) // Slate 500
      ..style = PaintingStyle.fill;

    // Góc trên bên phải
    final p1 = Offset(size.width - 24, 36);
    final p2 = Offset(size.width - 76, 72);
    final p3 = Offset(size.width - 40, 118);
    final p4 = Offset(size.width - 105, 126);

    canvas.drawLine(p1, p2, linePaint);
    canvas.drawLine(p2, p3, linePaint);
    canvas.drawLine(p2, p4, linePaint);
    canvas.drawLine(p3, p4, linePaint);

    canvas.drawCircle(p1, 3.0, nodePaint);
    canvas.drawCircle(p2, 3.5, nodePaint);
    canvas.drawCircle(p3, 3.0, nodePaint);
    canvas.drawCircle(p4, 3.5, nodePaint);

    // Góc dưới bên trái
    final q1 = Offset(36, size.height - 76);
    final q2 = Offset(86, size.height - 40);
    final q3 = Offset(46, size.height - 124);
    final q4 = Offset(110, size.height - 104);

    canvas.drawLine(q1, q2, linePaint);
    canvas.drawLine(q1, q3, linePaint);
    canvas.drawLine(q3, q4, linePaint);
    canvas.drawLine(q2, q4, linePaint);

    canvas.drawCircle(q1, 3.0, nodePaint);
    canvas.drawCircle(q2, 3.5, nodePaint);
    canvas.drawCircle(q3, 3.5, nodePaint);
    canvas.drawCircle(q4, 3.0, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
