import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../graph_coloring/application/energy_providers.dart';
import '../../../graph_coloring/application/game_controller.dart';
import '../../../graph_coloring/presentation/screens/game_screen.dart';
import '../../../graph_coloring/presentation/widgets/energy_ad_dialog.dart';
import '../../../graph_coloring/presentation/widgets/game_background_widget.dart';
import '../../application/campaign_providers.dart';
import '../../application/level_providers.dart';
import '../../domain/entities/chapter_info.dart';
import '../widgets/level_tile.dart';

/// Màn hình chọn màn chơi (30 levels) cho một Chapter cụ thể.
class LevelSelectionScreen extends ConsumerWidget {
  const LevelSelectionScreen({
    super.key,
    required this.chapter,
  });

  final ChapterInfo chapter;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final campaignState = ref.watch(campaignNotifierProvider);
    final levelRepo = ref.watch(levelRepositoryProvider);
    final energy = ref.watch(dailyEnergyNotifierProvider);
    final levels = levelRepo.getLevelsByChapter(chapter.id);

    // Tính thống kê Chapter
    int completedCount = 0;
    int chapterStars = 0;
    for (final lvl in levels) {
      if (campaignState.isLevelCompleted(lvl.id)) {
        completedCount++;
      }
      chapterStars += campaignState.getLevelStars(lvl.id);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.chapterShort(chapter.id)}: ${_getTitle(l10n)}',
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              l10n.levelsRange(chapter.startOverallIndex, chapter.endOverallIndex),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Nút quay về trang chủ (Home)
          IconButton(
            tooltip: l10n.homeTooltip,
            icon: const Icon(Icons.home_rounded, color: Colors.white70),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),

          // Huy hiệu Năng lượng (chạm để mở EnergyAdDialog)
          GestureDetector(
            onTap: () => EnergyAdDialog.show(context),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1065).withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.energy.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: Color(0xFFC084FC),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$energy/${DailyEnergyRepository.maxDailyEnergy}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE9D5FF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: GameBackgroundWidget(
        child: Column(
          children: [
            // Header thống kê Chapter
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: Color(0xFF34D399),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.completedCountText(completedCount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD1FAE5),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppColors.border,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.starsCountText(chapterStars),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFEF3C7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lưới 30 levels
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final level = levels[index];
                  final isUnlocked = campaignState.isLevelUnlocked(level.id);
                  final isCompleted = campaignState.isLevelCompleted(level.id);
                  final bestStars = campaignState.getLevelStars(level.id);
                  final isCurrent = isUnlocked && !isCompleted;

                  return LevelTile(
                    levelNumber: level.levelNumber,
                    overallIndex: level.overallIndex,
                    bestStars: bestStars,
                    isUnlocked: isUnlocked,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    onTap: () {
                      if (energy <= 0) {
                        EnergyAdDialog.show(
                          context,
                          reasonMessage: l10n.energyReasonPlay,
                          onEnergyGranted: () {
                            ref
                                .read(gameControllerProvider.notifier)
                                .loadLevel(level, resetSession: true);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const GameScreen(),
                              ),
                            );
                          },
                        );
                        return;
                      }

                      // Nạp level vào controller và reset từ đầu theo yêu cầu
                      ref
                          .read(gameControllerProvider.notifier)
                          .loadLevel(level, resetSession: true);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GameScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
