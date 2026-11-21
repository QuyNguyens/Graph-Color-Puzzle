import 'package:flutter/material.dart';

import '../../../../core/constants/app_metadata.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import 'game_icon_widget.dart';

/// Hộp thoại thông tin trò chơi (Game Information Dialog).
/// Hiển thị Icon, Tên game, Phiên bản, Mô tả tóm tắt,
/// và hỗ trợ xem giấy phép nguồn mở (Flutter LicensePage) cũng như Đặt lại tiến trình.
class GameInfoDialog extends StatelessWidget {
  const GameInfoDialog({
    super.key,
    required this.onResetProgress,
    this.onOpenTutorial,
  });

  final VoidCallback onResetProgress;
  final VoidCallback? onOpenTutorial;

  /// Phương thức tĩnh tiện ích để hiển thị GameInfoDialog.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onResetProgress,
    VoidCallback? onOpenTutorial,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => GameInfoDialog(
        onResetProgress: onResetProgress,
        onOpenTutorial: onOpenTutorial,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.borderSubtle, width: 1.2),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Game Icon
            const GameIconWidget(size: 64),
            const SizedBox(height: 14),

            // 2. Full Game Name
            const Text(
              AppMetadata.appName,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),

            // 3. Current Application Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.backgroundPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: const Text(
                AppMetadata.displayVersion,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Short Game Description
            Text(
              l10n.appDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFCBD5E1),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // 5. Nút "Hướng dẫn chơi" (How to Play)
            if (onOpenTutorial != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.16),
                    foregroundColor: AppColors.accent,
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onOpenTutorial,
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(
                    l10n.howToPlayButton,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 6. Nút "Xem giấy phép nguồn mở" (View Licenses)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.policy_outlined, size: 18),
                label: Text(
                  l10n.buttonViewLicenses,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  // Mở màn hình LicensePage tích hợp của Flutter
                  showLicensePage(
                    context: context,
                    applicationName: AppMetadata.appName,
                    applicationVersion: AppMetadata.fullVersion,
                    applicationIcon: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: GameIconWidget(size: 48),
                    ),
                    applicationLegalese: l10n.appLegalese,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Nút "Đặt lại toàn bộ tiến trình" (Reset Progress)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF87171), // Red 400
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(
                  l10n.resetProgressButton,
                  style: const TextStyle(fontSize: 12.5),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onResetProgress();
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.buttonClose,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
