import '../../domain/entities/chapter_info.dart';
import '../../domain/entities/puzzle_level.dart';
import '../levels/chapter_1_levels.dart';
import '../levels/chapter_2_levels.dart';
import '../levels/chapter_3_levels.dart';
import '../levels/chapter_4_levels.dart';
import '../levels/chapter_5_levels.dart';
import '../levels/chapter_6_levels.dart';

/// Interface trừu tượng cho nguồn dữ liệu level cục bộ.
/// Tầng Data thuần Dart.
abstract class LevelLocalDataSource {
  List<ChapterInfo> getChapters();
  ChapterInfo? getChapterById(int chapterId);
  List<PuzzleLevel> getAllLevels();
  List<PuzzleLevel> getLevelsByChapter(int chapterId);
  PuzzleLevel? getLevelById(String id);
  PuzzleLevel? getLevelByOverallIndex(int overallIndex);
}

/// Implementation của LevelLocalDataSource với bộ nhớ đệm O(1) tra cứu.
class LevelLocalDataSourceImpl implements LevelLocalDataSource {
  LevelLocalDataSourceImpl() {
    _initIndexes();
  }

  static const List<ChapterInfo> _chapters = [
    ChapterInfo(
      id: 1,
      title: 'First Connection',
      subtitle: 'Làm quen với luật kề và cách tô màu cơ bản',
      levelCount: 30,
      startOverallIndex: 1,
      endOverallIndex: 30,
    ),
    ChapterInfo(
      id: 2,
      title: 'Color Balance',
      subtitle: 'Quản lý kho màu chính xác và tránh ngõ cụt',
      levelCount: 30,
      startOverallIndex: 31,
      endOverallIndex: 60,
    ),
    ChapterInfo(
      id: 3,
      title: 'Locked Connections',
      subtitle: 'Tư duy chiến thuật xoay quanh các Node cố định',
      levelCount: 30,
      startOverallIndex: 61,
      endOverallIndex: 90,
    ),
    ChapterInfo(
      id: 4,
      title: 'Complex Network',
      subtitle: 'Mạng lưới kết nối phức tạp và điểm nghẽn logic',
      levelCount: 30,
      startOverallIndex: 91,
      endOverallIndex: 120,
    ),
    ChapterInfo(
      id: 5,
      title: 'Restricted Choices',
      subtitle: 'Ràng buộc tập màu giới hạn theo từng Node',
      levelCount: 30,
      startOverallIndex: 121,
      endOverallIndex: 150,
    ),
    ChapterInfo(
      id: 6,
      title: 'Master Network',
      subtitle: 'Thử thách đỉnh cao kết hợp toàn bộ cơ chế',
      levelCount: 30,
      startOverallIndex: 151,
      endOverallIndex: 180,
    ),
  ];

  late final List<PuzzleLevel> _allLevels;
  late final Map<String, PuzzleLevel> _levelsById;
  late final Map<int, PuzzleLevel> _levelsByOverallIndex;
  late final Map<int, List<PuzzleLevel>> _levelsByChapter;
  late final Map<int, ChapterInfo> _chaptersById;

  void _initIndexes() {
    _allLevels = [
      ...chapter1Levels,
      ...chapter2Levels,
      ...chapter3Levels,
      ...chapter4Levels,
      ...chapter5Levels,
      ...chapter6Levels,
    ];

    _levelsById = {for (final level in _allLevels) level.id: level};
    _levelsByOverallIndex = {
      for (final level in _allLevels) level.overallIndex: level
    };

    _levelsByChapter = {
      1: List.unmodifiable(chapter1Levels),
      2: List.unmodifiable(chapter2Levels),
      3: List.unmodifiable(chapter3Levels),
      4: List.unmodifiable(chapter4Levels),
      5: List.unmodifiable(chapter5Levels),
      6: List.unmodifiable(chapter6Levels),
    };

    _chaptersById = {for (final ch in _chapters) ch.id: ch};
  }

  @override
  List<ChapterInfo> getChapters() => List.unmodifiable(_chapters);

  @override
  ChapterInfo? getChapterById(int chapterId) => _chaptersById[chapterId];

  @override
  List<PuzzleLevel> getAllLevels() => List.unmodifiable(_allLevels);

  @override
  List<PuzzleLevel> getLevelsByChapter(int chapterId) =>
      _levelsByChapter[chapterId] ?? const [];

  @override
  PuzzleLevel? getLevelById(String id) => _levelsById[id];

  @override
  PuzzleLevel? getLevelByOverallIndex(int overallIndex) =>
      _levelsByOverallIndex[overallIndex];
}

