import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/services/rewarded_ad_service.dart';

/// Triển khai dịch vụ Rewarded Ads AdMob cho Flutter.
/// Hỗ trợ cả Native Android/iOS (qua Google Mobile Ads SDK) và
/// Fallback giả lập (Simulated Mode) khi chạy trên Windows Desktop hoặc môi trường Test.
class AdMobRewardedAdService implements RewardedAdService {
  AdMobRewardedAdService({
    String? androidAdUnitId,
    String? iosAdUnitId,
  })  : _androidAdUnitId = androidAdUnitId ?? _defaultAndroidTestAdUnitId,
        _iosAdUnitId = iosAdUnitId ?? _defaultIosTestAdUnitId;

  // Mã Test chính thức của Google AdMob cho Rewarded Video Ads
  static const String _defaultAndroidTestAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _defaultIosTestAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  final String _androidAdUnitId;
  final String _iosAdUnitId;

  RewardedAd? _rewardedAd;
  RewardedAdState _state = RewardedAdState.initial;
  final _stateController = StreamController<RewardedAdState>.broadcast();

  bool _isInitialized = false;
  bool _isLoading = false;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String get _adUnitId {
    if (Platform.isAndroid) return _androidAdUnitId;
    if (Platform.isIOS) return _iosAdUnitId;
    return _androidAdUnitId;
  }

  @override
  RewardedAdState get state => _state;

  @override
  Stream<RewardedAdState> get stateStream => _stateController.stream;

  @override
  bool get isAdLoaded => _state == RewardedAdState.loaded && (_rewardedAd != null || !_isMobile);

  void _updateState(RewardedAdState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (_isMobile) {
      try {
        await MobileAds.instance.initialize();
        _isInitialized = true;
        // Tự động nạp trước (preload) quảng cáo đầu tiên sau khi khởi tạo SDK
        loadRewardedAd();
      } catch (e) {
        debugPrint('[AdMob] Lỗi khởi tạo MobileAds SDK: $e');
        _isInitialized = true;
      }
    } else {
      // Desktop / Web / Tests: Đánh dấu sẵn sàng ở chế độ giả lập
      debugPrint('[AdMob] Chạy ở chế độ Giả lập (Desktop/Web/Test)');
      _isInitialized = true;
      loadRewardedAd();
    }
  }

  @override
  Future<void> loadRewardedAd() async {
    if (_isLoading || _state == RewardedAdState.loaded) return;
    _isLoading = true;
    _updateState(RewardedAdState.loading);

    if (!_isMobile) {
      // Giả lập thời gian nạp quảng cáo trên desktop
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _isLoading = false;
      _updateState(RewardedAdState.loaded);
      return;
    }

    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoading = false;
            _updateState(RewardedAdState.loaded);

            // Cấu hình sự kiện vòng đời hiển thị quảng cáo
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _rewardedAd = null;
                _updateState(RewardedAdState.initial);
                // Preload video tiếp theo ngay khi video vừa đóng
                loadRewardedAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('[AdMob] Lỗi hiển thị full screen: $error');
                ad.dispose();
                _rewardedAd = null;
                _updateState(RewardedAdState.failed);
                // Thử nạp lại
                loadRewardedAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdMob] Lỗi nạp Rewarded Ad: $error');
            _rewardedAd = null;
            _isLoading = false;
            _updateState(RewardedAdState.failed);
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdMob] Ngoại lệ khi nạp Rewarded Ad: $e');
      _isLoading = false;
      _updateState(RewardedAdState.failed);
    }
  }

  @override
  Future<bool> showRewardedAd({
    required void Function(int amount, String type) onUserEarnedReward,
    void Function(String error)? onAdFailedToShow,
    void Function()? onAdDismissed,
  }) async {
    // 1. Kiểm tra nếu đang chạy ở chế độ giả lập (Desktop/Test)
    if (!_isMobile) {
      _updateState(RewardedAdState.showing);
      // Giả lập thời lượng xem video quảng cáo
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      // Kích hoạt nhận thưởng chính xác 1 lần
      onUserEarnedReward(1, 'energy');
      _updateState(RewardedAdState.initial);
      onAdDismissed?.call();
      // Preload tiếp
      loadRewardedAd();
      return true;
    }

    // 2. Chế độ thiết bị thực (Android / iOS)
    if (_rewardedAd == null) {
      // Nếu chưa có sẵn, thử nạp lại và báo lỗi
      loadRewardedAd();
      onAdFailedToShow?.call('Quảng cáo chưa sẵn sàng. Vui lòng thử lại sau vài giây.');
      return false;
    }

    _updateState(RewardedAdState.showing);
    bool rewardGranted = false;

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          if (!rewardGranted) {
            rewardGranted = true;
            onUserEarnedReward(reward.amount.toInt(), reward.type);
          }
        },
      );
      return true;
    } catch (e) {
      debugPrint('[AdMob] Ngoại lệ khi hiển thị quảng cáo: $e');
      _updateState(RewardedAdState.failed);
      onAdFailedToShow?.call('Không thể hiển thị quảng cáo: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _stateController.close();
  }
}
