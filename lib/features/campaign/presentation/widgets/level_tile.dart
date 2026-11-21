import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// Phân loại cột mốc của từng màn chơi trong Chapter
enum LevelMilestoneType {
  none,
  colorYellow, // Màn 5: Mở khóa Màu Vàng
  colorGreen,  // Màn 10: Mở khóa Màu Xanh lá
  challenge,   // Màn 15, 25: Màn Thử thách cao độ
  colorPurple, // Màn 20: Mở khóa Màu Tím
  finale,      // Màn 30: Chung kết Chapter
}

/// Ô đại diện cho 1 màn chơi trong Grid Level Selection.
/// Đồng bộ ngôn ngữ thiết kế Dark Node theo phong cách tham chiếu:
/// - Lòng ô màu xanh đen đậm (#111827)
/// - Viền ngọc lục bảo Emerald (#00C995) cho các màn khả dụng / hoàn thành
/// - Viền mờ cho các màn bị khóa
/// - Nổi bật màn hiện tại với viền sáng hơn
/// - Bảo toàn nguyên vẹn huy hiệu và màu cột mốc (Milestone 5, 10, 20), Thử thách (15, 25) và Chung kết (30).
class LevelTile extends StatelessWidget {
  const LevelTile({
    super.key,
    required this.levelNumber,
    required this.overallIndex,
    required this.bestStars,
    required this.isUnlocked,
    required this.isCompleted,
    this.isCurrent = false,
    this.onTap,
  });

  final int levelNumber;
  final int overallIndex;
  final int bestStars;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback? onTap;

  LevelMilestoneType get milestoneType {
    switch (levelNumber) {
      case 5:
        return LevelMilestoneType.colorYellow;
      case 10:
        return LevelMilestoneType.colorGreen;
      case 15:
      case 25:
        return LevelMilestoneType.challenge;
      case 20:
        return LevelMilestoneType.colorPurple;
      case 30:
        return LevelMilestoneType.finale;
      default:
        return LevelMilestoneType.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    double borderWidth = isCurrent ? 2.4 : 1.5;

    final isMilestone = milestoneType != LevelMilestoneType.none;

    if (!isUnlocked) {
      // Màn khóa: Nền tối mờ, viền mờ tối giản
      backgroundColor = isMilestone
          ? const Color(0xFF111827).withValues(alpha: 0.8)
          : const Color(0xFF0F172A).withValues(alpha: 0.7);
      borderColor = isMilestone
          ? _getMilestoneAccentColor().withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.08);
      textColor = AppColors.textMuted;
      if (isMilestone) borderWidth = 1.6;
    } else if (isCompleted) {
      // Màn đã hoàn thành: Nền dark navy #111827, viền emerald #00C995
      backgroundColor = const Color(0xFF111827);
      borderColor = isMilestone
          ? _getMilestoneAccentColor()
          : AppColors.nodeBorder;
      textColor = isMilestone
          ? _getMilestoneAccentColor()
          : AppColors.nodeText;
      if (isMilestone) borderWidth = 1.8;
    } else if (isCurrent) {
      // Màn đang chơi hiện tại: Nền dark navy #111827, viền emerald #00C995 nổi bật
      backgroundColor = const Color(0xFF111827);
      borderColor = isMilestone
          ? _getMilestoneAccentColor()
          : AppColors.nodeBorder;
      textColor = isMilestone
          ? _getMilestoneAccentColor()
          : const Color(0xFF00E5AA);
      borderWidth = 2.4;
    } else {
      // Màn đã mở khóa nhưng chưa chơi
      backgroundColor = const Color(0xFF111827);
      borderColor = isMilestone
          ? _getMilestoneAccentColor().withValues(alpha: 0.8)
          : AppColors.nodeBorder.withValues(alpha: 0.65);
      textColor = isMilestone
          ? _getMilestoneAccentColor()
          : AppColors.nodeText;
      if (isMilestone) borderWidth = 1.6;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: isCurrent
                      ? (isMilestone ? _getMilestoneAccentColor() : AppColors.nodeBorder).withValues(alpha: 0.32)
                      : (isMilestone ? _getMilestoneAccentColor().withValues(alpha: 0.18) : AppColors.nodeBorder.withValues(alpha: 0.14)),
                  blurRadius: isCurrent ? 8 : (isMilestone ? 6 : 4),
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isUnlocked ? onTap : null,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isUnlocked) ...[
                            Icon(
                              milestoneType == LevelMilestoneType.finale
                                  ? Icons.workspace_premium_rounded
                                  : Icons.lock_rounded,
                              size: 18,
                              color: isMilestone
                                  ? _getMilestoneAccentColor().withValues(alpha: 0.5)
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$levelNumber',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isMilestone ? FontWeight.w900 : FontWeight.bold,
                                color: textColor,
                                height: 1.1,
                              ),
                            ),
                          ] else ...[
                            if (milestoneType == LevelMilestoneType.finale) ...[
                              const Icon(
                                Icons.workspace_premium_rounded,
                                size: 14,
                                color: Color(0xFFFBBF24),
                              ),
                              const SizedBox(height: 1),
                            ],
                            Text(
                              '$levelNumber',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: milestoneType == LevelMilestoneType.finale ? 13 : 15,
                                fontWeight: isMilestone ? FontWeight.w900 : FontWeight.bold,
                                color: textColor,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Hàng 3 ngôi sao nhỏ
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (starIdx) {
                                  final hasStar = starIdx < bestStars;
                                  return Icon(
                                    hasStar
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 11,
                                    color: hasStar
                                        ? const Color(0xFFFBBF24)
                                        : Colors.white.withValues(alpha: 0.18),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Huy hiệu màu mới ở góc trên bên phải khi là màn Milestone mở màu
          if (_hasColorBadge())
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getMilestoneColorValue(),
                  border: Border.all(color: const Color(0xFF111827), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),

          // Tag Finale nhỏ ở cạnh trên
          if (milestoneType == LevelMilestoneType.finale && isUnlocked)
            Positioned(
              top: -6,
              left: 2,
              right: 2,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: const Text(
                      'FINALE',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasColorBadge() {
    return milestoneType == LevelMilestoneType.colorYellow ||
        milestoneType == LevelMilestoneType.colorGreen ||
        milestoneType == LevelMilestoneType.colorPurple;
  }

  Color _getMilestoneAccentColor() {
    switch (milestoneType) {
      case LevelMilestoneType.colorYellow:
        return const Color(0xFFF59E0B); // Amber 500
      case LevelMilestoneType.colorGreen:
        return const Color(0xFF10B981); // Emerald 500
      case LevelMilestoneType.challenge:
        return const Color(0xFFF43F5E); // Rose 500
      case LevelMilestoneType.colorPurple:
        return const Color(0xFFA855F7); // Purple 500
      case LevelMilestoneType.finale:
        return const Color(0xFFD97706); // Amber 600 Gold
      case LevelMilestoneType.none:
        return const Color(0xFF64748B);
    }
  }

  Color _getMilestoneColorValue() {
    switch (milestoneType) {
      case LevelMilestoneType.colorYellow:
        return const Color(0xFFFBC02D); // Yellow node
      case LevelMilestoneType.colorGreen:
        return const Color(0xFF43A047); // Green node
      case LevelMilestoneType.colorPurple:
        return const Color(0xFF8E24AA); // Purple node
      default:
        return Colors.transparent;
    }
  }
}
