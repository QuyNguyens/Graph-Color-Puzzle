import '../entities/campaign_progress.dart';

/// Interface cho việc lưu trữ và khôi phục tiến trình Campaign của người chơi.
/// Tầng Domain thuần Dart, không phụ thuộc SharedPreferences hay framework.
abstract class CampaignProgressRepository {
  /// Đọc tiến trình Campaign từ bộ nhớ cục bộ.
  /// Nếu chưa có dữ liệu hoặc dữ liệu bị hỏng, trả về CampaignProgress.initial().
  Future<CampaignProgress> loadProgress();

  /// Lưu trạng thái tiến trình Campaign.
  Future<void> saveProgress(CampaignProgress progress);

  /// Đặt lại toàn bộ tiến trình Campaign về mặc định (chỉ Level 1 mở khóa, 0 sao).
  /// Không làm ảnh hưởng đến Active Game Session.
  Future<void> resetProgress();
}

