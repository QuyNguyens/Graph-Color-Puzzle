import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/graph_node.dart';
import '../../domain/entities/puzzle_color.dart';
import '../theme/puzzle_color_palette.dart';

/// Widget hiển thị đỉnh đồ thị theo phong cách tham chiếu Ball Lab Puzzle:
/// - Đỉnh chưa tô: Nền xanh đen đậm (#111827), viền ngọc lục bảo Emerald (#00C995),
///   phát sáng nhẹ (subtle green glow) và nhãn số màu trắng ngà êm dịu (#E5EDF5).
/// - Đỉnh đã tô: Giữ nguyên vẹn 100% màu sắc puzzle chủ đạo, không bị phủ viền xanh.
class GraphNodeWidget extends StatelessWidget {
  const GraphNodeWidget({
    super.key,
    required this.node,
    required this.onColorDropped,
    required this.onTap,
    this.isHinted = false,
    this.hintedColor,
  });

  final GraphNode node;
  final ValueChanged<PuzzleColor> onColorDropped;
  final VoidCallback onTap;
  final bool isHinted;
  final PuzzleColor? hintedColor;

  static const double nodeSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final currentColor = node.currentColor;
    final isLocked = node.isLocked;
    final isColored = node.isColored;
    final nodeColor = PuzzleColorPalette.getColor(currentColor);
    final hintUiColor = hintedColor != null
        ? PuzzleColorPalette.getColor(hintedColor)
        : const Color(0xFFFFB300);

    return DragTarget<PuzzleColor>(
      onWillAcceptWithDetails: (details) => !isLocked,
      onAcceptWithDetails: (details) => onColorDropped(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty && !isLocked;
        final hoveredColor = isHovered ? candidateData.first : null;

        // Xác định màu viền theo trạng thái
        Color borderColor;
        double borderWidth;
        if (isHovered) {
          borderColor = AppColors.nodeSelected; // #00E5AA
          borderWidth = 2.6;
        } else if (isHinted && !isColored) {
          borderColor = hintUiColor;
          borderWidth = 2.4;
        } else if (isLocked) {
          borderColor = const Color(0xFF334155);
          borderWidth = 2.2;
        } else if (isColored) {
          borderColor = Colors.black26; // Tự nhiên, không phủ emerald đè lên màu puzzle
          borderWidth = 1.8;
        } else {
          // Đỉnh chưa tô: Viền Emerald #00C995 thanh mảnh rõ nét
          borderColor = AppColors.nodeBorder;
          borderWidth = 1.8;
        }

        // Xác định hiệu ứng bóng / phát sáng (Glow)
        List<BoxShadow> shadows;
        if (isHinted && !isColored) {
          shadows = [
            BoxShadow(
              color: hintUiColor.withValues(alpha: 0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ];
        } else if (isHovered) {
          shadows = [
            BoxShadow(
              color: AppColors.nodeSelected.withValues(alpha: 0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ];
        } else if (!isColored && !isLocked) {
          // Tỏa sáng lục bảo rất nhẹ cho đỉnh chưa tô (Subtle Emerald Glow)
          shadows = [
            BoxShadow(
              color: AppColors.nodeBorder.withValues(alpha: 0.22),
              blurRadius: 6,
              spreadRadius: 0.5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ];
        } else {
          // Đỉnh đã tô màu hoặc bị khóa: Đổ bóng chiều sâu thông thường, không phát sáng lục
          shadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 3,
              offset: const Offset(0, 1.5),
            ),
          ];
        }

        final effectiveNodeBgColor = hoveredColor != null
            ? PuzzleColorPalette.getColor(hoveredColor).withValues(alpha: 0.95)
            : ((isHinted && !isColored)
                ? hintUiColor.withValues(alpha: 0.18)
                : nodeColor);

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isHovered ? nodeSize + 6 : nodeSize,
                height: isHovered ? nodeSize + 6 : nodeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveNodeBgColor,
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                  boxShadow: shadows,
                ),
                child: Center(
                  child: _buildNodeContent(
                    context,
                    currentColor,
                    hoveredColor,
                    isLocked,
                    hintUiColor,
                  ),
                ),
              ),

              // Huy hiệu bóng đèn gợi ý ở góc trên bên phải khi node đang mang trạng thái Hint
              if (isHinted && !isColored)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: hintUiColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.nodeUncolored, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNodeContent(
    BuildContext context,
    PuzzleColor? currentColor,
    PuzzleColor? hoveredColor,
    bool isLocked,
    Color hintUiColor,
  ) {
    final l10n = AppLocalizations.of(context);

    if (isLocked) {
      return const Icon(
        Icons.lock,
        size: 20,
        color: Color(0xFF94A3B8),
      );
    }

    final activeColor = currentColor ?? hoveredColor;

    if (activeColor != null) {
      return Text(
        activeColor.getLocalizedSymbol(l10n),
        style: TextStyle(
          color: PuzzleColorPalette.getContrastTextColor(activeColor),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Node chưa tô màu: Hiển thị ID với màu trắng ngà #E5EDF5 dịu mắt trên nền xanh đen #111827
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          node.id,
          style: TextStyle(
            color: isHinted ? hintUiColor : AppColors.nodeText,
            fontSize: 14,
            fontWeight: isHinted ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        if (isHinted && hintedColor != null)
          Text(
            hintedColor!.getLocalizedSymbol(l10n),
            style: TextStyle(
              color: hintUiColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
