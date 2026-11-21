import 'package:flutter_test/flutter_test.dart';
import 'package:graph_coloring/features/campaign/data/repositories/level_repository_impl.dart';
import 'package:graph_coloring/features/campaign/domain/services/level_validator.dart';

void main() {
  group('LevelValidator & Campaign Pipeline Tests', () {
    late final LevelRepositoryImpl repository;
    late final LevelValidator validator;

    setUpAll(() {
      repository = LevelRepositoryImpl();
      validator = const LevelValidator();
    });

    test('Xác thực toàn bộ 180 handcrafted levels không có bất kỳ lỗi nào', () {
      final allLevels = repository.getAllLevels();
      expect(allLevels.length, equals(180));

      final report = validator.validateAll(allLevels);
      expect(report.isValid, isTrue, reason: report.errors.join('\n'));
      expect(report.errors, isEmpty);
      expect(report.totalLevels, equals(180));
    });

    test('Kiểm tra cấu trúc 6 Chapters trong Repository', () {
      final chapters = repository.getChapters();
      expect(chapters.length, equals(6));

      for (int i = 1; i <= 6; i++) {
        final chapter = repository.getChapterById(i);
        expect(chapter, isNotNull);
        expect(chapter!.id, equals(i));
        expect(chapter.levelCount, equals(30));
        expect(chapter.startOverallIndex, equals((i - 1) * 30 + 1));
        expect(chapter.endOverallIndex, equals(i * 30));

        final chapterLevels = repository.getLevelsByChapter(i);
        expect(chapterLevels.length, equals(30));
        for (final lvl in chapterLevels) {
          expect(lvl.chapterId, equals(i));
        }
      }
    });

    test('Kiểm tra tra cứu Level theo ID và theo overallIndex', () {
      final level1 = repository.getLevelById('c1_l01');
      expect(level1, isNotNull);
      expect(level1!.overallIndex, equals(1));
      expect(level1.levelNumber, equals(1));

      final level180 = repository.getLevelByOverallIndex(180);
      expect(level180, isNotNull);
      expect(level180!.id, equals('c6_l30'));
      expect(level180.chapterId, equals(6));
      expect(level180.levelNumber, equals(30));

      // ID không tồn tại
      expect(repository.getLevelById('non_existent'), isNull);
      expect(repository.getLevelByOverallIndex(999), isNull);
    });

    test('Kiểm tra đặc trưng từng Chapter theo GDD', () {
      // Chapter 1: 0 locked, 0 restricted, 2 colors
      final ch1Levels = repository.getLevelsByChapter(1);
      for (final lvl in ch1Levels) {
        expect(lvl.targetInventory.length, equals(2));
        expect(lvl.initialGraph.nodes.values.any((n) => n.isLocked), isFalse);
        expect(lvl.initialGraph.nodes.values.any((n) => n.restrictedColors != null), isFalse);
      }

      // Chapter 3: Có locked nodes, 0 restricted
      final ch3Levels = repository.getLevelsByChapter(3);
      for (final lvl in ch3Levels) {
        expect(lvl.initialGraph.nodes.values.any((n) => n.isLocked), isTrue);
        expect(lvl.initialGraph.nodes.values.any((n) => n.restrictedColors != null), isFalse);
      }

      // Chapter 5: Có restricted colors và locked nodes
      final ch5Levels = repository.getLevelsByChapter(5);
      for (final lvl in ch5Levels) {
        expect(lvl.initialGraph.nodes.values.any((n) => n.restrictedColors != null), isTrue);
      }

      // Chapter 6: Master network kết hợp
      final ch6Levels = repository.getLevelsByChapter(6);
      for (final lvl in ch6Levels) {
        expect(lvl.initialGraph.nodes.values.any((n) => n.isLocked), isTrue);
        expect(lvl.initialGraph.nodes.values.any((n) => n.restrictedColors != null), isTrue);
      }
    });
  });
}

