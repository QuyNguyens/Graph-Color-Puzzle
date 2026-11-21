import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/campaign_progress_local_datasource.dart';
import '../data/repositories/campaign_progress_repository_impl.dart';
import '../domain/repositories/campaign_progress_repository.dart';
import 'campaign_notifier.dart';
import 'campaign_state.dart';

/// Provider cung cấp CampaignProgressLocalDataSource.
final campaignProgressLocalDataSourceProvider =
    Provider<CampaignProgressLocalDataSource>((ref) {
  return CampaignProgressLocalDataSourceImpl();
});

/// Provider cung cấp CampaignProgressRepository.
final campaignProgressRepositoryProvider =
    Provider<CampaignProgressRepository>((ref) {
  final dataSource = ref.watch(campaignProgressLocalDataSourceProvider);
  return CampaignProgressRepositoryImpl(localDataSource: dataSource);
});

/// Provider quản lý toàn bộ trạng thái và tiến trình Campaign.
final campaignNotifierProvider =
    NotifierProvider<CampaignNotifier, CampaignState>(CampaignNotifier.new);

