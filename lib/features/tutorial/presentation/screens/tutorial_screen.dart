import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/game_audio_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../graph_coloring/presentation/widgets/game_background_widget.dart';
import '../widgets/tutorial_illustrations.dart';
import '../widgets/tutorial_step_card.dart';

/// Màn hình hướng dẫn luật chơi tương tác (How to Play Tutorial Screen).
/// Gồm 6 bước giáo dục trực quan, hỗ trợ đa ngôn ngữ hoàn toàn,
/// tích hợp hiệu ứng âm thanh và cơ chế điều hướng mượt mà.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({
    super.key,
    this.onStartPlaying,
  });

  /// Callback tùy chọn khi người chơi bấm nút "Bắt đầu chơi" ở bước cuối cùng
  final VoidCallback? onStartPlaying;

  static const int totalSteps = 6;

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _playClickSound() {
    try {
      ref.read(gameAudioServiceProvider).playSelectColor();
    } catch (_) {}
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    _playClickSound();
    if (_currentPage < TutorialScreen.totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishTutorial();
    }
  }

  void _previousPage() {
    _playClickSound();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skipToFinal() {
    _playClickSound();
    _pageController.animateToPage(
      TutorialScreen.totalSteps - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _finishTutorial() {
    _playClickSound();
    if (widget.onStartPlaying != null) {
      widget.onStartPlaying!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLastPage = _currentPage == TutorialScreen.totalSteps - 1;
    final progress = (_currentPage + 1) / TutorialScreen.totalSteps;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: l10n.buttonClose,
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () {
            _playClickSound();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          l10n.tutorialTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _skipToFinal,
              child: Text(
                l10n.tutorialButtonSkip,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
      body: GameBackgroundWidget(
        child: SafeArea(
          child: Column(
            children: [
              // 1. Thanh chỉ báo tiến trình (Progress Indicator)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.tutorialStepProgress(
                            _currentPage + 1,
                            TutorialScreen.totalSteps,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Nội dung các bước hướng dẫn (PageView)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    // BƯỚC 1: Chào mừng & Mục tiêu
                    TutorialStepCard(
                      stepNumber: 1,
                      totalSteps: TutorialScreen.totalSteps,
                      badgeTitle: l10n.tutorialStep1Subtitle,
                      title: l10n.tutorialStep1Title,
                      description: l10n.tutorialStep1Description,
                      illustration: const WelcomeIllustration(),
                      accentColor: const Color(0xFF38BDF8),
                      icon: Icons.hub_rounded,
                    ),

                    // BƯỚC 2: Đỉnh, Cạnh & Quy tắc vàng
                    TutorialStepCard(
                      stepNumber: 2,
                      totalSteps: TutorialScreen.totalSteps,
                      badgeTitle: l10n.tutorialStep2Subtitle,
                      title: l10n.tutorialStep2Title,
                      description: l10n.tutorialStep2Description,
                      illustration: const RuleComparisonIllustration(),
                      accentColor: const Color(0xFF10B981),
                      icon: Icons.rule_rounded,
                    ),

                    // BƯỚC 3: Cách chọn & đặt màu
                    TutorialStepCard(
                      stepNumber: 3,
                      totalSteps: TutorialScreen.totalSteps,
                      badgeTitle: l10n.tutorialStep3Subtitle,
                      title: l10n.tutorialStep3Title,
                      description: l10n.tutorialStep3Description,
                      illustration: const PlacementIllustration(),
                      accentColor: const Color(0xFFF59E0B),
                      icon: Icons.touch_app_rounded,
                    ),

                    // BƯỚC 4: Giới hạn kho màu chính xác
                    TutorialStepCard(
                      stepNumber: 4,
                      totalSteps: TutorialScreen.totalSteps,
                      badgeTitle: l10n.tutorialStep4Subtitle,
                      title: l10n.tutorialStep4Title,
                      description: l10n.tutorialStep4Description,
                      illustration: const InventoryIllustration(),
                      accentColor: const Color(0xFFA855F7),
                      icon: Icons.inventory_2_rounded,
                    ),

                    // BƯỚC 5: Công cụ hỗ trợ & Khiên lỗi
                    TutorialStepCard(
                      stepNumber: 5,
                      totalSteps: TutorialScreen.totalSteps,
                      badgeTitle: l10n.tutorialStep5Subtitle,
                      title: l10n.tutorialStep5Title,
                      description: l10n.tutorialStep5Description,
                      illustration: const ActionsIllustration(),
                      accentColor: const Color(0xFFEC4899),
                      icon: Icons.shield_rounded,
                    ),

                    // BƯỚC 6: Chiến thắng & Chinh phục
                    TutorialStepCard(
                      stepNumber: 6,
                      totalSteps: TutorialScreen.totalSteps,
                      badgeTitle: l10n.tutorialStep6Subtitle,
                      title: l10n.tutorialStep6Title,
                      description: l10n.tutorialStep6Description,
                      illustration: const VictoryIllustration(),
                      accentColor: const Color(0xFFFBBF24),
                      icon: Icons.emoji_events_rounded,
                    ),
                  ],
                ),
              ),

              // 3. Thanh điều hướng đáy (Bottom Navigation Bar)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  border: Border(
                    top: BorderSide(color: AppColors.borderHairline),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dãy chấm chỉ báo (Dots indicator) đặt riêng hàng trên, căn giữa thoáng đãng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        TutorialScreen.totalSteps,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.accent
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hàng nút điều hướng (Action Buttons Row)
                    Row(
                      children: [
                        // Nút Previous (chỉ hiển thị từ trang 2 trở đi)
                        if (_currentPage > 0) ...[
                          Expanded(
                            flex: 4,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(color: AppColors.borderSubtle),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _previousPage,
                              icon: const Icon(Icons.arrow_back_rounded, size: 18),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  l10n.tutorialButtonPrevious,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        // Nút Next hoặc Bắt đầu chơi (Start Playing)
                        Expanded(
                          flex: _currentPage > 0 ? 6 : 1,
                          child: isLastPage
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 6,
                                    shadowColor:
                                        AppColors.accent.withValues(alpha: 0.5),
                                  ),
                                  onPressed: _finishTutorial,
                                  icon: const Icon(Icons.play_arrow_rounded,
                                      size: 20),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      l10n.tutorialButtonStart,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _nextPage,
                                  icon: const Icon(Icons.arrow_forward_rounded,
                                      size: 18),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      l10n.tutorialButtonNext,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
