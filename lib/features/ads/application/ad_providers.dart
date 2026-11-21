import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/admob_rewarded_ad_service.dart';
import '../domain/services/rewarded_ad_service.dart';

export '../domain/services/rewarded_ad_service.dart';

/// Provider cung cấp Singleton RewardedAdService cho toàn ứng dụng.
final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  final service = AdMobRewardedAdService();
  // Khởi tạo SDK và preload quảng cáo ngay khi provider được đọc
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// StreamProvider theo dõi trạng thái tải/hiển thị của Rewarded Ad.
final rewardedAdStateProvider = StreamProvider<RewardedAdState>((ref) {
  final service = ref.watch(rewardedAdServiceProvider);
  return service.stateStream;
});
