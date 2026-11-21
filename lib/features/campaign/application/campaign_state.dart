import '../domain/entities/campaign_progress.dart';

/// Kết quả chi tiết sau khi hoàn thành một màn chơi trong Campaign.
class LevelCompletionResult {
  const LevelCompletionResult({
    required this.levelId,
    required this.earnedStars,
    required this.bestStars,
    required this.isNewBest,
    required this.isFirstCompletion,
    this.nextUnlockedLevelId,
  });

  final String levelId;
  final int earnedStars;
  final int bestStars;
  final bool isNewBest;
  final bool isFirstCompletion;
  final String? nextUnlockedLevelId;
}

/// Trạng thái bất biến của toàn bộ tiến trình Campaign.
class CampaignState {
  const CampaignState({
    required this.progress,
    this.isLoading = false,
    this.lastCompletionResult,
    this.errorMessage,
  });

  final CampaignProgress progress;
  final bool isLoading;
  final LevelCompletionResult? lastCompletionResult;
  final String? errorMessage;

  int get totalStars => progress.totalStars;
  int get completedLevelsCount => progress.completedLevelsCount;
  String get highestUnlockedLevelId => progress.highestUnlockedLevelId;

  bool isLevelUnlocked(String levelId) =>
      progress.getLevelProgress(levelId).isUnlocked;

  bool isLevelCompleted(String levelId) =>
      progress.getLevelProgress(levelId).isCompleted;

  int getLevelStars(String levelId) =>
      progress.getLevelProgress(levelId).bestStars;

  CampaignState copyWith({
    CampaignProgress? progress,
    bool? isLoading,
    LevelCompletionResult? lastCompletionResult,
    bool clearCompletionResult = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CampaignState(
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      lastCompletionResult: clearCompletionResult
          ? null
          : (lastCompletionResult ?? this.lastCompletionResult),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

