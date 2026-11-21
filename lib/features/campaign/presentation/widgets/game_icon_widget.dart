import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// Widget hiển thị biểu tượng đại diện chính thức của trò chơi Graph Coloring.
/// Tải hình ảnh biểu tượng chính thức (app_icon.png) với góc bo mềm mại,
/// viền ánh sáng cyan tinh tế và fallback an toàn nếu chưa tải xong.
class GameIconWidget extends StatelessWidget {
  const GameIconWidget({
    super.key,
    this.size = 28,
  });

  final double size;

  static const String iconAsset = 'assets/icon/app_icon.png';

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.24);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.25),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          iconAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF111827),
            child: Icon(
              Icons.hub_rounded,
              size: size * 0.62,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}
