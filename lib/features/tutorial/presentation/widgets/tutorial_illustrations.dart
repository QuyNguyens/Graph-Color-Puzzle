import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../graph_coloring/presentation/theme/puzzle_color_palette.dart';

/// Bộ hình minh họa trực quan (Vector & Custom Widgets) cho 6 bước hướng dẫn.
/// Tuân thủ quy chuẩn mỹ thuật Midnight Slate / Deep Navy và các quy tắc Graph Coloring thực tế.

// ---------------------------------------------------------------------------
// Helper: Vẽ một quả bóng màu bóng bẩy (Glossy Sphere) đồng bộ phong cách game
// ---------------------------------------------------------------------------
class TutorialGlossyBall extends StatelessWidget {
  const TutorialGlossyBall({
    super.key,
    required this.color,
    this.size = 44.0,
    this.label,
    this.textColor,
    this.isSelected = false,
    this.isUncolored = false,
  });

  final Color color;
  final double size;
  final String? label;
  final Color? textColor;
  final bool isSelected;
  final bool isUncolored;

  @override
  Widget build(BuildContext context) {
    if (isUncolored) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.nodeUncolored,
          border: Border.all(
            color: isSelected ? AppColors.nodeSelected : AppColors.nodeBorder,
            width: isSelected ? 2.5 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? AppColors.nodeSelected : AppColors.nodeBorder)
                  .withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label ?? '?',
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.bold,
              color: AppColors.nodeText,
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            color,
            Color.lerp(color, Colors.black, 0.45) ?? Colors.black,
          ],
          stops: const [0.05, 0.55, 1.0],
        ),
        border: Border.all(
          color: isSelected ? Colors.white : Colors.white24,
          width: isSelected ? 2.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      child: label != null
          ? Center(
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Colors.white,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 1 ILLUSTRATION — Đồ thị mẫu hoàn chỉnh lung linh (Welcome)
// ---------------------------------------------------------------------------
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      width: 220,
      child: CustomPaint(
        painter: _WelcomeGraphPainter(),
        child: Stack(
          alignment: Alignment.center,
          children: const [
            // Center Orange Node
            Positioned(
              left: 88,
              top: 48,
              child: TutorialGlossyBall(
                color: Color(0xFFF59E0B),
                size: 44,
                label: 'C',
              ),
            ),
            // Top Magenta Node
            Positioned(
              left: 89,
              top: 2,
              child: TutorialGlossyBall(
                color: Color(0xFFEC4899),
                size: 38,
                label: '1',
              ),
            ),
            // Right Lime Green Node
            Positioned(
              left: 172,
              top: 51,
              child: TutorialGlossyBall(
                color: Color(0xFF10B981),
                size: 38,
                label: '2',
              ),
            ),
            // Bottom Royal Blue Node
            Positioned(
              left: 89,
              top: 100,
              child: TutorialGlossyBall(
                color: Color(0xFF3B82F6),
                size: 38,
                label: '3',
              ),
            ),
            // Left Purple Node
            Positioned(
              left: 6,
              top: 51,
              child: TutorialGlossyBall(
                color: Color(0xFF8B5CF6),
                size: 38,
                label: '4',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    const center = Offset(110, 70);
    const top = Offset(108, 21);
    const right = Offset(191, 70);
    const bottom = Offset(108, 119);
    const left = Offset(25, 70);

    final points = [top, right, bottom, left];

    // Radial spokes from center
    for (final p in points) {
      canvas.drawLine(center, p, glowPaint);
      canvas.drawLine(center, p, edgePaint);
    }

    // Outer perimeter ring
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      canvas.drawLine(p1, p2, glowPaint);
      canvas.drawLine(p1, p2, edgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// STEP 2 ILLUSTRATION — So sánh Hợp lệ vs Xung đột (Rules Comparison)
// ---------------------------------------------------------------------------
class RuleComparisonIllustration extends StatelessWidget {
  const RuleComparisonIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Cột bên trái: HỢP LỆ (Khác màu)
            Flexible(
              child: _buildComparisonCard(
                isValid: true,
                badgeText: l10n.tutorialValidLabel,
                subText: l10n.tutorialValidDesc,
                color1: const Color(0xFF3B82F6), // Blue
                color2: const Color(0xFF10B981), // Green
                edgeColor: const Color(0xFF10B981),
                badgeColor: AppColors.success,
                icon: Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 12),
            // Cột bên phải: XUNG ĐỘT (Cùng màu)
            Flexible(
              child: _buildComparisonCard(
                isValid: false,
                badgeText: l10n.tutorialConflictLabel,
                subText: l10n.tutorialConflictDesc,
                color1: const Color(0xFFEF4444), // Red
                color2: const Color(0xFFEF4444), // Red (trùng)
                edgeColor: const Color(0xFFEF4444),
                badgeColor: AppColors.error,
                icon: Icons.cancel_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComparisonCard({
    required bool isValid,
    required String badgeText,
    required String subText,
    required Color color1,
    required Color color2,
    required Color edgeColor,
    required Color badgeColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isValid
            ? const Color(0xFF064E3B).withValues(alpha: 0.35)
            : const Color(0xFF7F1D1D).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Huy hiệu trạng thái
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Minh họa 2 đỉnh nối nhau
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cạnh nối giữa 2 đỉnh
                Positioned(
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: edgeColor,
                      boxShadow: [
                        BoxShadow(
                          color: edgeColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                // Node trái
                Positioned(
                  left: 4,
                  child: TutorialGlossyBall(
                    color: color1,
                    size: 38,
                  ),
                ),
                // Node phải
                Positioned(
                  right: 4,
                  child: TutorialGlossyBall(
                    color: color2,
                    size: 38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Mô tả ngắn
          Text(
            subText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isValid ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 3 ILLUSTRATION — Chọn và đặt màu (Placement Interaction)
// ---------------------------------------------------------------------------
class PlacementIllustration extends StatelessWidget {
  const PlacementIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Đỉnh chưa tô màu ở trên
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            TutorialGlossyBall(
              color: Colors.transparent,
              size: 48,
              isUncolored: true,
              isSelected: true,
              label: '1',
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Mũi tên hướng dẫn di chuyển / chọn
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.arrow_upward_rounded, color: AppColors.accent, size: 22),
            SizedBox(width: 4),
            Icon(Icons.touch_app_rounded, color: AppColors.warning, size: 20),
          ],
        ),
        const SizedBox(height: 6),

        // Thanh chọn màu palette nhỏ bên dưới
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TutorialGlossyBall(
                color: Color(0xFFEF4444), // Red
                size: 32,
              ),
              SizedBox(width: 10),
              TutorialGlossyBall(
                color: Color(0xFF3B82F6), // Blue (đang chọn)
                size: 36,
                isSelected: true,
              ),
              SizedBox(width: 10),
              TutorialGlossyBall(
                color: Color(0xFF10B981), // Green
                size: 32,
              ),
              SizedBox(width: 10),
              TutorialGlossyBall(
                color: Color(0xFFF59E0B), // Yellow
                size: 32,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 4 ILLUSTRATION — Kho số lượng màu chính xác (Color Inventory)
// ---------------------------------------------------------------------------
class InventoryIllustration extends StatelessWidget {
  const InventoryIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mô phỏng Color Inventory Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInventoryBadge(
                color: const Color(0xFF3B82F6), // Blue
                countText: '2',
                isDepleted: false,
              ),
              const SizedBox(width: 12),
              _buildInventoryBadge(
                color: const Color(0xFFF59E0B), // Yellow
                countText: '1',
                isDepleted: false,
              ),
              const SizedBox(width: 12),
              _buildInventoryBadge(
                color: const Color(0xFF10B981), // Green (đã dùng hết)
                countText: '0 ✓',
                isDepleted: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Nhãn mục tiêu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderHairline),
          ),
          child: Text(
            l10n.tutorialInventoryGoalLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryBadge({
    required Color color,
    required String countText,
    required bool isDepleted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDepleted
            ? const Color(0xFF0F172A).withValues(alpha: 0.6)
            : const Color(0xFF334155),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDepleted
              ? Colors.white12
              : color.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TutorialGlossyBall(
            color: color,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            countText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDepleted ? AppColors.textMuted : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 5 ILLUSTRATION — Các công cụ hỗ trợ & Khiên lỗi (Actions & Shields)
// ---------------------------------------------------------------------------
class ActionsIllustration extends StatelessWidget {
  const ActionsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildActionChip(
          icon: Icons.undo_rounded,
          iconColor: Colors.white70,
          title: l10n.tutorialActionUndo,
          badge: '1/1',
        ),
        _buildActionChip(
          icon: Icons.lightbulb_rounded,
          iconColor: const Color(0xFFFBBF24),
          title: l10n.tutorialActionHint,
          badge: '1/day',
        ),
        _buildActionChip(
          icon: Icons.refresh_rounded,
          iconColor: Colors.white70,
          title: l10n.tutorialActionRestart,
          badge: '0 or 1⚡',
        ),
        _buildActionChip(
          icon: Icons.shield_rounded,
          iconColor: const Color(0xFF38BDF8),
          title: l10n.tutorialActionShields,
          badge: '2 🛡️',
        ),
        _buildActionChip(
          icon: Icons.polyline_rounded,
          iconColor: const Color(0xFF34D399),
          title: l10n.coloredLinesLabel,
          badge: 'ON/OFF',
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
  }) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 6 ILLUSTRATION — Đồ thị hoàn thành & Đạt 3 sao (Victory)
// ---------------------------------------------------------------------------
class VictoryIllustration extends StatelessWidget {
  const VictoryIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3 ngôi sao vàng rực rỡ
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 36),
            SizedBox(width: 6),
            Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 48),
            SizedBox(width: 6),
            Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 36),
          ],
        ),
        const SizedBox(height: 6),

        // Mini graph 3 đỉnh tam giác hợp lệ 100%
        SizedBox(
          width: 130,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: const [
              Positioned(
                top: 0,
                child: TutorialGlossyBall(
                  color: Color(0xFFEF4444), // Red
                  size: 28,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 10,
                child: TutorialGlossyBall(
                  color: Color(0xFF3B82F6), // Blue
                  size: 28,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 10,
                child: TutorialGlossyBall(
                  color: Color(0xFF10B981), // Green
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
