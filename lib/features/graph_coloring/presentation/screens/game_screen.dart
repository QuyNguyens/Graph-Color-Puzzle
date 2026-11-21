import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../campaign/application/campaign_providers.dart';
import '../../../campaign/application/level_providers.dart';
import '../../../campaign/domain/entities/puzzle_level.dart';
import '../../../campaign/domain/services/level_title_localizer.dart';
import '../../../campaign/presentation/screens/level_selection_screen.dart';
import '../../../campaign/presentation/widgets/victory_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../application/energy_providers.dart';
import '../../application/game_controller.dart';
import '../../application/hint_providers.dart';
import '../../application/line_settings_providers.dart';
import '../widgets/color_inventory_bar.dart';
import '../widgets/colored_lines_ad_dialog.dart';
import '../widgets/energy_ad_dialog.dart';
import '../widgets/game_action_bar.dart';
import '../widgets/game_background_widget.dart';
import '../widgets/game_header.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/gameplay_feedback_toast.dart';
import '../widgets/graph_board.dart';
import '../widgets/hint_ad_dialog.dart';
import '../../../../core/audio/game_audio_service.dart';

/// Màn hình gameplay chính hoàn chỉnh với Mistake System, Undo, Restart và Local Persistence.
/// Thiết kế giao diện Midnight Slate / Deep Navy cao cấp, giúp các đỉnh màu bão hòa tỏa sáng nổi bật.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  String? _feedbackMessage;
  GameplayFeedbackType _feedbackType = GameplayFeedbackType.invalidMove;
  Timer? _feedbackTimer;
  String? _lastDeductedAttemptId;
  bool _hasMovedColorWithLinesOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentLevel = ref.read(gameControllerProvider).currentLevel;
        _checkLevelGreeting(currentLevel);
      }
    });
  }

  void _checkLevelGreeting(PuzzleLevel? level) {
    if (level == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    if (level.chapterId == 1) {
      if (level.levelNumber == 5) {
        _triggerFeedback(l10n.greetingYellowUnlocked, GameplayFeedbackType.colorUnlocked);
      } else if (level.levelNumber == 10) {
        _triggerFeedback(l10n.greetingGreenUnlocked, GameplayFeedbackType.colorUnlocked);
      } else if (level.levelNumber == 20) {
        _triggerFeedback(l10n.greetingPurpleUnlocked, GameplayFeedbackType.colorUnlocked);
      } else if (level.levelNumber == 30) {
        _triggerFeedback(l10n.greetingChapter1Finale, GameplayFeedbackType.milestone);
      }
    }
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  GameplayFeedbackType _classifyFeedback(String message) {
    if (message.startsWith('Gợi ý') || message.startsWith('Hint')) {
      return GameplayFeedbackType.hint;
    }
    if (message.contains('khóa') || message.contains('locked')) {
      return GameplayFeedbackType.lockedNode;
    }
    if (message.contains('không cho phép') || message.contains('not allow')) {
      return GameplayFeedbackType.restrictedColor;
    }
    if (message.contains('Không còn cách hoàn thành') ||
        message.contains('hết lượt lỗi') ||
        message.contains('ngõ cụt') ||
        message.contains('Dead end')) {
      return GameplayFeedbackType.noSolution;
    }
    if (message.contains('Hai node') ||
        message.contains('cùng màu') ||
        message.contains('trong kho') ||
        message.contains('same color') ||
        message.contains('inventory')) {
      return GameplayFeedbackType.invalidMove;
    }
    if (message.contains('màu mới') || message.contains('Mở khóa màu') || message.contains('unlocked')) {
      return GameplayFeedbackType.colorUnlocked;
    }
    if (message.contains('cột mốc') || message.contains('Milestone') || message.contains('Chung Kết') || message.contains('Finale')) {
      return GameplayFeedbackType.milestone;
    }
    return GameplayFeedbackType.info;
  }

  void _triggerFeedback(String rawMessage, GameplayFeedbackType type) {
    _feedbackTimer?.cancel();
    String displayMessage = rawMessage;
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      displayMessage = _localizeFeedbackMessage(l10n, rawMessage, type);
    }
    setState(() {
      _feedbackMessage = displayMessage;
      _feedbackType = type;
    });
    final durationMs = type == GameplayFeedbackType.hint
        ? 2500
        : (type == GameplayFeedbackType.noSolution ? 2200 : 1800);
    _feedbackTimer = Timer(Duration(milliseconds: durationMs), () {
      if (mounted) {
        setState(() {
          _feedbackMessage = null;
        });
      }
    });
  }

  String _localizeFeedbackMessage(AppLocalizations l10n, String rawMessage, GameplayFeedbackType type) {
    if (type == GameplayFeedbackType.noSolution) {
      return l10n.errorDeadEndNoSolution;
    }
    if (rawMessage.startsWith('Gợi ý:')) {
      final match = RegExp(r'node\s+(\S+)\s+với\s+màu\s+(.*)', caseSensitive: false).firstMatch(rawMessage);
      if (match != null) {
        final node = match.group(1) ?? '';
        final color = match.group(2) ?? '';
        return l10n.hintSuggestion(color, node);
      }
    }
    if (rawMessage.contains('Hai node') || rawMessage.contains('cùng màu')) {
      return l10n.errorAdjacentSameColor;
    }
    if (rawMessage.contains('đã bị khóa màu') || rawMessage.contains('khóa cố định')) {
      return l10n.errorLockedNode;
    }
    if (rawMessage.contains('dùng hết số lượng') || rawMessage.contains('out of stock')) {
      final match = RegExp(r'Màu\s+(.*?)\s+đã dùng hết', caseSensitive: false).firstMatch(rawMessage);
      final colorStr = match?.group(1) ?? '';
      return l10n.errorInventoryEmpty(colorStr);
    }
    if (rawMessage.contains('Không thể xóa màu')) {
      return l10n.errorCannotEraseLocked;
    }
    if (rawMessage.contains('tối đa 1 lần')) {
      return l10n.errorUndoLimit;
    }
    if (rawMessage.contains('Bàn cờ đã thay đổi')) {
      return l10n.hintBoardChanged;
    }
    if (rawMessage.contains('Không tìm thấy lời giải')) {
      return l10n.hintNoSolutionFound;
    }
    if (rawMessage.contains('Không còn cách hoàn thành')) {
      return l10n.errorNoSolutionWithChoice;
    }
    if (rawMessage.contains('Đã hồi sinh')) {
      return l10n.revivedSuccessToast;
    }
    if (rawMessage.contains('Đã làm mới bàn cờ')) {
      return l10n.boardRefreshed;
    }
    if (rawMessage.contains('Đã nhận +1 Gợi ý')) {
      return l10n.hintReceivedToast;
    }
    return rawMessage;
  }

  void _navigateBackToCurrentChapter(BuildContext context) {
    final currentLevel = ref.read(gameControllerProvider).currentLevel;
    if (currentLevel != null) {
      final levelRepo = ref.read(levelRepositoryProvider);
      final currentChapter = levelRepo.getChapters().firstWhere(
            (c) => c.id == currentLevel.chapterId,
            orElse: () => levelRepo.getChapters().first,
          );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LevelSelectionScreen(chapter: currentChapter),
        ),
        (route) => route.isFirst,
      );
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final remainingHints = ref.watch(dailyHintNotifierProvider);
    final remainingEnergy = ref.watch(dailyEnergyNotifierProvider);
    final isColoredLinesOn = ref.watch(coloredLinesSettingsProvider);
    final remainingLinesQuota = ref.watch(dailyColoredLinesNotifierProvider);
    final l10n = AppLocalizations.of(context);

    // Lắng nghe sự kiện GameOver, Hoàn thành ván chơi và Error Message
    ref.listen(gameControllerProvider, (previous, next) {
      if (next.attemptId != previous?.attemptId) {
        _hasMovedColorWithLinesOn = false;
      }

      // Xử lý trừ lượt Line màu khi màn chơi hoàn thành hoặc thất bại
      if ((next.isCompleted && !(previous?.isCompleted ?? false)) ||
          (next.isGameOver && !(previous?.isGameOver ?? false))) {
        _handleLevelEndLineQuota(next.attemptId);
      }
      // 1. Kích hoạt Victory Dialog khi ván chơi hoàn thành
      if (next.isCompleted && !(previous?.isCompleted ?? false)) {
        final currentLevel = next.currentLevel;
        final levelRepo = ref.read(levelRepositoryProvider);
        final campaignState = ref.read(campaignNotifierProvider);

        PuzzleLevel? nextLevel;
        bool isNextUnlocked = false;

        if (currentLevel != null && currentLevel.overallIndex < 180) {
          nextLevel =
              levelRepo.getLevelByOverallIndex(currentLevel.overallIndex + 1);
          if (nextLevel != null) {
            // Vừa hoàn thành level hiện tại, màn tiếp theo lập tức mở khóa
            isNextUnlocked = true;
          }
        }

        final bestStars = currentLevel != null
            ? campaignState.getLevelStars(currentLevel.id)
            : (next.earnedStars ?? 1);

        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => VictoryDialog(
            level: currentLevel,
            earnedStars: next.earnedStars ?? 1,
            bestStars: bestStars > (next.earnedStars ?? 1)
                ? bestStars
                : (next.earnedStars ?? 1),
            nextLevel: nextLevel,
            isNextUnlocked: isNextUnlocked,
            remainingEnergy: remainingEnergy,
            onNextLevel: () {
              ref.read(gameAudioServiceProvider).playVictoryAdvance(attemptId: next.attemptId);
              Navigator.of(dialogContext).pop();
              if (nextLevel != null) {
                controller.loadLevel(nextLevel);
              }
            },
            onReplay: () {
              Navigator.of(dialogContext).pop();
              controller.replayLevel();
            },
            onBackToCampaign: () {
              Navigator.of(dialogContext).pop();
              _navigateBackToCurrentChapter(context);
            },
          ),
        );
      }

      // 2. Kích hoạt GameOver Dialog khi ván chơi chuyển sang GameOver
      if (next.isGameOver && !(previous?.isGameOver ?? false)) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => GameOverDialog(
            remainingEnergy: remainingEnergy,
            onRestart: controller.retryFailedAttempt,
            hasUsedContinue: next.hasUsedContinue,
            onContinueSuccess: () {
              final l10n = AppLocalizations.of(context);
              controller.continueSessionWithExtraMistakes();
              _triggerFeedback(
                l10n.revivedSuccessToast,
                GameplayFeedbackType.info,
              );
            },
            onBackToCampaign: () {
              Navigator.of(dialogCtx).pop();
              _navigateBackToCurrentChapter(context);
            },
          ),
        );
      }

      // 3. Hiển thị Gameplay Feedback Toast nổi phía trên bàn cờ
      if (next.errorMessage != null &&
          !next.isGameOver &&
          next.errorMessage != previous?.errorMessage) {
        final feedbackType = _classifyFeedback(next.errorMessage!);
        _triggerFeedback(next.errorMessage!, feedbackType);
        controller.clearErrorMessage();
      }

      // 4. Lắng nghe thay đổi level để hiển thị thông báo cột mốc
      if (next.currentLevel != null &&
          next.currentLevel?.id != previous?.currentLevel?.id) {
        _checkLevelGreeting(next.currentLevel);
      }
    });

    // Tránh flash giao diện level rỗng trong tích tắc trước khi SharedPreferences khôi phục xong
    if (gameState.isInitializing) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: GameBackgroundWidget(
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF38BDF8),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateBackToCurrentChapter(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Slate 900
        appBar: GameHeader(
          title: gameState.currentLevel != null
              ? '${l10n.chapterShort(gameState.currentLevel!.chapterId)} - ${l10n.levelTitleWithIndex(gameState.currentLevel!.levelNumber, LevelTitleLocalizer.getTitle(gameState.currentLevel!, Localizations.localeOf(context)))}'
              : (gameState.levelTitle.isNotEmpty
                  ? gameState.levelTitle
                  : l10n.levelHeaderFallback),
          remainingMistakes: gameState.remainingMistakes,
          isColoredLinesOn: isColoredLinesOn,
          remainingLinesQuota: remainingLinesQuota,
          onToggleColoredLines: () => _handleToggleColoredLines(
            context,
            isColoredLinesOn,
            remainingLinesQuota,
          ),
          onRestartPressed: () =>
              _confirmRestart(context, controller, remainingEnergy),
          onBackPressed: () => _navigateBackToCurrentChapter(context),
        ),
      body: Stack(
        children: [
          GameBackgroundWidget(
            child: Column(
              children: [
                // Banner trạng thái
                if (gameState.isCompleted)
                  _buildVictoryBanner(
                      context, controller, gameState.earnedStars, l10n)
                else if (gameState.isGameOver)
                  _buildGameOverBanner(context, controller, l10n)
                else
                  _buildInstructionsBanner(l10n),

                // Khu vực bàn cờ đồ thị (tự động khóa khi hoàn thành hoặc game over)
                Expanded(
                  child: IgnorePointer(
                    ignoring: !gameState.isPlaying,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.boardSurface.withValues(alpha: 0.75), // Subtle deep navy (#152238)
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.graphEdge.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: GraphBoard(
                          graph: gameState.graph,
                          hintedNodeId: gameState.hintedNodeId,
                          hintedColor: gameState.hintedColor,
                          attemptId: gameState.attemptId,
                          historyLength: gameState.undoHistory.length,
                          lastMove: gameState.undoHistory.isNotEmpty
                              ? gameState.undoHistory.last
                              : null,
                          isInitializing: gameState.isInitializing,
                          showColoredLines: isColoredLinesOn,
                          onColorDropped: (nodeId, color) {
                            if (ref.read(coloredLinesSettingsProvider)) {
                              _hasMovedColorWithLinesOn = true;
                            }
                            controller.applyColorMove(
                                nodeId: nodeId, color: color);
                          },
                          onNodeTapped: (nodeId) {
                            if (gameState.selectedColor != null) {
                              final node = gameState.graph.getNode(nodeId);
                              if (node != null &&
                                  !node.isLocked &&
                                  ref.read(coloredLinesSettingsProvider)) {
                                _hasMovedColorWithLinesOn = true;
                              }
                              controller.applyColorMove(
                                nodeId: nodeId,
                                color: gameState.selectedColor!,
                              );
                            } else {
                              controller.removeColor(nodeId);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Thanh Color Inventory
                AbsorbPointer(
                  absorbing: !gameState.isPlaying,
                  child: ColorInventoryBar(
                    inventory: gameState.inventory,
                    selectedColor: gameState.selectedColor,
                    onColorSelected: (color) {
                      controller.selectColor(color);
                    },
                  ),
                ),

                // Thanh công cụ người chơi (Undo, Hint, Restart)
                GameActionBar(
                  canUndo: gameState.canUndo,
                  hasUsedUndo: gameState.hasUsedUndo,
                  canHint: gameState.isPlaying,
                  remainingHints: remainingHints,
                  onUndo: controller.undo,
                  onHint: () =>
                      _handleHintPressed(context, controller, remainingHints),
                  onRestart: () =>
                      _confirmRestart(context, controller, remainingEnergy),
                ),
              ],
            ),
          ),

          // Top Floating Gameplay Feedback Toast (tối giản, nổi phía trên, không che đồ thị hay nút điều khiển)
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Center(
                child: GameplayFeedbackToast(
                  message: _feedbackMessage,
                  type: _feedbackType,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  /// Xử lý khi nhấn nút Gợi ý: Nếu còn gợi ý thì dùng, nếu hết thì mở HintAdDialog xem quảng cáo
  void _handleHintPressed(
    BuildContext context,
    GameController controller,
    int remainingHints,
  ) {
    if (remainingHints > 0) {
      controller.requestHint();
    } else {
      HintAdDialog.show(
        context,
        onHintGranted: () {
          final l10n = AppLocalizations.of(context);
          controller.requestHint();
          _triggerFeedback(
            l10n.hintReceivedToast,
            GameplayFeedbackType.info,
          );
        },
      );
    }
  }

  /// Xử lý khi nhấn nút bật/tắt Line màu:
  /// - Nếu đang bật: Tắt bình thường (không trừ lượt nếu chưa di chuyển màu vào node).
  /// - Nếu đang tắt: Kiểm tra còn lượt trong ngày (> 0) thì bật; nếu hết lượt (0) thì hiển thị ColoredLinesAdDialog.
  void _handleToggleColoredLines(
    BuildContext context,
    bool isColoredLinesOn,
    int remainingLinesQuota,
  ) {
    if (isColoredLinesOn) {
      ref.read(coloredLinesSettingsProvider.notifier).setEnabled(false);
    } else {
      if (remainingLinesQuota > 0) {
        ref.read(coloredLinesSettingsProvider.notifier).setEnabled(true);
      } else {
        ColoredLinesAdDialog.show(context);
      }
    }
  }

  /// Trừ 1 lượt sử dụng Line màu khi hoàn thành hoặc thua màn chơi nếu ván này có thực sự dùng Line màu.
  /// Nếu người chơi chỉ lỡ bật rồi tắt trước khi di chuyển màu vào node, hoàn toàn KHÔNG trừ lượt.
  Future<void> _handleLevelEndLineQuota(String attemptId) async {
    final isLinesOnNow = ref.read(coloredLinesSettingsProvider);
    final hasActuallyUsedLines = _hasMovedColorWithLinesOn || isLinesOnNow;

    if (hasActuallyUsedLines && _lastDeductedAttemptId != attemptId) {
      _lastDeductedAttemptId = attemptId;
      final remaining = await ref
          .read(dailyColoredLinesNotifierProvider.notifier)
          .consumeTurn();

      if (remaining != null && remaining <= 0) {
        // Tự động tắt Line màu khi hết lượt và báo toast
        await ref
            .read(coloredLinesSettingsProvider.notifier)
            .setEnabled(false);
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          _triggerFeedback(
            l10n.coloredLinesExhaustedToast,
            GameplayFeedbackType.info,
          );
        }
      }
    }
  }

  /// Hiển thị hộp thoại xác nhận trước khi Restart hoặc mời xem Ad nạp Energy nếu đã hết.
  /// Nếu đồ thị đang ở trạng thái ban đầu (chưa đặt quả bóng nào, hoặc đã hoàn tác hết),
  /// hoàn toàn không trừ Energy, không hiển thị dialog và làm mới bàn cờ ngay lập tức.
  void _confirmRestart(
    BuildContext context,
    GameController controller,
    int energy,
  ) {
    final gameState = ref.read(gameControllerProvider);
    final l10n = AppLocalizations.of(context);

    // Nếu chưa đặt quả bóng nào trên đồ thị (hoặc đã hoàn tác hết về trạng thái ban đầu):
    // Không trừ Energy, không hiển thị dialog, làm mới bàn cờ miễn phí.
    if (!gameState.hasPlacedBalls) {
      controller.replayLevel();
      _triggerFeedback(l10n.boardRefreshed, GameplayFeedbackType.info);
      return;
    }

    // Chỉ khi đã đặt ít nhất một quả bóng vào đồ thị mới hiển thị dialog
    if (energy <= 0) {
      EnergyAdDialog.show(
        context,
        reasonMessage: l10n.energyReasonRestart,
        onEnergyGranted: () {
          controller.restartActiveAttempt();
        },
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.restartConfirmTitle, style: const TextStyle(color: Colors.white)),
          content: Text(
            l10n.restartConfirmContent(energy, DailyEnergyRepository.maxDailyEnergy),
            style: const TextStyle(color: Color(0xFFCBD5E1)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(l10n.buttonCancel, style: const TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final res = await controller.restartActiveAttempt();
                if (res == AttemptLifecycleResult.insufficientEnergy && context.mounted) {
                  EnergyAdDialog.show(
                    context,
                    reasonMessage: l10n.energyReasonRestart,
                    onEnergyGranted: () {
                      controller.restartActiveAttempt();
                    },
                  );
                }
              },
              child: Text(l10n.buttonRestartCost),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionsBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_rounded, size: 20, color: Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.instructionsBannerText,
              style: const TextStyle(
                fontSize: 12.0,
                color: Color(0xFFCBD5E1),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryBanner(
    BuildContext context,
    GameController controller,
    int? earnedStars,
    AppLocalizations l10n,
  ) {
    final starsText = earnedStars != null ? ' ${'⭐' * earnedStars}' : '';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF34D399),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.levelCompletedBannerTitle(starsText),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  earnedStars != null
                      ? l10n.levelCompletedBannerDescEarned(earnedStars)
                      : l10n.levelCompletedBannerDescGeneric,
                  style: const TextStyle(
                    color: Color(0xFFA7F3D0),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: controller.replayLevel,
            child: Text(l10n.buttonReplay),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverBanner(
    BuildContext context,
    GameController controller,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF450A0A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cancel_rounded,
            color: Color(0xFFF87171),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.gameOverBannerText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final energy = ref.read(dailyEnergyNotifierProvider);
              if (energy <= 0) {
                EnergyAdDialog.show(
                  context,
                  reasonMessage: l10n.energyReasonRetry,
                  onEnergyGranted: () {
                    controller.retryFailedAttempt();
                  },
                );
                return;
              }
              controller.retryFailedAttempt();
            },
            child: Text(l10n.buttonReplay),
          ),
        ],
      ),
    );
  }
}
