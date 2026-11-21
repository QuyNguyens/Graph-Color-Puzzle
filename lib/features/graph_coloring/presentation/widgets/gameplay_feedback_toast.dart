import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Các phân loại phản hồi gameplay phục vụ hiển thị Toast cao cấp
enum GameplayFeedbackType {
  invalidMove,
  noSolution,
  lockedNode,
  restrictedColor,
  hint,
  colorUnlocked,
  milestone,
  info,
}

/// Component thông báo phản hồi gameplay nổi phía trên bàn cờ (Top Floating Capsule).
/// Thiết kế tối giản, hiện đại, tương thích hoàn hảo với nền Midnight Slate.
/// Tuyệt đối không che khuất đồ thị hay các nút điều khiển, không chặn tương tác chạm (IgnorePointer).
class GameplayFeedbackToast extends StatelessWidget {
  const GameplayFeedbackToast({
    super.key,
    required this.message,
    required this.type,
  });

  final String? message;
  final GameplayFeedbackType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isVisible = message != null && message!.isNotEmpty;

    return IgnorePointer(
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, -0.35),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedScale(
            scale: isVisible ? 1.0 : 0.94,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xF50F172A), // Slate 900 obsidian translucent
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _getAccentColor().withValues(alpha: type == GameplayFeedbackType.noSolution ? 0.6 : 0.35),
                  width: type == GameplayFeedbackType.noSolution ? 1.5 : 1.0,
                ),
                boxShadow: _getShadows(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon badge nhỏ gọn
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getAccentColor().withValues(alpha: 0.16),
                    ),
                    child: Icon(
                      _getIconData(),
                      size: 15,
                      color: _getAccentColor(),
                    ),
                  ),
                  const SizedBox(width: 9),

                  // Tag cảnh báo đặc biệt cho lỗi phạt No Solution (-1 Lỗi)
                  if (type == GameplayFeedbackType.noSolution) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        l10n.mistakePenaltyTag,
                        style: const TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],

                  // Nội dung thông báo cô đọng, rõ ràng
                  Flexible(
                    child: Text(
                      message ?? '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: type == GameplayFeedbackType.noSolution
                            ? FontWeight.w700
                            : FontWeight.w600,
                        letterSpacing: 0.15,
                        decoration: TextDecoration.none,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getAccentColor() {
    switch (type) {
      case GameplayFeedbackType.noSolution:
        return const Color(0xFFEF4444); // Red 500 penalty
      case GameplayFeedbackType.invalidMove:
        return const Color(0xFFFB923C); // Orange 400
      case GameplayFeedbackType.lockedNode:
        return const Color(0xFF94A3B8); // Slate 400
      case GameplayFeedbackType.restrictedColor:
        return const Color(0xFFEC4899); // Pink 500
      case GameplayFeedbackType.hint:
        return const Color(0xFFFBBF24); // Amber 400
      case GameplayFeedbackType.colorUnlocked:
        return const Color(0xFF06B6D4); // Cyan 500
      case GameplayFeedbackType.milestone:
        return const Color(0xFFA855F7); // Purple 500
      case GameplayFeedbackType.info:
        return const Color(0xFF38BDF8); // Sky 400
    }
  }

  IconData _getIconData() {
    switch (type) {
      case GameplayFeedbackType.noSolution:
        return Icons.report_problem_rounded;
      case GameplayFeedbackType.invalidMove:
        return Icons.close_rounded;
      case GameplayFeedbackType.lockedNode:
        return Icons.lock_rounded;
      case GameplayFeedbackType.restrictedColor:
        return Icons.block_rounded;
      case GameplayFeedbackType.hint:
        return Icons.lightbulb_rounded;
      case GameplayFeedbackType.colorUnlocked:
        return Icons.palette_rounded;
      case GameplayFeedbackType.milestone:
        return Icons.emoji_events_rounded;
      case GameplayFeedbackType.info:
        return Icons.info_outline_rounded;
    }
  }

  List<BoxShadow> _getShadows() {
    final baseShadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 4),
    );

    if (type == GameplayFeedbackType.noSolution) {
      return [
        BoxShadow(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          blurRadius: 14,
          offset: const Offset(0, 2),
        ),
        baseShadow,
      ];
    }

    if (type == GameplayFeedbackType.hint) {
      return [
        BoxShadow(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        baseShadow,
      ];
    }

    if (type == GameplayFeedbackType.milestone) {
      return [
        BoxShadow(
          color: const Color(0xFFA855F7).withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        baseShadow,
      ];
    }

    return [baseShadow];
  }
}
