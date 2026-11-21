import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../ads/application/ad_providers.dart';
import '../../application/energy_providers.dart';
import '../../domain/repositories/daily_energy_repository.dart';
import '../../domain/services/uuid_generator.dart';

/// Hộp thoại Nạp Năng lượng qua Rewarded Ads (EnergyAdDialog).
/// Tuân thủ chuẩn thẩm mỹ Midnight Slate / Deep Navy đồng bộ toàn hệ thống.
/// Cho phép người chơi xem trạng thái Năng lượng và xem video quảng cáo nhận +1 Energy.
class EnergyAdDialog extends ConsumerStatefulWidget {
  const EnergyAdDialog({
    super.key,
    this.onEnergyGranted,
    this.reasonMessage,
  });

  /// Callback được gọi ngay khi người chơi nhận thưởng Energy thành công
  final VoidCallback? onEnergyGranted;

  /// Thông điệp giải thích ngữ cảnh mở dialog (ví dụ: cần Energy để restart)
  final String? reasonMessage;

  /// Helper static method mở EnergyAdDialog tiện lợi từ bất kỳ BuildContext nào
  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onEnergyGranted,
    String? reasonMessage,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => EnergyAdDialog(
        onEnergyGranted: onEnergyGranted,
        reasonMessage: reasonMessage,
      ),
    );
  }

  @override
  ConsumerState<EnergyAdDialog> createState() => _EnergyAdDialogState();
}

class _EnergyAdDialogState extends ConsumerState<EnergyAdDialog> {
  bool _isWatching = false;
  bool _rewardSuccess = false;
  String? _errorMessage;

  Future<void> _handleWatchAd() async {
    if (_isWatching || _rewardSuccess) return;

    setState(() {
      _isWatching = true;
      _errorMessage = null;
    });

    final adService = ref.read(rewardedAdServiceProvider);

    final showResult = await adService.showRewardedAd(
      onUserEarnedReward: (amount, type) async {
        // Sinh UUID v4 nguyên tử cho lượt nhận thưởng (chống nhận thưởng trùng)
        final rewardId = UuidGenerator.generateV4();
        final claimResult = await ref
            .read(dailyEnergyNotifierProvider.notifier)
            .claimEnergyReward(amount: 1, rewardId: rewardId);

        if (claimResult.isSuccess && mounted) {
          setState(() {
            _rewardSuccess = true;
            _isWatching = false;
          });

          // Hiệu ứng hoàn thành trước khi tự động đóng dialog
          await Future<void>.delayed(const Duration(milliseconds: 700));
          if (mounted) {
            Navigator.of(context).pop(true);
            widget.onEnergyGranted?.call();
          }
        }
      },
      onAdFailedToShow: (error) {
        if (mounted) {
          setState(() {
            _isWatching = false;
            _errorMessage = error;
          });
        }
      },
      onAdDismissed: () {
        if (mounted && !_rewardSuccess) {
          setState(() {
            _isWatching = false;
          });
        }
      },
    );

    if (!showResult && mounted && !_rewardSuccess) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isWatching = false;
        _errorMessage ??= l10n.adNotReady;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentEnergy = ref.watch(dailyEnergyNotifierProvider);
    final maxEnergy = DailyEnergyRepository.maxDailyEnergy;
    final isFull = currentEnergy >= maxEnergy;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppColors.energy.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      elevation: 20,
      backgroundColor: const Color(0xFF1E293B), // Slate 800
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon năng lượng phát sáng
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2E1065),
                    border: Border.all(
                      color: AppColors.energy.withValues(alpha: 0.7),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.energy.withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFC084FC),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),

                // Tiêu đề
                Text(
                  l10n.energyAdDialogTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Huy hiệu hiển thị số Năng lượng hiện có
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFull
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.energy.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 18,
                        color: isFull ? const Color(0xFF34D399) : const Color(0xFFC084FC),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.gameOverEnergyBadge(currentEnergy, maxEnergy),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isFull ? const Color(0xFFA7F3D0) : const Color(0xFFE9D5FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Nội dung thông báo
                Text(
                  widget.reasonMessage ??
                      (currentEnergy <= 0
                          ? l10n.energyDefaultNeed(maxEnergy)
                          : (isFull
                              ? l10n.energyDefaultFull(maxEnergy)
                              : l10n.energyDefaultWatch(maxEnergy))),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFFCBD5E1),
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Thông báo giờ tự động reset (chống tràn width tuyệt đối)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.energyResetSchedule,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Thông báo lỗi nếu có
                if (_errorMessage != null) ...[
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
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFCA5A5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Hàng nút tương tác
                if (!isFull) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rewardSuccess
                            ? const Color(0xFF059669)
                            : const Color(0xFF7C3AED), // Purple 600
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      onPressed: _isWatching ? null : _handleWatchAd,
                      child: _isWatching
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.adLoading,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : (_rewardSuccess
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.energyRewardSuccess,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_circle_filled_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.buttonWatchAdEnergy,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nút về màn hình chính (Home)
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: Text(
                        l10n.buttonBackToHome,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      l10n.buttonLater,
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        l10n.buttonGotIt,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: Text(
                        l10n.buttonBackToHome,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
