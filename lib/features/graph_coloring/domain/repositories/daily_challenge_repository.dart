import '../entities/daily_challenge_state.dart';
import '../entities/level_completion_event.dart';

/// Interface quản lý Daily Challenges và tiến độ nhiệm vụ hằng ngày.
/// Tầng Domain thuần Dart.
abstract class DailyChallengeRepository {
  /// Lấy trạng thái Daily Challenges của ngày hiện tại (tự động reset nếu sang ngày mới).
  Future<DailyChallengeState> getDailyChallengeState();

  /// Ghi nhận sự kiện hoàn thành màn chơi vào Daily Challenge.
  /// - Kiểm tra idempotent theo attemptId.
  /// - Chỉ ghi nhận nếu event thuộc ngày hiện tại.
  /// - Trả về `true` nếu ghi đĩa thành công hoặc nếu event đã được ghi nhận trước đó.
  /// - Trả về `false` nếu ghi đĩa thất bại.
  Future<bool> recordCompletion(LevelCompletionEvent event);

  /// Đánh dấu một nhiệm vụ là đã nhận thưởng sau khi Energy được cộng thành công.
  /// Trả về `true` nếu lưu đĩa thành công, `false` nếu ghi đĩa thất bại.
  Future<bool> markMissionClaimed(String missionId);

  /// Đặt lại Daily Challenges về trạng thái ban đầu của ngày hôm nay (dùng cho debug/test).
  Future<bool> resetDailyChallenge();
}

