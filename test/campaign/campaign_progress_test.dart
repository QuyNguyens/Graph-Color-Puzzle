import 'package:flutter_test/flutter_test.dart';
import 'package:graph_coloring/features/campaign/data/models/campaign_progress_dto.dart';
import 'package:graph_coloring/features/campaign/domain/entities/campaign_progress.dart';
import 'package:graph_coloring/features/campaign/domain/entities/level_progress.dart';
import 'package:graph_coloring/features/campaign/domain/services/star_rating_calculator.dart';

void main() {
  group('Campaign Progress & Star Rating Unit Tests', () {
    test('1. Người chơi mới: Chỉ Level 1 unlocked, 0 sao, 0 completed', () {
      final initial = CampaignProgress.initial();
      expect(initial.highestUnlockedLevelId, equals('c1_l01'));
      expect(initial.totalStars, equals(0));
      expect(initial.completedLevelsCount, equals(0));

      final lvl1 = initial.getLevelProgress('c1_l01');
      expect(lvl1.isUnlocked, isTrue);
      expect(lvl1.isCompleted, isFalse);
      expect(lvl1.bestStars, equals(0));

      // Level 2 mặc định khóa
      final lvl2 = initial.getLevelProgress('c1_l02');
      expect(lvl2.isUnlocked, isFalse);
      expect(lvl2.isCompleted, isFalse);
    });

    test('2. StarRatingCalculator: Tính sao chính xác theo GDD', () {
      // Chưa hoàn thành
      expect(
        StarRatingCalculator.calculateStars(isCompleted: false, hintsUsed: 0, mistakesCount: 0),
        equals(0),
      );
      // Hoàn thành có dùng hint
      expect(
        StarRatingCalculator.calculateStars(isCompleted: true, hintsUsed: 1, mistakesCount: 0),
        equals(1),
      );
      // Hoàn thành không hint nhưng có lỗi
      expect(
        StarRatingCalculator.calculateStars(isCompleted: true, hintsUsed: 0, mistakesCount: 2),
        equals(2),
      );
      // Hoàn thành không hint và 0 lỗi -> 3 sao
      expect(
        StarRatingCalculator.calculateStars(isCompleted: true, hintsUsed: 0, mistakesCount: 0),
        equals(3),
      );
    });

    test('3. Replay Level: Không làm giảm bestStars và không cộng dồn completed', () {
      var progress = CampaignProgress.initial();
      final map = Map<String, LevelProgress>.from(progress.progressMap);

      // Hoàn thành lần đầu: 1 sao
      map['c1_l01'] = const LevelProgress(
        levelId: 'c1_l01',
        isUnlocked: true,
        isCompleted: true,
        bestStars: 1,
      );
      progress = progress.copyWith(progressMap: map);
      expect(progress.totalStars, equals(1));
      expect(progress.completedLevelsCount, equals(1));

      // Chơi lại đạt 3 sao
      final starsAttempt2 = StarRatingCalculator.calculateStars(
        isCompleted: true,
        hintsUsed: 0,
        mistakesCount: 0,
      );
      final newBest = StarRatingCalculator.updateBestStars(
        currentBest: progress.getLevelProgress('c1_l01').bestStars,
        newlyEarned: starsAttempt2,
      );
      map['c1_l01'] = progress.getLevelProgress('c1_l01').copyWith(bestStars: newBest);
      progress = progress.copyWith(progressMap: map);
      expect(progress.totalStars, equals(3));
      expect(progress.completedLevelsCount, equals(1));

      // Chơi lại lần 3 chỉ đạt 1 sao -> bestStars vẫn giữ 3
      final starsAttempt3 = StarRatingCalculator.calculateStars(
        isCompleted: true,
        hintsUsed: 1,
        mistakesCount: 2,
      );
      final preservedBest = StarRatingCalculator.updateBestStars(
        currentBest: progress.getLevelProgress('c1_l01').bestStars,
        newlyEarned: starsAttempt3,
      );
      expect(preservedBest, equals(3));
      expect(progress.totalStars, equals(3));
    });

    test('4. DTO Serialization & Migration: Xử lý an toàn JSON thiếu field hoặc hỏng', () {
      final jsonV1 = {
        'version': 1,
        'highest_unlocked_level_id': 'c1_l05',
        'levels': {
          'c1_l01': {
            'level_id': 'c1_l01',
            'is_unlocked': true,
            'is_completed': true,
            'best_stars': 3,
          },
          'c1_l02': {
            'level_id': 'c1_l02',
            // thiếu is_unlocked, is_completed, best_stars
          },
        },
      };

      final dto = CampaignProgressDto.fromJson(jsonV1);
      final entity = dto.toEntity();

      expect(entity.highestUnlockedLevelId, equals('c1_l05'));
      expect(entity.getLevelProgress('c1_l01').bestStars, equals(3));
      expect(entity.getLevelProgress('c1_l02').isUnlocked, isFalse);
      expect(entity.getLevelProgress('c1_l02').bestStars, equals(0));
    });

    test('5. Level 180 boundary: Không mở khóa Level 181', () {
      final progress = CampaignProgress.initial();
      final map = Map<String, LevelProgress>.from(progress.progressMap);
      map['c6_l30'] = const LevelProgress(
        levelId: 'c6_l30',
        isUnlocked: true,
        isCompleted: true,
        bestStars: 3,
      );

      final updated = progress.copyWith(
        progressMap: map,
        highestUnlockedLevelId: 'c6_l30',
      );

      expect(updated.progressMap.containsKey('c6_l31'), isFalse);
      expect(updated.highestUnlockedLevelId, equals('c6_l30'));
    });
  });
}

