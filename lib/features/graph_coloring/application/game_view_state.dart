import '../../campaign/domain/entities/puzzle_level.dart';
import '../domain/entities/color_inventory.dart';
import '../domain/entities/game_move.dart';
import '../domain/entities/game_status.dart';
import '../domain/entities/graph.dart';
import '../domain/entities/puzzle_color.dart';

/// Trạng thái bất biến (immutable) của phiên chơi game.
class GameViewState {
  const GameViewState({
    this.attemptId = '',
    required this.levelId,
    this.currentLevel,
    this.levelTitle = '',
    required this.graph,
    required this.inventory,
    this.status = GameStatus.playing,
    this.remainingMistakes = 2,
    this.mistakesCount = 0,
    this.hintsUsed = 0,
    this.hintedNodeId,
    this.hintedColor,
    this.undoHistory = const [],
    this.hasUsedContinue = false,
    this.hasUsedUndo = false,
    this.selectedColor,
    this.errorMessage,
    this.isInitializing = false,
    this.earnedStars,
  });

  /// Định danh cố định của lượt chơi hiện tại (UUID v4 thuần).
  final String attemptId;

  /// Định danh level hiện tại.
  final String levelId;

  /// Thông tin định nghĩa của màn chơi hiện tại (nếu nạp từ Campaign).
  final PuzzleLevel? currentLevel;

  /// Tiêu đề hiển thị của màn chơi trên Header.
  final String levelTitle;

  /// Đồ thị hiện tại với trạng thái các node.
  final Graph graph;

  /// Kho màu và tiến độ sử dụng từng màu.
  final ColorInventory inventory;

  /// Trạng thái vòng đời của ván chơi (playing, completed, gameOver).
  final GameStatus status;

  /// Số lượt lỗi còn lại trong ván (bắt đầu từ 2, giảm khi phạm lỗi No Solution).
  final int remainingMistakes;

  /// Tổng số lần mắc lỗi No Solution trong suốt lượt chơi hiện tại (phục vụ tính 3 sao).
  final int mistakesCount;

  /// Số lần đã sử dụng gợi ý (Hint) trong lượt chơi hiện tại (dùng để tính sao: hintsUsed > 0 tối đa 1 sao).
  final int hintsUsed;

  /// ID của node đang được gợi ý nổi bật trên bàn cờ (null nếu không có gợi ý nào đang hoạt động).
  final String? hintedNodeId;

  /// Màu sắc được gợi ý cho node tương ứng (null nếu không có gợi ý).
  final PuzzleColor? hintedColor;

  /// Lịch sử các nước đi hợp lệ đã thực hiện (dùng cho Undo).
  final List<GameMove> undoHistory;

  /// Đã sử dụng lượt Continue (quảng cáo) trong ván này chưa (tối đa 1 lần).
  final bool hasUsedContinue;

  /// Đã sử dụng lượt Hoàn tác (Undo) trong ván này chưa (tối đa 1 lần / level).
  final bool hasUsedUndo;

  /// Màu đang được chọn khi dùng cơ chế Tap-to-select (null nếu không chọn).
  final PuzzleColor? selectedColor;

  /// Thông điệp lỗi hoặc thông báo tạm thời từ chối nước đi (nếu có).
  final String? errorMessage;

  /// Cờ xác định phiên chơi đang trong quá trình khôi phục ban đầu từ SharedPreferences.
  /// Giúp UI hiển thị loader mượt mà, không bị flash màn hình mặc định rồi mới ghi đè.
  final bool isInitializing;

  /// Số sao đạt được khi hoàn thành màn chơi (1, 2 hoặc 3 sao). Null nếu chưa hoàn thành.
  final int? earnedStars;

  bool get isPlaying => status == GameStatus.playing;
  bool get isCompleted => status == GameStatus.completed;
  bool get isGameOver => status == GameStatus.gameOver;
  bool get canUndo => isPlaying && undoHistory.isNotEmpty && !hasUsedUndo;
  bool get hasActiveHint => hintedNodeId != null && hintedColor != null;

  /// Kiểm tra xem người chơi đã đặt ít nhất một quả bóng nào lên đồ thị chưa.
  /// Bỏ qua các node bị khóa (locked nodes có sẵn màu từ màn chơi ban đầu).
  bool get hasPlacedBalls =>
      graph.nodes.values.any((node) => !node.isLocked && node.currentColor != null);

  GameViewState copyWith({
    String? attemptId,
    String? levelId,
    PuzzleLevel? currentLevel,
    bool clearCurrentLevel = false,
    String? levelTitle,
    Graph? graph,
    ColorInventory? inventory,
    GameStatus? status,
    int? remainingMistakes,
    int? mistakesCount,
    int? hintsUsed,
    String? hintedNodeId,
    PuzzleColor? hintedColor,
    bool clearHint = false,
    List<GameMove>? undoHistory,
    bool? hasUsedContinue,
    bool? hasUsedUndo,
    PuzzleColor? selectedColor,
    bool clearSelectedColor = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isInitializing,
    int? earnedStars,
    bool clearEarnedStars = false,
  }) {
    return GameViewState(
      attemptId: attemptId ?? this.attemptId,
      levelId: levelId ?? this.levelId,
      currentLevel: clearCurrentLevel ? null : (currentLevel ?? this.currentLevel),
      levelTitle: levelTitle ?? this.levelTitle,
      graph: graph ?? this.graph,
      inventory: inventory ?? this.inventory,
      status: status ?? this.status,
      remainingMistakes: remainingMistakes ?? this.remainingMistakes,
      mistakesCount: mistakesCount ?? this.mistakesCount,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintedNodeId: clearHint ? null : (hintedNodeId ?? this.hintedNodeId),
      hintedColor: clearHint ? null : (hintedColor ?? this.hintedColor),
      undoHistory: undoHistory ?? this.undoHistory,
      hasUsedContinue: hasUsedContinue ?? this.hasUsedContinue,
      hasUsedUndo: hasUsedUndo ?? this.hasUsedUndo,
      selectedColor: clearSelectedColor ? null : (selectedColor ?? this.selectedColor),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isInitializing: isInitializing ?? this.isInitializing,
      earnedStars: clearEarnedStars ? null : (earnedStars ?? this.earnedStars),
    );
  }
}
