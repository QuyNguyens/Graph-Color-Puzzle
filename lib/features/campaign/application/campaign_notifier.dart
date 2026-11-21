import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../graph_coloring/application/game_controller.dart';
import '../domain/entities/campaign_progress.dart';
import '../domain/entities/level_progress.dart';
import '../domain/repositories/campaign_progress_repository.dart';
import '../domain/repositories/level_repository.dart';
import '../domain/services/star_rating_calculator.dart';
import 'campaign_providers.dart';
import 'campaign_state.dart';
import 'level_providers.dart';

/// Notifier quản lý tiến trình Campaign theo Riverpod 3 Notifier API.
class CampaignNotifier extends Notifier<CampaignState> {
  late final CampaignProgressRepository _progressRepository;
  late final LevelRepository _levelRepository;

  Future<void>? _initFuture;
  Future<LevelCompletionResult?> _recordQueue = Future.value(null);

  @override
  CampaignState build() {
    _progressRepository = ref.watch(campaignProgressRepositoryProvider);
    _levelRepository = ref.watch(levelRepositoryProvider);

    // Tự động khôi phục tiến trình từ SharedPreferences
    _initFuture = _loadInitialProgress();

    return CampaignState(
      progress: CampaignProgress.initial(),
      isLoading: true,
    );
  }

  Future<void> _loadInitialProgress() async {
    try {
      final progress = await _progressRepository.loadProgress();
      state = state.copyWith(
        progress: progress,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể nạp tiến trình Campaign: $e',
      );
    }
  }

  /// Ghi nhận kết quả khi người chơi hoàn thành một màn chơi.
  /// Sử dụng FIFO Queue để xử lý tuần tự, chống race condition khi hoàn thành dồn dập.
  Future<LevelCompletionResult?> recordLevelCompletion({
    required String levelId,
    required int mistakesCount,
    int hintsUsed = 0,
  }) {
    _recordQueue = _recordQueue.then((_) => _executeRecordLevelCompletion(
          levelId: levelId,
          mistakesCount: mistakesCount,
          hintsUsed: hintsUsed,
        ));
    return _recordQueue;
  }

  /// Thực thi ghi nhận level completion với đầy đủ kiểm tra bảo mật luồng Unlock và Persistence.
  Future<LevelCompletionResult?> _executeRecordLevelCompletion({
    required String levelId,
    required int mistakesCount,
    int hintsUsed = 0,
  }) async {
    // 1. Chờ nạp xong tiến trình ban đầu nếu đang load
    if (_initFuture != null) {
      await _initFuture;
    }

    final level = _levelRepository.getLevelById(levelId);

    // Tính toán số sao đạt được dựa trên GDD
    final earnedStars = StarRatingCalculator.calculateStars(
      isCompleted: true,
      hintsUsed: hintsUsed,
      mistakesCount: mistakesCount,
    );

    // Xử lý mock level (chỉ chấp nhận nếu đúng currentLevelId của GameController)
    if (level == null) {
      if (levelId == GameController.currentLevelId) {
        final mockResult = LevelCompletionResult(
          levelId: levelId,
          earnedStars: earnedStars,
          bestStars: earnedStars,
          isNewBest: true,
          isFirstCompletion: true,
        );
        state = state.copyWith(lastCompletionResult: mockResult);
        return mockResult;
      }
      // Level không tồn tại -> Từ chối ghi nhận
      return null;
    }

    // 2. Kiểm tra giới hạn hợp lệ của level trong Campaign (1–180)
    if (level.overallIndex < 1 || level.overallIndex > 180) {
      return null;
    }

    final currentProgress = state.progress.getLevelProgress(levelId);

    // 3. Bảo mật luồng Unlock: Không cho phép hoàn thành màn chơi chưa được mở khóa!
    if (!currentProgress.isUnlocked) {
      return null;
    }

    final isFirstCompletion = !currentProgress.isCompleted;
    final oldBestStars = currentProgress.bestStars;
    final newBestStars = StarRatingCalculator.updateBestStars(
      currentBest: oldBestStars,
      newlyEarned: earnedStars,
    );
    final isNewBest = newBestStars > oldBestStars;

    final updatedMap =
        Map<String, LevelProgress>.from(state.progress.progressMap);

    // 4. Cập nhật trạng thái của màn chơi vừa thắng
    updatedMap[levelId] = currentProgress.copyWith(
      isCompleted: true,
      bestStars: newBestStars,
      isUnlocked: true,
    );

    // 5. Mở khóa màn chơi tiếp theo (N + 1) nếu chưa phải Level 180
    String? nextUnlockedId;
    String highestUnlockedId = state.progress.highestUnlockedLevelId;

    if (level.overallIndex < 180) {
      final nextOverall = level.overallIndex + 1;
      final nextLevel = _levelRepository.getLevelByOverallIndex(nextOverall);
      if (nextLevel != null) {
        nextUnlockedId = nextLevel.id;
        final nextProgress = updatedMap[nextLevel.id] ??
            LevelProgress(levelId: nextLevel.id, isUnlocked: false);

        if (!nextProgress.isUnlocked) {
          updatedMap[nextLevel.id] = nextProgress.copyWith(isUnlocked: true);
        }

        // Cập nhật mốc level cao nhất mở khóa nếu tiến xa hơn
        final currentHighestLevel =
            _levelRepository.getLevelById(highestUnlockedId);
        final currentHighestOverall = currentHighestLevel?.overallIndex ?? 1;
        if (nextOverall > currentHighestOverall) {
          highestUnlockedId = nextLevel.id;
        }
      }
    }

    // 6. Tạo thực thể tiến trình mới
    final updatedProgress = state.progress.copyWith(
      progressMap: updatedMap,
      highestUnlockedLevelId: highestUnlockedId,
    );

    final result = LevelCompletionResult(
      levelId: levelId,
      earnedStars: earnedStars,
      bestStars: newBestStars,
      isNewBest: isNewBest,
      isFirstCompletion: isFirstCompletion,
      nextUnlockedLevelId: nextUnlockedId,
    );

    // 7. Lưu an toàn vào SharedPreferences TRƯỚC KHI cập nhật UI state:
    // Nếu lưu thất bại, không cập nhật state thành công giả mạo!
    try {
      await _progressRepository.saveProgress(updatedProgress);
      state = state.copyWith(
        progress: updatedProgress,
        lastCompletionResult: result,
        clearErrorMessage: true,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Lưu tiến trình Campaign thất bại: $e',
      );
      return null;
    }
  }

  /// Đặt lại toàn bộ tiến trình Campaign về mặc định (chỉ Level 1 mở, 0 sao).
  /// Không ảnh hưởng đến Active Game Session.
  Future<void> resetProgress() async {
    if (_initFuture != null) {
      await _initFuture;
    }

    try {
      await _progressRepository.resetProgress();
      state = state.copyWith(
        progress: CampaignProgress.initial(),
        clearCompletionResult: true,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Không thể reset tiến trình Campaign: $e',
      );
    }
  }

  /// Xóa thông báo lỗi tạm thời.
  void clearErrorMessage() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearErrorMessage: true);
    }
  }
}

