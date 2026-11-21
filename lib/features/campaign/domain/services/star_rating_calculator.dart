/// Service tính toán số sao đạt được dựa trên tiêu chí GDD Mục 7.5.
/// Tầng Domain thuần Dart.
class StarRatingCalculator {
  const StarRatingCalculator._();

  /// Tính số sao đạt được trong một lượt chơi (attempt):
  /// - 0 sao: Chưa hoàn thành màn chơi.
  /// - 1 sao: Hoàn thành level.
  /// - 2 sao: Hoàn thành level mà không sử dụng Hint.
  /// - 3 sao: Hoàn thành level mà không sử dụng Hint VÀ không mắc lỗi nào.
  static int calculateStars({
    required bool isCompleted,
    required int hintsUsed,
    required int mistakesCount,
  }) {
    if (!isCompleted) return 0;

    // 3 sao: Không hint và 0 lỗi
    if (hintsUsed == 0 && mistakesCount == 0) {
      return 3;
    }

    // 2 sao: Không hint
    if (hintsUsed == 0) {
      return 2;
    }

    // 1 sao: Hoàn thành màn chơi
    return 1;
  }

  /// Cập nhật số sao tốt nhất đã đạt: Không bao giờ làm giảm số sao cũ.
  static int updateBestStars({
    required int currentBest,
    required int newlyEarned,
  }) {
    return newlyEarned > currentBest ? newlyEarned : currentBest;
  }
}

