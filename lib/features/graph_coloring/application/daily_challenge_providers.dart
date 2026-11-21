import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/daily_challenge_local_datasource.dart';
import '../data/datasources/pending_completion_local_datasource.dart';
import '../data/repositories/daily_challenge_repository_impl.dart';
import '../domain/repositories/daily_challenge_repository.dart';

/// Provider cung cấp DailyChallengeLocalDataSource.
final dailyChallengeLocalDataSourceProvider =
    Provider<DailyChallengeLocalDataSource>((ref) {
  return DailyChallengeLocalDataSource();
});

/// Provider cung cấp PendingCompletionLocalDataSource (Outbox).
final pendingCompletionLocalDataSourceProvider =
    Provider<PendingCompletionLocalDataSource>((ref) {
  return PendingCompletionLocalDataSource();
});

/// Provider cung cấp DailyChallengeRepository.
final dailyChallengeRepositoryProvider =
    Provider<DailyChallengeRepository>((ref) {
  return DailyChallengeRepositoryImpl(
    localDataSource: ref.watch(dailyChallengeLocalDataSourceProvider),
  );
});

