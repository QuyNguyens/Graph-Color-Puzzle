import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// Thẻ nội dung của từng bước hướng dẫn (Tutorial Step Card).
/// Thiết kế thanh lịch, có scroll an toàn cho màn hình nhỏ,
/// hiệu ứng viền ánh sáng tinh tế và phân cấp kiểu chữ chuẩn mực.
class TutorialStepCard extends StatelessWidget {
  const TutorialStepCard({
    super.key,
    required this.stepNumber,
    required this.totalSteps,
    required this.badgeTitle,
    required this.title,
    required this.description,
    required this.illustration,
    this.accentColor = AppColors.accent,
    this.icon,
  });

  final int stepNumber;
  final int totalSteps;
  final String badgeTitle;
  final String title;
  final String description;
  final Widget illustration;
  final Color accentColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Huy hiệu danh mục bước
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  badgeTitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Tiêu đề chính của bước
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.2,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),

          // 3. Khung hình minh họa trực quan (Illustration Canvas)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 140, maxHeight: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131D33), // Deep Midnight Navy
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: illustration,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Khung mô tả chi tiết quy tắc / luật chơi (Description Card)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.borderHairline,
                width: 1.0,
              ),
            ),
            child: _buildFormattedDescription(description),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedDescription(String text) {
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          return const SizedBox(height: 6);
        }

        final isBullet = trimmed.startsWith('•') || trimmed.startsWith('-');
        final content = isBullet ? trimmed.substring(1).trim() : trimmed;

        if (isBullet) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFCBD5E1), // Slate 300
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            trimmed,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFFCBD5E1),
              height: 1.45,
            ),
          ),
        );
      }).toList(),
    );
  }
}
