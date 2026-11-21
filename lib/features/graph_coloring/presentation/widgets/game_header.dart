import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Header hiển thị thông tin màn chơi, bộ đếm lỗi và nút thao tác nhanh.
/// Thiết kế hòa quyện với phong cách Midnight Slate / Deep Navy của màn chơi.
class GameHeader extends StatelessWidget implements PreferredSizeWidget {
  const GameHeader({
    super.key,
    required this.title,
    required this.remainingMistakes,
    required this.onRestartPressed,
    this.onBackPressed,
    this.isColoredLinesOn = true,
    this.remainingLinesQuota = 5,
    this.onToggleColoredLines,
  });

  final String title;
  final int remainingMistakes;
  final VoidCallback onRestartPressed;
  final VoidCallback? onBackPressed;
  final bool isColoredLinesOn;
  final int remainingLinesQuota;
  final VoidCallback? onToggleColoredLines;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      leading: onBackPressed != null
          ? IconButton(
              tooltip: l10n.backTooltip,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
              onPressed: onBackPressed,
            )
          : (canPop
              ? IconButton(
                  tooltip: l10n.backTooltip,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: false,
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      elevation: 0,
      actions: [
        // Huy hiệu hiển thị số lượt lỗi còn lại
        _buildMistakesBadge(context, l10n),
        const SizedBox(width: 4),

        // Nút bật/tắt đường nối màu (Colored Lines Toggle)
        if (onToggleColoredLines != null)
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
                color: isColoredLinesOn
                    ? const Color(0xFF38BDF8)
                    : Colors.white38,
                size: 20,
              ),
              onPressed: onToggleColoredLines,
            ),
          ),

        // Nút chơi lại kèm xác nhận
        IconButton(
          tooltip: l10n.restartFreeTooltip,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          onPressed: onRestartPressed,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMistakesBadge(BuildContext context, AppLocalizations l10n) {
    Color badgeColor;
    Color textColor;
    IconData badgeIcon;

    if (remainingMistakes >= 2) {
      badgeColor = const Color(0xFF064E3B).withValues(alpha: 0.65); // Dark Emerald
      textColor = const Color(0xFF4ADE80); // Emerald 400
      badgeIcon = Icons.shield_outlined;
    } else if (remainingMistakes == 1) {
      badgeColor = const Color(0xFF78350F).withValues(alpha: 0.65); // Dark Amber
      textColor = const Color(0xFFFBBF24); // Amber 400
      badgeIcon = Icons.warning_amber_rounded;
    } else {
      badgeColor = const Color(0xFF7F1D1D).withValues(alpha: 0.65); // Dark Red
      textColor = const Color(0xFFF87171); // Red 400
      badgeIcon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: textColor),
          const SizedBox(width: 5),
          Text(
            l10n.mistakesBadge(remainingMistakes),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
