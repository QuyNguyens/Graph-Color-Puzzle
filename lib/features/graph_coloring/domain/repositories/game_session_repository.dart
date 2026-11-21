import '../entities/active_session_metadata_result.dart';
import '../entities/color_inventory.dart';
import '../entities/game_move.dart';
import '../entities/graph.dart';

/// Dữ liệu phục hồi của một ván chơi dở dang.
class RestoredGameSession {
  const RestoredGameSession({
    required this.attemptId,
    required this.levelId,
    required this.graph,
    required this.inventory,
    required this.remainingMistakes,
    required this.mistakesCount,
    this.hintsUsed = 0,
    required this.hasUsedContinue,
    this.hasUsedUndo = false,
    required this.undoHistory,
    this.completedAtIso,
    this.earnedStars,
  });

  /// Định danh duy nhất cố định của lượt chơi (UUID v4)
  final String attemptId;

  final String levelId;
  final Graph graph;
  final ColorInventory inventory;
  final int remainingMistakes;
  final int mistakesCount;
  final int hintsUsed;
  final bool hasUsedContinue;
  final bool hasUsedUndo;
  final List<GameMove> undoHistory;

  /// Thời điểm hoàn thành nếu ván cờ đã thắng (null nếu đang chơi)
  final String? completedAtIso;

  /// Số sao đạt được nếu ván cờ đã thắng (null nếu đang chơi)
  final int? earnedStars;
}

/// Interface trừu tượng cho việc lưu và khôi phục trạng thái lượt chơi.
/// Tầng Domain thuần Dart, không phụ thuộc vào SharedPreferences hay external packages.
abstract class GameSessionRepository {
  /// Lưu trạng thái của lượt chơi hiện tại.
  /// Trả về `true` nếu lưu đĩa thành công, `false` nếu ghi đĩa thất bại.
  Future<bool> saveActiveSession({
    required String levelId,
    required Graph graph,
    required int remainingMistakes,
    required int mistakesCount,
    required int hintsUsed,
    required bool hasUsedContinue,
    bool hasUsedUndo = false,
    required List<GameMove> undoHistory,
    String? attemptId,
    String? completedAtIso,
    int? earnedStars,
  });

  /// Đọc và khôi phục trạng thái dở dang nếu có.
  /// - Tự động migrate session v1–v3 lên v4 và persist đĩa ngay lập tức.
  /// - Trả về null nếu không có session hoặc session bị hỏng/không hợp lệ hoặc migration thất bại.
  Future<RestoredGameSession?> loadActiveSession({
    required String levelId,
    required Graph initialGraph,
    required Map<dynamic, int> initialTargets,
  });

  /// Lấy levelId của ván chơi dở dang đang được lưu (nếu có).
  /// Trả về null nếu không có session dở dang hoặc session hỏng.
  Future<String?> getActiveSessionLevelId();

  /// Thẩm định nhanh siêu dữ liệu của phiên chơi hiện tại trên đĩa mà không dựng lại toàn bộ đồ thị (Lightweight Inspection).
  /// Phân biệt rõ: không có session, session đang chơi, session đã thắng, session bị hỏng cú pháp hoặc lỗi I/O storage.
  /// Tuyệt đối không xóa session, không ghi đè đĩa và không thực hiện Deep Restoration.
  Future<ActiveSessionMetadataResult> getActiveSessionMetadata();

  /// Xóa dữ liệu lượt chơi đã lưu (khi hoàn thành màn hoặc restart màn mới).
  /// Trả về `true` nếu xóa thành công.
  Future<bool> clearActiveSession();

  /// Xóa dữ liệu lượt chơi có điều kiện: chỉ xóa nếu session hiện tại trên đĩa khớp chính xác với [expectedAttemptId].
  /// - Trả về `true` nếu session tồn tại, khớp attemptId và đã được xóa thành công.
  /// - Trả về `false` nếu không có session, attemptId không khớp, JSON hỏng hoặc không xác định được attemptId.
  /// Tuyệt đối không xóa dữ liệu nếu không khớp attemptId.
  Future<bool> clearActiveSessionIfMatches({required String expectedAttemptId});
}
