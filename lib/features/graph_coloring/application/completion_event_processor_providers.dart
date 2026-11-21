import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../campaign/application/campaign_providers.dart';
import 'completion_event_processor.dart';
import 'daily_challenge_providers.dart';
import 'game_controller.dart';

/// Provider cung cấp CompletionEventProcessor (Singleton trong ProviderScope).
final completionEventProcessorProvider =
    Provider<CompletionEventProcessor>((ref) {
  return CompletionEventProcessor(
    sessionRepository: ref.watch(gameSessionRepositoryProvider),
    outboxDataSource: ref.watch(pendingCompletionLocalDataSourceProvider),
    challengeRepository: ref.watch(dailyChallengeRepositoryProvider),
    campaignNotifier: ref.watch(campaignNotifierProvider.notifier),
  );
});

