import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../ads/application/ad_providers.dart';
import '../../application/daily_hint_notifier.dart';
import '../../domain/repositories/daily_hint_repository.dart';

/// Hộp thoại Nhận thêm Gợi ý qua Rewarded Ads (HintAdDialog).
/// Tuân thủ chuẩn thẩm mỹ Midnight Slate / Deep Navy đồng bộ toàn hệ thống.
/// Mỗi ngày có 1 lượt Gợi ý miễn phí. Khi hết có thể xem quảng cáo để nhận thêm +1 Gợi ý.
class HintAdDialog extends ConsumerStatefulWidget {
  const HintAdDialog({
    super.key,
    this.onHintGranted,
    this.reasonMessage,
  });

  /// Callback được gọi ngay khi người chơi nhận thưởng Hint thành công
  final VoidCallback? onHintGranted;

  /// Thông điệp giải thích ngữ cảnh mở dialog (nếu có)
  final String? reasonMessage;

  /// Helper static method mở HintAdDialog tiện lợi từ bất kỳ BuildContext nào
  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onHintGranted,
    String? reasonMessage,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => HintAdDialog(
        onHintGranted: onHintGranted,
        reasonMessage: reasonMessage,
      ),
    );
  }

  @override
  ConsumerState<HintAdDialog> createState() => _HintAdDialogState();
}

class _HintAdDialogState extends ConsumerState<HintAdDialog> {
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
        // Cộng +1 lượt Hint vào hạn ngạch
        await ref
            .read(dailyHintNotifierProvider.notifier)
            .grantHintReward(amount: 1);

        if (mounted) {
          setState(() {
            _rewardSuccess = true;
            _isWatching = false;
          });

          // Hiệu ứng hoàn thành trước khi tự động đóng dialog
          await Future<void>.delayed(const Duration(milliseconds: 700));
          if (mounted) {
            Navigator.of(context).pop(true);
            widget.onHintGranted?.call();
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
    final currentHints = ref.watch(dailyHintNotifierProvider);
    const maxFree = DailyHintRepository.maxDailyHints;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
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
                // Icon bóng đèn gợi ý phát sáng
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF451A03), // Amber 950 base
                    border: Border.all(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.7),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: Color(0xFFFBBF24),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),

                // Tiêu đề
                Text(
                  l10n.hintAdDialogTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Huy hiệu hiển thị số Gợi ý hiện có
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: currentHints > 0
                          ? const Color(0xFFFBBF24).withValues(alpha: 0.6)
                          : const Color(0xFF64748B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentHints > 0
                            ? Icons.lightbulb_rounded
                            : Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: currentHints > 0
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.hintCountBadge(currentHints),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: currentHints > 0
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Nội dung giải thích
                Text(
                  widget.reasonMessage ??
                      (currentHints <= 0
                          ? l10n.hintDefaultNeed(maxFree)
                          : l10n.hintDefaultWatch),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFFCBD5E1),
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Thông báo lỗi nếu có
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFFCA5A5),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Thông báo thành công
                if (_rewardSuccess) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF4ADE80),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.hintRewardSuccess,
                          style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Nút Xem quảng cáo (+1 Gợi ý)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_isWatching || _rewardSuccess) ? null : _handleWatchAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706), // Amber 600
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF334155),
                      disabledForegroundColor: const Color(0xFF64748B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    child: _isWatching
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.adLoading,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_filled_rounded, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                l10n.buttonWatchAdHint,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Nút Để sau
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: TextButton(
                    onPressed: _isWatching ? null : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.buttonLater,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
