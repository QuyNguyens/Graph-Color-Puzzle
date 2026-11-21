import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Thanh công cụ thao tác người chơi (Undo, Hint, Restart).
/// Thiết kế hòa quyện với phong cách Midnight Slate / Deep Navy của màn chơi.
class GameActionBar extends StatelessWidget {
  const GameActionBar({
    super.key,
    required this.canUndo,
    this.undoCount = 0,
    this.hasUsedUndo = false,
    required this.canHint,
    required this.remainingHints,
    required this.onUndo,
    required this.onHint,
    required this.onRestart,
  });

  final bool canUndo;
  final int undoCount;
  final bool hasUsedUndo;
  final bool canHint;
  final int remainingHints;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0F172A), // Slate 900 base
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Nút Undo (Mỗi level tối đa 1 lần hoàn tác)
            _buildActionButton(
              context: context,
              icon: Icons.undo_rounded,
              label: hasUsedUndo ? l10n.actionUndoUsed : l10n.actionUndoAvailable,
              isEnabled: canUndo,
              onPressed: onUndo,
            ),

            // Nút Hint (Mỗi ngày 1 hint miễn phí, xem quảng cáo để nhận thêm)
            _buildActionButton(
              context: context,
              icon: remainingHints > 0 ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
              label: remainingHints > 1
                  ? l10n.actionHintMultiple(remainingHints)
                  : l10n.actionHintDaily(remainingHints),
              isEnabled: canHint,
              activeColor: remainingHints > 0 ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8),
              onPressed: onHint,
            ),

            // Nút Restart
            _buildActionButton(
              context: context,
              icon: Icons.refresh_rounded,
              label: l10n.actionRestart,
              isEnabled: true,
              onPressed: onRestart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onPressed,
    Color? activeColor,
  }) {
    final color = isEnabled
        ? (activeColor ?? Colors.white70)
        : const Color(0xFF475569); // Slate 600 disabled

    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
