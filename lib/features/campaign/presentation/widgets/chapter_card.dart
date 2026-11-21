import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/chapter_info.dart';

/// Card đại diện cho một Chapter trên màn hình Campaign Home.
class ChapterCard extends StatelessWidget {
  const ChapterCard({
    super.key,
    required this.chapter,
    required this.completedLevels,
    required this.totalStars,
    required this.isUnlocked,
    required this.onTap,
  });

  final ChapterInfo chapter;
  final int completedLevels;
  final int totalStars;
  final bool isUnlocked;
  final VoidCallback onTap;

  static const int maxStarsPerChapter = 90; // 30 màn * 3 sao

  String _getTitle(AppLocalizations l10n) {
    switch (chapter.id) {
      case 1:
        return l10n.chapter1Title;
      case 2:
        return l10n.chapter2Title;
      case 3:
        return l10n.chapter3Title;
      case 4:
        return l10n.chapter4Title;
      case 5:
        return l10n.chapter5Title;
      case 6:
        return l10n.chapter6Title;
      default:
        return chapter.title;
    }
  }

  String _getSubtitle(AppLocalizations l10n) {
    switch (chapter.id) {
      case 1:
        return l10n.chapter1Subtitle;
      case 2:
        return l10n.chapter2Subtitle;
      case 3:
        return l10n.chapter3Subtitle;
      case 4:
        return l10n.chapter4Subtitle;
      case 5:
        return l10n.chapter5Subtitle;
      case 6:
        return l10n.chapter6Subtitle;
      default:
        return chapter.subtitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progressFraction =
        (completedLevels / chapter.levelCount).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.surface
            : const Color(0xFF131D33).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? AppColors.borderSubtle
              : Colors.white.withValues(alpha: 0.05),
          width: 1.2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isUnlocked ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng tiêu đề: Badge Chapter + Tên + Trạng thái Lock
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? const Color(0xFF0F172A)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isUnlocked
                              ? AppColors.accent.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Text(
                        l10n.chapterShort(chapter.id).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked
                              ? AppColors.accent
                              : AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getTitle(l10n),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isUnlocked)
                      const Icon(
                        Icons.lock_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.accent,
                        size: 24,
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Mô tả đặc trưng của Chapter
                Text(
                  _getSubtitle(l10n),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isUnlocked
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),

                // Tiến độ & Số sao
                if (isUnlocked) ...[
                  // Thanh tiến trình
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      backgroundColor: const Color(0xFF0F172A),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.chapterLevelsProgress(completedLevels, chapter.levelCount),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 17,
                            color: Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalStars/$maxStarsPerChapter',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFEF3C7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.unlockChapterRequirement(chapter.id - 1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
