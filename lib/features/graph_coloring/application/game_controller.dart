import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../campaign/application/campaign_providers.dart';
import '../../campaign/application/level_providers.dart';
import '../../campaign/domain/entities/puzzle_level.dart';
import '../../campaign/domain/services/star_rating_calculator.dart';
import '../data/datasources/game_session_local_datasource.dart';
import '../data/repositories/game_session_repository_impl.dart';
import '../domain/entities/attempt_lifecycle_result.dart';
import '../domain/entities/game_move.dart';
import '../domain/entities/game_status.dart';
import '../domain/entities/puzzle_color.dart';
import '../domain/repositories/daily_energy_repository.dart';
import '../domain/repositories/game_session_repository.dart';
import '../domain/services/game_validation_service.dart';
import '../domain/services/hint_service.dart';
import '../domain/services/uuid_generator.dart';
import 'completion_event_processor_providers.dart';
import 'energy_providers.dart';
import 'game_view_state.dart';
import 'hint_providers.dart';
import '../../../core/audio/game_audio_service.dart';

export '../domain/entities/attempt_lifecycle_result.dart';

/// Provider cung cấp GameSessionRepository.
final gameSessionRepositoryProvider = Provider<GameSessionRepository>((ref) {
  return GameSessionRepositoryImpl(
    localDataSource: GameSessionLocalDataSource(),
  );
});

/// Provider kiểm tra ID màn chơi dở dang đang được lưu (nếu có).
final activeSessionLevelIdProvider = FutureProvider<String?>((ref) async {
  final sessionRepo = ref.watch(gameSessionRepositoryProvider);
  return sessionRepo.getActiveSessionLevelId();
});

/// Controller quản lý vòng đời ván chơi (Game Session), điều phối các hành động của người chơi:
/// Tô màu, Đổi màu, Xóa màu, Undo, Restart và Hệ thống Lượt lỗi.
/// Tuân thủ Riverpod 3 Notifier API.
class GameController extends Notifier<GameViewState> {
  late final GameValidationService _validationService;
  late final GameSessionRepository _sessionRepository;
  late final HintService _hintService;

  static const String currentLevelId = 'mock_level_c1_l01';
  int _sessionGeneration = 0;
  bool _isRequestingHint = false;
  bool _isRestarting = false;
  bool _isAbandoning = false;
  bool _isHandlingGameOver = false;
  bool _isProcessingMove = false;
  PuzzleLevel? _currentLevel;

  @override
  GameViewState build() {
    _validationService = const GameValidationService();
    _sessionRepository = ref.watch(gameSessionRepositoryProvider);
    _hintService = ref.watch(hintServiceProvider);

    // Mặc định nạp Level 1 (c1_l01) từ LevelRepository thay cho mock level cũ
    final firstLevel =
        ref.read(levelRepositoryProvider).getLevelByOverallIndex(1)!;
    _currentLevel = firstLevel;

    // Tự động khôi phục ván chơi dở dang sau khi build khởi tạo
    Future.microtask(() => _restoreSessionIfAvailable());

    return _createInitialStateForLevel(firstLevel, isInitializing: true);
  }

  GameViewState _createInitialStateForLevel(
    PuzzleLevel level, {
    String? attemptId,
    bool isInitializing = false,
  }) {
    return GameViewState(
      attemptId: attemptId ?? UuidGenerator.generateAttemptId(level.id),
      levelId: level.id,
      currentLevel: level,
      levelTitle: 'Chapter ${level.chapterId} - Màn ${level.levelNumber}: ${level.title}',
      graph: level.initialGraph,
      inventory: level.createInitialInventory(),
      status: GameStatus.playing,
      remainingMistakes: 2,
      mistakesCount: 0,
      undoHistory: const [],
      hasUsedContinue: false,
      hasUsedUndo: false,
      selectedColor: null,
      errorMessage: null,
      isInitializing: isInitializing,
    );
  }

  /// Nạp một màn chơi mới từ Campaign.
  /// Nếu [resetSession] là true, xóa sạch session cũ và bắt đầu ván chơi mới từ đầu (0 nước đi, 2 khiên lỗi).
  /// Sử dụng `_sessionGeneration` để loại bỏ hoàn toàn race condition nếu người chơi chuyển level nhanh.
  Future<void> loadLevel(
    PuzzleLevel level, {
    bool resetSession = false,
  }) async {
    _currentLevel = level;
    _sessionGeneration++;
    _isRequestingHint = false;
    _isRestarting = false;
    _isHandlingGameOver = false;
    final gen = _sessionGeneration;

    if (resetSession) {
      // Xóa session dở dang cũ và khởi tạo ván mới hoàn toàn từ đầu
      await _sessionRepository.clearActiveSession();
      if (gen != _sessionGeneration) return;
      state = _createInitialStateForLevel(
        level,
        attemptId: UuidGenerator.generateV4(),
        isInitializing: false,
      );
      _autoSave();
      return;
    }

    // Reset giao diện ngay lập tức về trạng thái rỗng của level mới
    state = _createInitialStateForLevel(level, isInitializing: true);

    final restored = await _sessionRepository.loadActiveSession(
      levelId: level.id,
      initialGraph: level.initialGraph,
      initialTargets: level.targetInventory,
    );

    // Bỏ qua kết quả đọc bất đồng bộ nếu người chơi đã chuyển level hoặc restart
    if (gen != _sessionGeneration) return;

    if (restored != null && restored.levelId == level.id) {
      final isCompleted = _validationService.isLevelCompleted(
        graph: restored.graph,
        inventory: restored.inventory,
      );

      state = state.copyWith(
        attemptId: restored.attemptId,
        levelId: level.id,
        currentLevel: level,
        levelTitle: 'Chapter ${level.chapterId} - Màn ${level.levelNumber}: ${level.title}',
        graph: restored.graph,
        inventory: restored.inventory,
        remainingMistakes: restored.remainingMistakes,
        mistakesCount: restored.mistakesCount,
        hintsUsed: restored.hintsUsed,
        hasUsedContinue: restored.hasUsedContinue,
        hasUsedUndo: restored.hasUsedUndo,
        undoHistory: restored.undoHistory,
        status: isCompleted ? GameStatus.completed : GameStatus.playing,
        isInitializing: false,
        clearErrorMessage: true,
      );
    } else {
      state = state.copyWith(isInitializing: false);
    }
  }

  /// Khôi phục ván chơi dở dang từ SharedPreferences nếu hợp lệ.
  Future<void> _restoreSessionIfAvailable() async {
    final gen = _sessionGeneration;
    final level = _currentLevel ??
        ref.read(levelRepositoryProvider).getLevelByOverallIndex(1)!;
    final levelId = level.id;

    final restored = await _sessionRepository.loadActiveSession(
      levelId: levelId,
      initialGraph: level.initialGraph,
      initialTargets: level.targetInventory,
    );

    // Nếu trong lúc load mà người chơi đã thực hiện Restart hoặc chuyển level thì hủy kết quả
    if (gen != _sessionGeneration) return;

    if (restored != null && restored.levelId == levelId) {
      // Kiểm tra trạng thái đã hoàn thành hay chưa
      final isCompleted = _validationService.isLevelCompleted(
        graph: restored.graph,
        inventory: restored.inventory,
      );

      state = state.copyWith(
        attemptId: restored.attemptId,
        levelId: levelId,
        currentLevel: level,
        levelTitle: 'Chapter ${level.chapterId} - Màn ${level.levelNumber}: ${level.title}',
        graph: restored.graph,
        inventory: restored.inventory,
        remainingMistakes: restored.remainingMistakes,
        mistakesCount: restored.mistakesCount,
        hintsUsed: restored.hintsUsed,
        hasUsedContinue: restored.hasUsedContinue,
        hasUsedUndo: restored.hasUsedUndo,
        undoHistory: restored.undoHistory,
        status: isCompleted ? GameStatus.completed : GameStatus.playing,
        isInitializing: false,
        clearErrorMessage: true,
      );
    } else {
      state = state.copyWith(isInitializing: false);
    }
  }

  /// Tự động lưu trạng thái ván chơi vào SharedPreferences sau mỗi thay đổi quan trọng.
  void _autoSave() {
    final gen = _sessionGeneration;
    if (state.isCompleted) {
      // Khi đã hoàn thành, CompletionEventProcessor chịu trách nhiệm lưu và dọn dẹp.
      // Tuyệt đối không xóa Active Session tại đây để tránh race condition xóa trước khi enqueue Outbox.
      return;
    } else {
      if (gen != _sessionGeneration) return;
      _sessionRepository.saveActiveSession(
        levelId: state.levelId,
        graph: state.graph,
        remainingMistakes: state.remainingMistakes,
        mistakesCount: state.mistakesCount,
        hintsUsed: state.hintsUsed,
        hasUsedContinue: state.hasUsedContinue,
        hasUsedUndo: state.hasUsedUndo,
        undoHistory: state.undoHistory,
        attemptId: state.attemptId,
      );
    }
  }

  /// Chọn hoặc hủy chọn màu (Tap-to-select).
  void selectColor(PuzzleColor? color) {
    if (!state.isPlaying) return;

    if (state.selectedColor == color) {
      state = state.copyWith(clearSelectedColor: true);
    } else {
      state = state.copyWith(selectedColor: color);
      if (color != null) {
        ref.read(gameAudioServiceProvider).playSelectColor();
      }
    }
  }

  /// Luồng xử lý nước đi DUY NHẤT cho cả Drag & Drop và Tap-to-select.
  Future<bool> applyColorMove({
    required String nodeId,
    required PuzzleColor color,
  }) async {
    // Khóa mọi thao tác khi ván chơi đã kết thúc, thất bại hoặc nước đi trước đang xử lý (chống rapid tap)
    if (!state.isPlaying || _isProcessingMove) return false;
    _isProcessingMove = true;

    try {
      final validation = _validationService.validateMove(
      graph: state.graph,
      inventory: state.inventory,
      nodeId: nodeId,
      newColor: color,
    );

    switch (validation) {
      case MoveValidationResult.noOp:
        return false;

      case MoveValidationResult.rejectedLockedNode:
        ref.read(gameAudioServiceProvider).playInvalidMove();
        state = state.copyWith(
          errorMessage: 'Node đã bị khóa cố định, không thể đổi màu!',
        );
        return false;

      case MoveValidationResult.rejectedRestrictedColor:
        return await _handleInvalidMove(
          'Node này không cho phép sử dụng màu ${color.label}!',
        );

      case MoveValidationResult.rejectedInventoryEmpty:
        return await _handleInvalidMove(
          'Màu ${color.label} đã dùng hết số lượng trong kho!',
        );

      case MoveValidationResult.rejectedAdjacentConflict:
        return await _handleInvalidMove(
          'Hai node nối với nhau không được có cùng màu!',
        );

      case MoveValidationResult.rejectedNoSolution:
        return await _handleInvalidMove(
          'Không còn cách hoàn thành với lựa chọn này.',
        );

      case MoveValidationResult.valid:
        final targetNode = state.graph.getNode(nodeId)!;
        final oldColor = targetNode.currentColor;

        var updatedInventory = state.inventory;
        if (oldColor != null) {
          updatedInventory = updatedInventory.releaseColor(oldColor);
        }
        updatedInventory = updatedInventory.useColor(color);

        final updatedNode = targetNode.copyWith(currentColor: color);
        final updatedGraph = state.graph.withUpdatedNode(updatedNode);

        // Lưu vào lịch sử Undo (chỉ lưu nước đi được chấp nhận)
        final move = GameMove(
          nodeId: nodeId,
          previousColor: oldColor,
          newColor: color,
          timestamp: DateTime.now(),
        );

        final updatedHistory = [...state.undoHistory, move];

        final completed = _validationService.isLevelCompleted(
          graph: updatedGraph,
          inventory: updatedInventory,
        );

        if (completed) {
          final earnedStars = StarRatingCalculator.calculateStars(
            isCompleted: true,
            hintsUsed: state.hintsUsed,
            mistakesCount: state.mistakesCount,
          );

          state = state.copyWith(
            graph: updatedGraph,
            inventory: updatedInventory,
            undoHistory: updatedHistory,
            status: GameStatus.completed,
            earnedStars: earnedStars,
            clearErrorMessage: true,
            clearHint: true,
          );

          // Phát âm thanh chiến thắng khi hoàn thành màn chơi (victory_advance.wav)
          ref.read(gameAudioServiceProvider).playVictoryAdvance(attemptId: state.attemptId);

          final level = _currentLevel ??
              ref.read(levelRepositoryProvider).getLevelById(state.levelId)!;

          // Bàn giao toàn bộ luồng lưu Completed Session và điều phối Outbox/Campaign/Challenge cho Processor
          await ref.read(completionEventProcessorProvider).processWinningGame(
                level: level,
                graph: updatedGraph,
                inventory: updatedInventory,
                remainingMistakes: state.remainingMistakes,
                mistakesCount: state.mistakesCount,
                hintsUsed: state.hintsUsed,
                hasUsedContinue: state.hasUsedContinue,
                undoHistory: updatedHistory,
                attemptId: state.attemptId,
                earnedStars: earnedStars,
              );

          return true;
        }

        state = state.copyWith(
          graph: updatedGraph,
          inventory: updatedInventory,
          undoHistory: updatedHistory,
          status: GameStatus.playing,
          clearErrorMessage: true,
          clearHint: true,
        );

        _autoSave();
        // Phát âm thanh đặt bóng thành công
        ref.read(gameAudioServiceProvider).playMoveColor();
        return true;
      }
    } finally {
      _isProcessingMove = false;
    }
  }

  /// Xử lý trừ lỗi thống nhất (Unified Mistake Accounting - Phase D4):
  /// - Áp dụng cho mọi nước đi không hợp lệ (Adjacent Conflict, Inventory Empty, Restricted Color, No Solution).
  /// - Mỗi thao tác người chơi chỉ trừ TỐI ĐA 1 lỗi (remainingMistakes: 2 -> 1 -> 0).
  /// - Rollback an toàn: Trạng thái bàn cờ và Inventory hoàn toàn không bị thay đổi.
  /// - Khi số lượt lỗi còn 0 và tiếp tục mắc lỗi -> Chuyển sang GameOver và trừ 1 Energy (loss).
  Future<bool> _handleInvalidMove(String message) async {
    final newMistakesCount = state.mistakesCount + 1;

    if (state.remainingMistakes > 0) {
      final newMistakes = state.remainingMistakes - 1;
      state = state.copyWith(
        remainingMistakes: newMistakes,
        mistakesCount: newMistakesCount,
        errorMessage: message,
      );
      _autoSave();
      // Phát âm thanh nước đi không hợp lệ
      ref.read(gameAudioServiceProvider).playInvalidMove();
      return false;
    } else {
      // Khi số lượt lỗi còn 0 và tiếp tục mắc thêm lỗi -> Chuyển sang GameOver
      if (_isHandlingGameOver) return false;
      _isHandlingGameOver = true;

      final attemptId = state.attemptId;
      // Tiêu thụ 1 Energy nguyên tử gắn với attemptId và lý do 'loss'
      try {
        await ref
            .read(dailyEnergyNotifierProvider.notifier)
            .consumeEnergy(
              amount: 1,
              attemptId: attemptId,
              reason: 'loss',
            );
      } catch (_) {}

      // Chuyển sang GameOver và lưu session
      state = state.copyWith(
        mistakesCount: newMistakesCount,
        status: GameStatus.gameOver,
        errorMessage: 'Bạn đã hết lượt lỗi! Màn chơi kết thúc.',
      );
      _autoSave();
      // Phát âm thanh thua cuộc chính xác 1 lần cho attempt này
      ref.read(gameAudioServiceProvider).playDefeat(attemptId: attemptId);
      return false;
    }
  }

  /// Xóa màu khỏi node thường và hoàn trả vào Inventory.
  bool removeColor(String nodeId) {
    if (!state.isPlaying) return false;

    final targetNode = state.graph.getNode(nodeId);
    if (targetNode == null) return false;

    if (targetNode.isLocked) {
      ref.read(gameAudioServiceProvider).playInvalidMove();
      state = state.copyWith(
        errorMessage: 'Không thể xóa màu của Node bị khóa!',
      );
      return false;
    }

    final oldColor = targetNode.currentColor;
    if (oldColor == null) return false;

    final updatedInventory = state.inventory.releaseColor(oldColor);
    final updatedNode = targetNode.copyWith(clearColor: true);
    final updatedGraph = state.graph.withUpdatedNode(updatedNode);

    // Ghi nhận thao tác xóa màu vào lịch sử Undo để có thể hoàn tác
    final move = GameMove(
      nodeId: nodeId,
      previousColor: oldColor,
      newColor: null,
      timestamp: DateTime.now(),
    );

    final updatedHistory = [...state.undoHistory, move];

    state = state.copyWith(
      graph: updatedGraph,
      inventory: updatedInventory,
      undoHistory: updatedHistory,
      status: GameStatus.playing,
      clearErrorMessage: true,
      clearHint: true,
    );

    _autoSave();
    return true;
  }

  /// Hoàn tác nước đi hợp lệ gần nhất (Undo).
  /// Mỗi màn chơi chỉ được hoàn tác tối đa 1 lần (hasUsedUndo = true).
  bool undo() {
    if (state.hasUsedUndo) {
      state = state.copyWith(
        errorMessage: 'Mỗi màn chơi chỉ được hoàn tác tối đa 1 lần!',
      );
      return false;
    }
    if (!state.canUndo) return false;

    final lastMove = state.undoHistory.last;
    final newHistory = state.undoHistory.sublist(0, state.undoHistory.length - 1);

    final targetNode = state.graph.getNode(lastMove.nodeId);
    if (targetNode == null) return false;

    // Khôi phục màu cũ của node
    final revertedNode = targetNode.copyWith(
      currentColor: lastMove.previousColor,
      clearColor: lastMove.previousColor == null,
    );
    final newGraph = state.graph.withUpdatedNode(revertedNode);

    // Khôi phục Inventory tương ứng
    var newInventory = state.inventory;
    // 1. Hoàn trả màu mới đã gán (nếu có)
    if (lastMove.newColor != null) {
      newInventory = newInventory.releaseColor(lastMove.newColor!);
    }
    // 2. Tiêu thụ lại màu cũ đã bị thay thế (nếu có)
    if (lastMove.previousColor != null) {
      newInventory = newInventory.useColor(lastMove.previousColor!);
    }

    // Đánh dấu đã sử dụng Undo (tối đa 1 lần / màn chơi)
    // Lưu ý: Undo không phục hồi lượt lỗi đã mất và không giảm mistakesCount
    state = state.copyWith(
      graph: newGraph,
      inventory: newInventory,
      undoHistory: newHistory,
      hasUsedUndo: true,
      status: GameStatus.playing,
      clearErrorMessage: true,
      clearHint: true,
    );

    _autoSave();
    // Phát âm thanh hoàn tác thành công
    ref.read(gameAudioServiceProvider).playUndo();
    return true;
  }

  /// Chơi lại màn chơi đã hoàn thành (Replay) — Hoàn toàn MIỄN PHÍ (0 Energy).
  /// Điều kiện: Màn chơi đã hoàn thành (`status == GameStatus.completed`).
  /// - Không tiêu thụ Energy, không chặn Replay kể cả khi Energy = 0.
  /// - Sinh Attempt ID (UUID v4) mới độc lập.
  /// - Dọn active session cũ trên đĩa nếu khớp attemptId.
  /// - Reset bàn cờ về trạng thái ban đầu, bảo toàn 100% kỷ lục sao và tiến trình Campaign cũ.
  Future<AttemptLifecycleResult> replayLevel() async {
    if (_isRestarting) return AttemptLifecycleResult.invalidLifecycleState;
    _isRestarting = true;

    try {
      final oldAttemptId = state.attemptId;
      _sessionGeneration++;
      _isRequestingHint = false;
      _isHandlingGameOver = false;

      // 1. Dọn active session cũ có điều kiện (chỉ xóa nếu đúng attemptId cũ)
      await _sessionRepository.clearActiveSessionIfMatches(
        expectedAttemptId: oldAttemptId,
      );

      // 2. Khởi tạo ván chơi mới độc lập với Attempt ID UUID v4 mới
      final level = _currentLevel ??
          ref.read(levelRepositoryProvider).getLevelByOverallIndex(1)!;

      state = _createInitialStateForLevel(
        level,
        attemptId: UuidGenerator.generateV4(),
        isInitializing: false,
      );

      _autoSave();
      // Phát âm thanh replay / restart
      ref.read(gameAudioServiceProvider).playReplay();
      return AttemptLifecycleResult.success;
    } catch (_) {
      return AttemptLifecycleResult.persistenceFailure;
    } finally {
      _isRestarting = false;
    }
  }

  /// Khởi động lại ván chơi đang dở dang (Restart) — Tiêu thụ ĐÚNG 1 Energy.
  /// Điều kiện: Ván chơi đang ở trạng thái `playing`.
  /// - Nếu Energy = 0: Trả về `insufficientEnergy`, KHÔNG xóa session, KHÔNG reset bàn cờ,
  ///   KHÔNG đổi attemptId (chờ xem Rewarded Ad ở tầng UI).
  /// - Nếu Energy > 0: Tiêu thụ nguyên tử đúng 1 Energy gắn với attemptId cũ (chống trừ trùng).
  /// - Dọn active session cũ và khởi tạo ván chơi mới với Attempt ID UUID v4 mới.
  Future<AttemptLifecycleResult> restartActiveAttempt() async {
    if (_isRestarting) return AttemptLifecycleResult.invalidLifecycleState;
    if (!state.isPlaying) return AttemptLifecycleResult.invalidLifecycleState;

    // Nếu bàn cờ đang ở trạng thái ban đầu (chưa đặt quả bóng nào hoặc đã hoàn tác hết):
    // Miễn phí 100% (0 Energy), reset màn chơi không tiêu tốn Energy.
    if (!state.hasPlacedBalls) {
      return replayLevel();
    }

    _isRestarting = true;
    try {
      final oldAttemptId = state.attemptId;

      // 1. Tiêu thụ 1 Energy nguyên tử gắn với attemptId cũ và reason 'restart'
      final newEnergy = await ref
          .read(dailyEnergyNotifierProvider.notifier)
          .consumeEnergy(
            amount: 1,
            attemptId: oldAttemptId,
            reason: 'restart',
          );

      // Nếu Energy = 0 hoặc không đủ: Giữ nguyên bàn chơi và active session
      if (newEnergy == null) {
        state = state.copyWith(
          errorMessage:
              'Bạn đã hết Năng lượng (0/${DailyEnergyRepository.maxDailyEnergy}). Cần Năng lượng để chơi lại!',
        );
        return AttemptLifecycleResult.insufficientEnergy;
      }

      // 2. Trừ Energy thành công -> Kết thúc attempt cũ, dọn session cũ trên đĩa
      _sessionGeneration++;
      _isRequestingHint = false;
      _isHandlingGameOver = false;

      await _sessionRepository.clearActiveSessionIfMatches(
        expectedAttemptId: oldAttemptId,
      );

      // 3. Khởi tạo attempt mới với Attempt ID UUID v4 mới
      final level = _currentLevel ??
          ref.read(levelRepositoryProvider).getLevelByOverallIndex(1)!;

      state = _createInitialStateForLevel(
        level,
        attemptId: UuidGenerator.generateV4(),
        isInitializing: false,
      );

      _autoSave();
      // Phát âm thanh replay / restart
      ref.read(gameAudioServiceProvider).playReplay();
      return AttemptLifecycleResult.success;
    } catch (_) {
      return AttemptLifecycleResult.persistenceFailure;
    } finally {
      _isRestarting = false;
    }
  }

  /// Thử lại sau khi thua cuộc (Retry).
  /// Điều kiện: Ván chơi trước đã kết thúc với trạng thái `gameOver` và còn Energy > 0.
  /// - Nếu Energy <= 0: Từ chối retry và trả về `insufficientEnergy`.
  /// - Sinh Attempt ID (UUID v4) mới độc lập và khởi tạo bàn cờ ban đầu.
  Future<AttemptLifecycleResult> retryFailedAttempt() async {
    if (_isRestarting) return AttemptLifecycleResult.invalidLifecycleState;
    if (!state.isGameOver) return AttemptLifecycleResult.invalidLifecycleState;

    final currentEnergy =
        await ref.read(dailyEnergyRepositoryProvider).getRemainingEnergy();
    if (currentEnergy <= 0) {
      state = state.copyWith(
        errorMessage:
            'Bạn đã hết Năng lượng (0/${DailyEnergyRepository.maxDailyEnergy}). Cần Năng lượng để thử lại!',
      );
      return AttemptLifecycleResult.insufficientEnergy;
    }

    _isRestarting = true;
    try {
      final oldAttemptId = state.attemptId;
      _sessionGeneration++;
      _isRequestingHint = false;
      _isHandlingGameOver = false;

      // 1. Dọn session thất bại cũ trên đĩa nếu khớp attemptId
      await _sessionRepository.clearActiveSessionIfMatches(
        expectedAttemptId: oldAttemptId,
      );

      // 2. Khởi tạo attempt mới độc lập với Attempt ID UUID v4 mới
      final level = _currentLevel ??
          ref.read(levelRepositoryProvider).getLevelByOverallIndex(1)!;

      state = _createInitialStateForLevel(
        level,
        attemptId: UuidGenerator.generateV4(),
        isInitializing: false,
      );

      _autoSave();
      // Phát âm thanh replay / restart
      ref.read(gameAudioServiceProvider).playReplay();
      return AttemptLifecycleResult.success;
    } catch (_) {
      return AttemptLifecycleResult.persistenceFailure;
    } finally {
      _isRestarting = false;
    }
  }

  /// Chủ động bỏ cuộc ván chơi đang dở dang (Abandon) — Tiêu thụ ĐÚNG 1 Energy.
  /// Điều kiện: Ván chơi đang ở trạng thái `playing`.
  /// - Nếu Energy = 0: Trả về `insufficientEnergy`, KHÔNG trừ Energy âm, KHÔNG xóa session.
  /// - Nếu Energy > 0: Tiêu thụ nguyên tử đúng 1 Energy gắn với attemptId cũ (chống trừ trùng).
  /// - Xóa active session trên đĩa, kết thúc Attempt, KHÔNG tạo attempt mới.
  Future<AttemptLifecycleResult> abandonActiveAttempt() async {
    if (_isAbandoning) return AttemptLifecycleResult.invalidLifecycleState;
    if (!state.isPlaying) return AttemptLifecycleResult.invalidLifecycleState;

    _isAbandoning = true;
    try {
      final oldAttemptId = state.attemptId;

      // 1. Tiêu thụ 1 Energy nguyên tử gắn với attemptId cũ và reason 'abandon'
      final newEnergy = await ref
          .read(dailyEnergyNotifierProvider.notifier)
          .consumeEnergy(
            amount: 1,
            attemptId: oldAttemptId,
            reason: 'abandon',
          );

      // Nếu Energy = 0: Giữ nguyên session và bàn chơi
      if (newEnergy == null) {
        state = state.copyWith(
          errorMessage:
              'Bạn đã hết Năng lượng (0/${DailyEnergyRepository.maxDailyEnergy}). Không thể bỏ cuộc!',
        );
        return AttemptLifecycleResult.insufficientEnergy;
      }

      // 2. Trừ Energy thành công -> Xóa active session trên đĩa an toàn
      _sessionGeneration++;
      _isRequestingHint = false;
      _isHandlingGameOver = false;

      await _sessionRepository.clearActiveSessionIfMatches(
        expectedAttemptId: oldAttemptId,
      );

      return AttemptLifecycleResult.success;
    } catch (_) {
      return AttemptLifecycleResult.persistenceFailure;
    } finally {
      _isAbandoning = false;
    }
  }

  /// Phương thức điều phối tương thích ngược (Legacy Routing):
  /// - Nếu game đang completed -> replayLevel() (0 Energy)
  /// - Nếu game đang gameOver -> retryFailedAttempt() (0 Energy thêm)
  /// - Nếu game đang playing -> restartActiveAttempt() (1 Energy)
  Future<bool> restartLevel() async {
    if (state.isCompleted) {
      final res = await replayLevel();
      return res.isSuccess;
    } else if (state.isGameOver) {
      final res = await retryFailedAttempt();
      return res.isSuccess;
    } else if (state.isPlaying) {
      final res = await restartActiveAttempt();
      return res.isSuccess;
    }
    return false;
  }

  /// Yêu cầu một gợi ý (Hint) cho nước đi tiếp theo.
  /// Tuân thủ quy trình kiểm tra 8 bước của Sub-phase 5.1 và bảo vệ Race Condition:
  /// 1. Chỉ cho phép khi game đang playing và không có hint request nào đang xử lý dở dang.
  /// 2. Kiểm tra bàn cờ còn node chưa tô màu.
  /// 3. Nếu Hint vẫn đang hiển thị, không tiêu thụ thêm quota.
  /// 4. Tìm nghiệm và xác định HintResult bằng CspSolver.
  /// 5. Nếu không tìm được gợi ý, không trừ quota và không tăng hintsUsed.
  /// 6. Gọi consumeHint() nguyên tử.
  /// 7. Nếu thành công:
  ///    - Kiểm tra snapshot bàn cờ: nếu bàn cờ thay đổi trong lúc chờ await, không hiển thị hint cũ.
  ///    - Thử tạo hint mới trên bàn cờ hiện tại nếu còn hợp lệ.
  ///    - Tăng hintsUsed đúng 1.
  /// 8. Nếu hết quota: thông báo phù hợp và không thay đổi hintsUsed.
  Future<void> requestHint() async {
    // 1. Chỉ cho phép khi game đang playing
    if (!state.isPlaying) return;

    // Ngăn chặn race condition khi người chơi bấm nút Hint liên tục (rapid double-tap)
    if (_isRequestingHint) return;
    _isRequestingHint = true;

    try {
      // 2. Kiểm tra bàn cờ còn node chưa tô màu và không bị khóa
      final hasUncolored = state.graph.nodes.values
          .any((node) => node.currentColor == null && !node.isLocked);
      if (!hasUncolored) {
        state = state.copyWith(errorMessage: 'Tất cả các node đã được tô màu!');
        return;
      }

      // 3. Nếu Hint vẫn đang hiển thị và người chơi chưa thực hiện nước đi,
      // không tiêu thụ thêm quota khi bấm lại.
      if (state.hasActiveHint) {
        state = state.copyWith(
          errorMessage:
              'Gợi ý hiện tại: Hãy tô màu ${state.hintedColor!.label} cho node ${state.hintedNodeId}.',
        );
        return;
      }

      // 4. Tìm nghiệm và xác định HintResult từ trạng thái bàn cờ hiện tại
      final snapshotGraph = state.graph;
      final hintResult = _hintService.generateHint(
        graph: snapshotGraph,
        inventory: state.inventory,
      );

      // 5. Nếu không tìm được gợi ý, không trừ quota và không tăng hintsUsed
      if (hintResult == null) {
        state = state.copyWith(
          errorMessage:
              'Không tìm thấy lời giải hợp lệ từ thế cờ hiện tại. Hãy thử Hoàn tác (Undo) hoặc Chơi lại!',
        );
        return;
      }

      // 6. Gọi consumeHint() nguyên tử qua DailyHintNotifier
      final gen = _sessionGeneration;
      final newQuota =
          await ref.read(dailyHintNotifierProvider.notifier).consumeHint();

      // Hủy kết quả nếu trong lúc chờ await người chơi đã restart hoặc đổi level
      if (gen != _sessionGeneration || !state.isPlaying) return;

      // 7. Nếu consumeHint() thành công
      if (newQuota != null) {
        // Kiểm tra race condition: Trạng thái bàn cờ có bị thay đổi trong lúc chờ await không?
        if (state.graph != snapshotGraph) {
          // Bàn cờ đã thay đổi (người chơi đã tô/xóa/undo trong lúc chờ).
          // TUYỆT ĐỐI không hiển thị hint của bàn cờ cũ!
          // Vì quota đã bị trừ nên vẫn phải ghi nhận hintsUsed.
          if (!state.isPlaying || state.graph.isAllColored) {
            state = state.copyWith(hintsUsed: state.hintsUsed + 1);
            _autoSave();
            return;
          }

          // Thử tạo gợi ý mới cho trạng thái bàn cờ mới nhất
          final freshHint = _hintService.generateHint(
            graph: state.graph,
            inventory: state.inventory,
          );

          if (freshHint != null) {
            state = state.copyWith(
              hintsUsed: state.hintsUsed + 1,
              hintedNodeId: freshHint.nodeId,
              hintedColor: freshHint.color,
              errorMessage:
                  'Gợi ý: Hãy tô màu ${freshHint.color.label} cho node ${freshHint.nodeId}.',
            );
            _autoSave();
            // Phát âm thanh hint
            ref.read(gameAudioServiceProvider).playHint();
            return;
          } else {
            state = state.copyWith(
              hintsUsed: state.hintsUsed + 1,
              clearHint: true,
              errorMessage:
                  'Bàn cờ đã thay đổi và không còn lời giải hợp lệ từ thế cờ này.',
            );
          }
          _autoSave();
          return;
        }

        // Bàn cờ không thay đổi: Cập nhật gợi ý chuẩn xác
        state = state.copyWith(
          hintsUsed: state.hintsUsed + 1,
          hintedNodeId: hintResult.nodeId,
          hintedColor: hintResult.color,
          errorMessage:
              'Gợi ý: Hãy tô màu ${hintResult.color.label} cho node ${hintResult.nodeId}.',
        );
        _autoSave();
        // Phát âm thanh hint
        ref.read(gameAudioServiceProvider).playHint();
      } else {
        // 8. Nếu hết quota trong ngày
        state = state.copyWith(
          errorMessage:
              'Bạn đã dùng hết lượt gợi ý miễn phí hôm nay! Hãy xem quảng cáo để nhận thêm.',
        );
      }
    } finally {
      _isRequestingHint = false;
    }
  }

  /// Điểm tích hợp Continue (Phase D4 & D5): Nhận thêm 2 lượt lỗi khi xem quảng cáo trả thưởng.
  /// - Chỉ cho phép tối đa 1 lần tiếp tục cho mỗi Attempt (hasUsedContinue = true).
  /// - Khôi phục remainingMistakes = 2, chuyển trạng thái về playing.
  /// - Giữ nguyên toàn bộ thế cờ hiện tại và lịch sử Undo.
  bool continueSessionWithExtraMistakes() {
    if (state.hasUsedContinue) return false;

    _isHandlingGameOver = false;
    state = state.copyWith(
      remainingMistakes: 2,
      hasUsedContinue: true,
      status: GameStatus.playing,
      clearErrorMessage: true,
    );
    _autoSave();
    return true;
  }

  /// Xóa thông báo lỗi tạm thời trên UI.
  void clearErrorMessage() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearErrorMessage: true);
    }
  }
}

/// Provider cung cấp GameController và GameViewState.
final gameControllerProvider =
    NotifierProvider<GameController, GameViewState>(GameController.new);
