import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/level_local_datasource.dart';
import '../data/repositories/level_repository_impl.dart';
import '../domain/repositories/level_repository.dart';

/// Provider cung cấp LevelLocalDataSource.
final levelLocalDataSourceProvider = Provider<LevelLocalDataSource>((ref) {
  return LevelLocalDataSourceImpl();
});

/// Provider cung cấp LevelRepository.
final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  final dataSource = ref.watch(levelLocalDataSourceProvider);
  return LevelRepositoryImpl(localDataSource: dataSource);
});

