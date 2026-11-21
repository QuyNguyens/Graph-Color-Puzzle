import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/daily_hint_local_datasource.dart';
import '../data/repositories/daily_hint_repository_impl.dart';
import '../domain/repositories/daily_hint_repository.dart';
import '../domain/services/hint_service.dart';

export 'daily_hint_notifier.dart';

/// Provider cung cấp Data Source cho Daily Hint.
final dailyHintLocalDataSourceProvider =
    Provider<DailyHintLocalDataSource>((ref) {
  return DailyHintLocalDataSource();
});

/// Provider cung cấp Repository quản lý hạn ngạch Hint hằng ngày.
final dailyHintRepositoryProvider = Provider<DailyHintRepository>((ref) {
  final dataSource = ref.watch(dailyHintLocalDataSourceProvider);
  return DailyHintRepositoryImpl(localDataSource: dataSource);
});

/// Provider cung cấp HintService.
final hintServiceProvider = Provider<HintService>((ref) {
  return const HintService();
});
