import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../ads/application/ad_providers.dart';
import '../../application/energy_providers.dart';
import '../../domain/repositories/daily_energy_repository.dart';
import 'energy_ad_dialog.dart';

/// Dialog hiển thị khi người chơi hết lượt lỗi cho phép (GameOver).
/// Tuân thủ GDD 4.4, 8.2 và Phase D4/D5:
/// - Thông điệp nhẹ nhàng, phối màu chuẩn Midnight Slate / Deep Navy.
/// - Cung cấp tùy chọn xem Rewarded Ad "Hồi sinh (+2 🛡️)" nếu chưa từng hồi sinh trong attempt này.
/// - Cho phép Thử lại (Retry) hoàn toàn miễn phí (0 Energy).
/// - Hiển thị Energy badge tương tác chạm để nạp thêm.
class GameOverDialog extends ConsumerStatefulWidget {
  const GameOverDialog({
    super.key,
    required this.remainingEnergy,
    required this.onRestart,
    this.hasUsedContinue = false,
    this.onContinueSuccess,
    this.onBackToCampaign,
  });

  final int remainingEnergy;
  final VoidCallback onRestart;
  final bool hasUsedContinue;
  final VoidCallback? onContinueSuccess;
  final VoidCallback? onBackToCampaign;

  @override
  ConsumerState<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends ConsumerState<GameOverDialog> {
  bool _isWatchingAd = false;
  String? _adErrorMessage;

  Future<void> _handleReviveWithAd() async {
    if (_isWatchingAd || widget.hasUsedContinue) return;

    setState(() {
      _isWatchingAd = true;
      _adErrorMessage = null;
    });

    final adService = ref.read(rewardedAdServiceProvider);

    final showResult = await adService.showRewardedAd(
      onUserEarnedReward: (amount, type) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onContinueSuccess?.call();
        }
      },
      onAdFailedToShow: (error) {
        if (mounted) {
          setState(() {
            _isWatchingAd = false;
            _adErrorMessage = error;
          });
        }
      },
      onAdDismissed: () {
        if (mounted) {
          setState(() {
            _isWatchingAd = false;
          });
        }
      },
    );

    if (!showResult && mounted) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isWatchingAd = false;
        _adErrorMessage ??= l10n.adNotReady;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentEnergy = ref.watch(dailyEnergyNotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.error.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      elevation: 16,
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon cảnh báo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF450A0A),
                border: Border.all(
                  color: AppColors.error,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFF87171),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            Text(
              l10n.gameOverTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Nội dung mô tả
            Text(
              l10n.gameOverMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Huy hiệu hiển thị Năng lượng (chạm để mở EnergyAdDialog nạp thêm)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                EnergyAdDialog.show(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1065).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.energy.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: Color(0xFFC084FC),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.gameOverEnergyBadge(currentEnergy, DailyEnergyRepository.maxDailyEnergy),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE9D5FF),
                      ),
                    ),
                    if (currentEnergy < DailyEnergyRepository.maxDailyEnergy) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.gameOverRechargeTag,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Hiển thị lỗi xem quảng cáo nếu có
            if (_adErrorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF450A0A).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _adErrorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFCA5A5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Nút Hồi sinh (+2 Lượt lỗi) qua Rewarded Ad (chỉ hiển thị nếu chưa dùng Continue)
            if (!widget.hasUsedContinue) ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669), // Emerald 600
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon: _isWatchingAd
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shield_rounded, size: 20),
                  label: Text(
                    _isWatchingAd ? l10n.adLoading : l10n.buttonReviveWithShields,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: _isWatchingAd ? null : _handleReviveWithAd,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Nút Thử lại màn này (Retry miễn phí 0 Energy sau Game Over)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(
                  l10n.buttonRetryLevel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  final energy = ref.read(dailyEnergyNotifierProvider);
                  if (energy <= 0) {
                    Navigator.of(context).pop();
                    EnergyAdDialog.show(
                      context,
                      reasonMessage: l10n.energyReasonRetry,
                      onEnergyGranted: () {
                        widget.onRestart();
                      },
                    );
                    return;
                  }
                  Navigator.of(context).pop();
                  widget.onRestart();
                },
              ),
            ),
            const SizedBox(height: 10),

            // Nút Quay về Campaign
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (widget.onBackToCampaign != null) {
                    widget.onBackToCampaign!();
                  } else if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(l10n.buttonBackToCampaign),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
