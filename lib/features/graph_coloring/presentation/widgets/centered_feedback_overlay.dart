import 'package:flutter/material.dart';

/// Phân loại chi tiết thông điệp phản hồi trong gameplay
enum FeedbackType {
  info,
  warning,
  invalidMove,
  noSolution,
  locked,
  restricted,
  hint,
}

/// Overlay thông báo phản hồi nổi ở trung tâm phía trên bàn cờ.
/// Thay thế hoàn toàn SnackBar đáy màn hình, mang lại cảm giác thanh thoát, hiện đại
/// và tuyệt đối không chặn tương tác chạm của người chơi (IgnorePointer).
class CenteredFeedbackOverlay extends StatelessWidget {
  const CenteredFeedbackOverlay({
    super.key,
    required this.message,
    this.type = FeedbackType.warning,
  });

  final String? message;
  final FeedbackType type;

  @override
  Widget build(BuildContext context) {
    final isVisible = message != null && message!.isNotEmpty;

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: isVisible ? 1.0 : 0.88,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Align(
            alignment: const Alignment(0, -0.45),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: _getSurfaceColor(),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _getBorderColor(),
                  width: type == FeedbackType.noSolution ? 1.8 : 1.2,
                ),
                boxShadow: _getBoxShadows(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIcon(),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: type == FeedbackType.noSolution
                            ? FontWeight.bold
                            : FontWeight.w600,
                        letterSpacing: 0.2,
                        decoration: TextDecoration.none,
                      ),
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

  Color _getSurfaceColor() {
    switch (type) {
      case FeedbackType.noSolution:
        return const Color(0xF52A121E); // Deep wine/ruby slate
      case FeedbackType.hint:
        return const Color(0xF21F2417); // Deep warm amber slate
      case FeedbackType.info:
        return const Color(0xFA0F172A); // Deep navy slate
      case FeedbackType.locked:
      case FeedbackType.restricted:
      case FeedbackType.invalidMove:
      case FeedbackType.warning:
        return const Color(0xEE1E293B); // Slate 800 frosted
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case FeedbackType.noSolution:
        return const Color(0xFFF43F5E).withValues(alpha: 0.65); // Rose 500
      case FeedbackType.hint:
        return const Color(0xFFFACC15).withValues(alpha: 0.55); // Amber 400
      case FeedbackType.restricted:
        return const Color(0xFFFB7185).withValues(alpha: 0.45); // Rose 400
      case FeedbackType.invalidMove:
        return const Color(0xFFFB923C).withValues(alpha: 0.45); // Orange 400
      case FeedbackType.warning:
        return const Color(0xFFFBBF24).withValues(alpha: 0.45); // Amber 400
      case FeedbackType.locked:
        return const Color(0xFF94A3B8).withValues(alpha: 0.45); // Slate 400
      case FeedbackType.info:
        return const Color(0xFF38BDF8).withValues(alpha: 0.45); // Sky 400
    }
  }

  List<BoxShadow> _getBoxShadows() {
    if (type == FeedbackType.noSolution) {
      return [
        BoxShadow(
          color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
          blurRadius: 20,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
    }
    if (type == FeedbackType.hint) {
      return [
        BoxShadow(
          color: const Color(0xFFFACC15).withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];
  }

  Widget _buildIcon() {
    switch (type) {
      case FeedbackType.noSolution:
        return const Icon(
          Icons.report_problem_rounded,
          color: Color(0xFFF43F5E), // Rose 500
          size: 22,
        );
      case FeedbackType.hint:
        return const Icon(
          Icons.lightbulb_rounded,
          color: Color(0xFFFACC15), // Gold 400
          size: 20,
        );
      case FeedbackType.locked:
        return const Icon(
          Icons.lock_rounded,
          color: Color(0xFFCBD5E1), // Slate 300
          size: 20,
        );
      case FeedbackType.restricted:
        return const Icon(
          Icons.do_not_disturb_on_rounded,
          color: Color(0xFFFB7185), // Rose 400
          size: 20,
        );
      case FeedbackType.invalidMove:
        return const Icon(
          Icons.highlight_off_rounded,
          color: Color(0xFFFB923C), // Orange 400
          size: 20,
        );
      case FeedbackType.warning:
        return const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFFBBF24), // Amber 400
          size: 20,
        );
      case FeedbackType.info:
        return const Icon(
          Icons.info_outline_rounded,
          color: Color(0xFF38BDF8), // Sky 400
          size: 20,
        );
    }
  }
}
