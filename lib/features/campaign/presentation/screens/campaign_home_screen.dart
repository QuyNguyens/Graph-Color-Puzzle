import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_metadata.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../graph_coloring/application/energy_providers.dart';
import '../../../graph_coloring/application/game_controller.dart';
import '../../../graph_coloring/application/line_settings_providers.dart';
import '../../../graph_coloring/presentation/screens/game_screen.dart';
import '../../../graph_coloring/presentation/widgets/colored_lines_ad_dialog.dart';
import '../../../graph_coloring/presentation/widgets/energy_ad_dialog.dart';
import '../../../graph_coloring/presentation/widgets/game_background_widget.dart';
import '../../application/campaign_providers.dart';
import '../../application/campaign_state.dart';
import '../../application/level_providers.dart';
import '../../application/sound_providers.dart';
import '../../domain/entities/chapter_info.dart';
import '../../domain/repositories/level_repository.dart';
import '../widgets/chapter_card.dart';
import '../widgets/continue_session_card.dart';
import '../widgets/game_icon_widget.dart';
import '../widgets/game_info_dialog.dart';
import '../../../tutorial/presentation/screens/tutorial_screen.dart';
import '../../domain/entities/puzzle_level.dart';
import 'level_selection_screen.dart';

/// Màn hình chính của Campaign: Chọn Chapter và Tiếp tục ván chơi dở dang.
class CampaignHomeScreen extends ConsumerWidget {
  const CampaignHomeScreen({super.key});

  static const int totalCampaignLevels = 180;
  static const int totalCampaignStars = 540; // 180 * 3 sao

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final campaignState = ref.watch(campaignNotifierProvider);
    final levelRepo = ref.watch(levelRepositoryProvider);
    final energy = ref.watch(dailyEnergyNotifierProvider);
    final isSoundOn = ref.watch(soundSettingsProvider);
    final isColoredLinesOn = ref.watch(coloredLinesSettingsProvider);
    final remainingLinesQuota = ref.watch(dailyColoredLinesNotifierProvider);
    final chapters = levelRepo.getChapters();

    // Kiểm tra ván chơi dở dang đang lưu (nếu có)
    final activeSessionAsync = ref.watch(activeSessionLevelIdProvider);
    final activeLevelId = activeSessionAsync.asData?.value;

    // Chỉ hiển thị Continue nếu ID là màn chơi hợp lệ trong 180 Campaign levels
    final activeLevel = (activeLevelId != null &&
            activeLevelId != GameController.currentLevelId)
        ? levelRepo.getLevelById(activeLevelId)
        : null;

    if (campaignState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        // Row 1: Định danh trò chơi và các hành động (Game Identity & Actions)
        title: const Row(
          children: [
            GameIconWidget(size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                AppMetadata.appName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Nút hướng dẫn cách chơi (How to Play Tutorial)
          IconButton(
            tooltip: l10n.howToPlayTooltip,
            icon: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.accent,
              size: 22,
            ),
            onPressed: () => _openTutorial(context, ref, activeLevel, levelRepo),
          ),

          // Nút bật / tắt âm thanh (Sound Icon Toggle)
          IconButton(
            tooltip: isSoundOn ? l10n.soundOffTooltip : l10n.soundOnTooltip,
            icon: Icon(
              isSoundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: isSoundOn ? AppColors.accent : Colors.white60,
              size: 22,
            ),
            onPressed: () => ref.read(soundSettingsProvider.notifier).toggle(),
          ),

          // Nút bật / tắt đường nối màu (Colored Lines Toggle)
          Badge(
            label: Text(
              '$remainingLinesQuota',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: isColoredLinesOn
                ? const Color(0xFF0284C7)
                : const Color(0xFF475569),
            textColor: Colors.white,
            offset: const Offset(-4, 4),
            child: IconButton(
              tooltip: isColoredLinesOn
                  ? '${l10n.coloredLinesOnTooltip} ($remainingLinesQuota/5)'
                  : '${l10n.coloredLinesOffTooltip} ($remainingLinesQuota/5)',
              icon: Icon(
                isColoredLinesOn
                    ? Icons.polyline_rounded
                    : Icons.polyline_outlined,
                color:
                    isColoredLinesOn ? const Color(0xFF38BDF8) : Colors.white60,
                size: 22,
              ),
              onPressed: () {
                if (isColoredLinesOn) {
                  ref
                      .read(coloredLinesSettingsProvider.notifier)
                      .setEnabled(false);
                } else {
                  if (remainingLinesQuota > 0) {
                    ref
                        .read(coloredLinesSettingsProvider.notifier)
                        .setEnabled(true);
                  } else {
                    ColoredLinesAdDialog.show(context);
                  }
                }
              },
            ),
          ),

          // Nút thông tin trò chơi (Information Icon -> GameInfoDialog)
          IconButton(
            tooltip: l10n.gameInfoTooltip,
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white70,
              size: 22,
            ),
            onPressed: () => GameInfoDialog.show(
              context,
              onResetProgress: () => _confirmReset(context, ref),
              onOpenTutorial: () {
                Navigator.of(context).pop();
                _openTutorial(context, ref, activeLevel, levelRepo);
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
        // Row 2: Thống kê người chơi (Player Statistics: Energy, Total Stars, Played Levels)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                // 1. Thống kê Năng lượng (Energy, chạm để mở EnergyAdDialog)
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFFC084FC),
                    valueText: '$energy/${DailyEnergyRepository.maxDailyEnergy}',
                    valueColor: const Color(0xFFE9D5FF),
                    label: l10n.statEnergy,
                    labelColor: const Color(0xFFD8B4FE),
                    backgroundColor: const Color(0xFF2E1065).withValues(alpha: 0.75),
                    borderColor: AppColors.energy.withValues(alpha: 0.5),
                    onTap: () => EnergyAdDialog.show(context),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Thống kê Tổng số sao (Total Stars)
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFFBBF24),
                    valueText: '${campaignState.totalStars}/$totalCampaignStars',
                    valueColor: const Color(0xFFFEF3C7),
                    label: l10n.statTotalStars,
                    labelColor: const Color(0xFFFDE68A),
                    backgroundColor: const Color(0xFF451A03).withValues(alpha: 0.75),
                    borderColor: AppColors.warning.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Thống kê Số màn đã vượt qua (Played Levels)
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFF34D399),
                    valueText: '${campaignState.completedLevelsCount}/$totalCampaignLevels',
                    valueColor: const Color(0xFFD1FAE5),
                    label: l10n.statLevels,
                    labelColor: const Color(0xFFA7F3D0),
                    backgroundColor: const Color(0xFF064E3B).withValues(alpha: 0.75),
                    borderColor: AppColors.success.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: GameBackgroundWidget(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // 1. Thẻ tiếp tục ván chơi dở dang (chỉ hiện khi có ván chưa hoàn thành)
            if (activeLevel != null)
              ContinueSessionCard(
                level: activeLevel,
                onContinue: () {
                  if (energy <= 0) {
                    EnergyAdDialog.show(
                      context,
                      reasonMessage: l10n.energyReasonContinue,
                      onEnergyGranted: () {
                        ref
                            .read(gameControllerProvider.notifier)
                            .loadLevel(activeLevel);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const GameScreen(),
                          ),
                        );
                      },
                    );
                    return;
                  }

                  ref
                      .read(gameControllerProvider.notifier)
                      .loadLevel(activeLevel);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GameScreen(),
                    ),
                  );
                },
              ),

            // Banner giới thiệu
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hub_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.campaignBannerTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          l10n.campaignBannerSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Thẻ Hướng dẫn chơi (How to Play Action Card)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F2B48)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openTutorial(context, ref, activeLevel, levelRepo),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.howToPlayBannerTitle,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.howToPlayBannerSubtitle,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Danh sách 6 Chapter Cards
            for (final chapter in chapters)
              _buildChapterItem(context, ref, chapter, campaignState, levelRepo),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String valueText,
    required Color valueColor,
    required String label,
    required Color labelColor,
    required Color backgroundColor,
    required Color borderColor,
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valueText,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }
    return cardContent;
  }

  Widget _buildChapterItem(
    BuildContext context,
    WidgetRef ref,
    ChapterInfo chapter,
    CampaignState campaignState,
    LevelRepository levelRepo,
  ) {
    final chapterLevels = levelRepo.getLevelsByChapter(chapter.id);

    int completedCount = 0;
    int chapterStars = 0;
    for (final lvl in chapterLevels) {
      if (campaignState.isLevelCompleted(lvl.id)) {
        completedCount++;
      }
      chapterStars += campaignState.getLevelStars(lvl.id);
    }

    // Chapter 1 luôn mở khóa; Chapter k mở khóa khi màn đầu tiên của nó mở khóa
    final firstLevelId = 'c${chapter.id}_l01';
    final isUnlocked = chapter.id == 1 ||
        campaignState.isLevelUnlocked(firstLevelId);

    return ChapterCard(
      chapter: chapter,
      completedLevels: completedCount,
      totalStars: chapterStars,
      isUnlocked: isUnlocked,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LevelSelectionScreen(chapter: chapter),
          ),
        );
      },
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderSubtle),
        ),
        title: Text(
          l10n.resetProgressConfirmTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.resetProgressConfirmMessage,
          style: const TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.buttonCancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await ref.read(campaignNotifierProvider.notifier).resetProgress();
              ref.invalidate(activeSessionLevelIdProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.resetProgressSuccessToast),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(l10n.buttonReset),
          ),
        ],
      ),
    );
  }

  void _openTutorial(
    BuildContext context,
    WidgetRef ref,
    PuzzleLevel? activeLevel,
    LevelRepository levelRepo,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TutorialScreen(
          onStartPlaying: () {
            Navigator.of(context).pop();
            final targetLevel =
                activeLevel ?? levelRepo.getLevelByOverallIndex(1);
            if (targetLevel != null) {
              ref.read(gameControllerProvider.notifier).loadLevel(targetLevel);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const GameScreen(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
