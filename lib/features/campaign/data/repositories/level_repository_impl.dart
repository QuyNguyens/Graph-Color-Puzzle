import '../../domain/entities/chapter_info.dart';
import '../../domain/entities/puzzle_level.dart';
import '../../domain/repositories/level_repository.dart';
import '../datasources/level_local_datasource.dart';

/// Implementation của LevelRepository sử dụng LevelLocalDataSource.
/// Tầng Data Layer, tuân thủ Clean Architecture.
class LevelRepositoryImpl implements LevelRepository {
  LevelRepositoryImpl({LevelLocalDataSource? localDataSource})
      : _dataSource = localDataSource ?? LevelLocalDataSourceImpl();

  final LevelLocalDataSource _dataSource;

  @override
  List<ChapterInfo> getChapters() => _dataSource.getChapters();

  @override
  ChapterInfo? getChapterById(int chapterId) =>
      _dataSource.getChapterById(chapterId);

  @override
  List<PuzzleLevel> getLevelsByChapter(int chapterId) =>
      _dataSource.getLevelsByChapter(chapterId);

  @override
  PuzzleLevel? getLevelById(String id) => _dataSource.getLevelById(id);

  @override
  PuzzleLevel? getLevelByOverallIndex(int overallIndex) =>
      _dataSource.getLevelByOverallIndex(overallIndex);

  @override
  List<PuzzleLevel> getAllLevels() => _dataSource.getAllLevels();
}

