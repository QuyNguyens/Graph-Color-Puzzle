import '../entities/chapter_info.dart';
import '../entities/puzzle_level.dart';

/// Interface cho việc truy xuất thông tin Chapter và Level trong Campaign.
/// Tầng Domain thuần Dart, không phụ thuộc UI hay external packages.
abstract class LevelRepository {
  /// Lấy danh sách toàn bộ 6 Chapter trong Campaign.
  List<ChapterInfo> getChapters();

  /// Lấy thông tin chi tiết một Chapter theo ID (1..6).
  ChapterInfo? getChapterById(int chapterId);

  /// Lấy danh sách 30 màn chơi của một Chapter cụ thể.
  List<PuzzleLevel> getLevelsByChapter(int chapterId);

  /// Lấy thông tin một màn chơi theo levelId (ví dụ: 'c1_l01').
  PuzzleLevel? getLevelById(String id);

  /// Lấy thông tin một màn chơi theo số thứ tự tổng thể (1..180).
  PuzzleLevel? getLevelByOverallIndex(int overallIndex);

  /// Lấy toàn bộ 180 màn chơi của Campaign.
  List<PuzzleLevel> getAllLevels();
}

