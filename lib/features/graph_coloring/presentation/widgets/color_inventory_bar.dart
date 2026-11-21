import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/color_inventory.dart';
import '../../domain/entities/puzzle_color.dart';
import '../theme/puzzle_color_palette.dart';

/// Thanh hiển thị kho màu (Color Inventory), hỗ trợ cả Draggable (kéo thả) và Tap-to-select.
/// Tinh chỉnh theo Phase UI-1: Loại bỏ nhãn tên màu chữ, bảo toàn swatch màu và số lượng bóng còn lại,
/// phân bổ độ rộng đồng đều (equal width) và chiều cao nhất quán cho toàn bộ các ô màu.
class ColorInventoryBar extends StatelessWidget {
  const ColorInventoryBar({
    super.key,
    required this.inventory,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final ColorInventory inventory;
  final PuzzleColor? selectedColor;
  final ValueChanged<PuzzleColor> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final colors = inventory.targetCounts.keys.toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: colors.map((color) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildColorItem(context, color),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getColorName(AppLocalizations l10n, PuzzleColor color) {
    return color.getLocalizedName(l10n);
  }

  Widget _buildColorItem(BuildContext context, PuzzleColor color) {
    final l10n = AppLocalizations.of(context);
    final remaining = inventory.getRemaining(color);
    final isAvailable = inventory.isAvailable(color);
    final isSelected = selectedColor == color;
    final colorHex = PuzzleColorPalette.getColor(color);
    final colorName = _getColorName(l10n, color);

    final chipWidget = Semantics(
      label: '$colorName: $remaining',
      selected: isSelected,
      enabled: isAvailable,
      button: true,
      child: GestureDetector(
        onTap: isAvailable ? () => onColorSelected(color) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF334155) // Slate 700 selected
                : (isAvailable
                    ? const Color(0xFF0F172A).withValues(alpha: 0.85) // Slate 900
                    : const Color(0xFF0F172A).withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorHex
                  : (isAvailable
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05)),
              width: isSelected ? 2.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorHex.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Vòng tròn hiển thị màu (Color Indicator / Swatch)
              Opacity(
                opacity: isAvailable ? 1.0 : 0.35,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorHex,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorHex.withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: PuzzleColorPalette.getContrastTextColor(color),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              // 2. Huy hiệu hiển thị số lượng bóng còn lại (Remaining Ball Count)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: remaining == 0
                      ? const Color(0xFF064E3B) // Emerald 900 (trạng thái đã hoàn thành số lượng)
                      : (isAvailable
                          ? const Color(0xFF334155) // Slate 700
                          : const Color(0xFF7F1D1D).withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$remaining',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: remaining == 0
                        ? const Color(0xFF4ADE80)
                        : (isAvailable ? Colors.white : const Color(0xFFFCA5A5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isAvailable) {
      return chipWidget;
    }

    // Nếu còn số lượng, cho phép kéo thả (Draggable)
    return Draggable<PuzzleColor>(
      data: color,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorHex.withValues(alpha: 0.95),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: colorHex.withValues(alpha: 0.5),
                blurRadius: 14,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$remaining',
              style: TextStyle(
                color: PuzzleColorPalette.getContrastTextColor(color),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: chipWidget,
      ),
      child: chipWidget,
    );
  }
}
