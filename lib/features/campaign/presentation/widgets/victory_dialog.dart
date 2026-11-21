import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/puzzle_level.dart';
import '../../domain/services/level_title_localizer.dart';

/// Hộp thoại chúc mừng chiến thắng khi người chơi hoàn thành một màn chơi.
/// Giao diện chuẩn Midnight Slate / Deep Navy đồng bộ toàn hệ thống.
class VictoryDialog extends StatelessWidget {
  const VictoryDialog({
    super.key,
    required this.level,
    required this.earnedStars,
    required this.bestStars,
    required this.onNextLevel,
    required this.onReplay,
    required this.onBackToCampaign,
    this.nextLevel,
    this.isNextUnlocked = true,
    this.remainingEnergy = 3,
  });

  final PuzzleLevel? level;
  final int earnedStars;
  final int bestStars;
  final PuzzleLevel? nextLevel;
  final bool isNextUnlocked;
  final int remainingEnergy;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;
  final VoidCallback onBackToCampaign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFinalLevel = level != null && level!.overallIndex >= 180;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppColors.success.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      elevation: 16,
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon huy hiệu chiến thắng
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF064E3B),
                border: Border.all(color: AppColors.success, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFF34D399),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            Text(
              isFinalLevel ? l10n.victoryCampaignFinalTitle : l10n.victoryTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),

            // Tên màn chơi
            if (level != null)
              Text(
                l10n.levelTitleWithIndex(
                  level!.overallIndex,
                  LevelTitleLocalizer.getTitle(level!, Localizations.localeOf(context)),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 18),

            // Hiển thị 3 ngôi sao đạt được
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isEarned = index < earnedStars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 42,
                    color: isEarned
                        ? const Color(0xFFFBBF24)
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),

            // Chi tiết số sao
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF451A03).withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                l10n.victoryStarsSummary(earnedStars, bestStars),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFEF3C7),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút "Màn tiếp theo" (hoặc hoàn thành nếu là level 180)
            if (!isFinalLevel) ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNextUnlocked
                        ? AppColors.accent
                        : AppColors.surfaceElevated,
                    foregroundColor: isNextUnlocked
                        ? const Color(0xFF0F172A)
                        : AppColors.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: isNextUnlocked ? 2 : 0,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    nextLevel != null
                        ? l10n.buttonNextLevelWithIndex(nextLevel!.overallIndex)
                        : l10n.buttonNextLevel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: isNextUnlocked ? onNextLevel : null,
                ),
              ),
              const SizedBox(height: 10),
            ] else ...[
              Text(
                l10n.victoryCampaignFinalMessage,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF34D399),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
            ],

            // Hàng 2 nút: Chơi lại & Về Campaign
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      l10n.buttonReplay,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: onReplay,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.grid_view_rounded, size: 18),
                    label: Text(l10n.buttonCampaign, style: const TextStyle(fontSize: 13)),
                    onPressed: onBackToCampaign,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
