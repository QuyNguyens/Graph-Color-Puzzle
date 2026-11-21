import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/daily_energy_local_datasource.dart';
import '../data/repositories/daily_energy_repository_impl.dart';
import '../domain/repositories/daily_energy_repository.dart';

export 'daily_energy_notifier.dart';
export '../domain/repositories/daily_energy_repository.dart';

/// Provider cung cấp Data Source cho Daily Energy.
final dailyEnergyLocalDataSourceProvider =
    Provider<DailyEnergyLocalDataSource>((ref) {
  return DailyEnergyLocalDataSource();
});

/// Provider cung cấp Repository quản lý hạn ngạch Năng lượng hằng ngày.
final dailyEnergyRepositoryProvider = Provider<DailyEnergyRepository>((ref) {
  final dataSource = ref.watch(dailyEnergyLocalDataSourceProvider);
  return DailyEnergyRepositoryImpl(localDataSource: dataSource);
});

