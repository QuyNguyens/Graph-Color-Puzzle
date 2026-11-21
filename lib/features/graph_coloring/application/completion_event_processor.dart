import 'dart:async';

import '../../campaign/application/campaign_notifier.dart';
import '../../campaign/domain/entities/puzzle_level.dart';
import '../data/datasources/pending_completion_local_datasource.dart';
import '../domain/entities/color_inventory.dart';
import '../domain/entities/game_move.dart';
import '../domain/entities/graph.dart';
import '../domain/entities/level_completion_event.dart';
import '../domain/repositories/daily_challenge_repository.dart';
import '../domain/repositories/game_session_repository.dart';

/// Application Service độc lập điều phối quy trình hoàn thành màn chơi (Completion Flow)
/// và xử lý hàng đợi Outbox với bảo vệ tính toàn vẹn giao dịch hai pha.
class CompletionEventProcessor {
  CompletionEventProcessor({
    required GameSessionRepository sessionRepository,
    required PendingCompletionLocalDataSource outboxDataSource,
    required DailyChallengeRepository challengeRepository,
    required CampaignNotifier campaignNotifier,
    DateTime Function()? nowProvider,
  })  : _sessionRepository = sessionRepository,
        _outboxDataSource = outboxDataSource,
        _challengeRepository = challengeRepository,
        _campaignNotifier = campaignNotifier,
        _nowProvider = nowProvider ?? DateTime.now;

  final GameSessionRepository _sessionRepository;
  final PendingCompletionLocalDataSource _outboxDataSource;
  final DailyChallengeRepository _challengeRepository;
  final CampaignNotifier _campaignNotifier;
  final DateTime Function() _nowProvider;

  // Hàng đợi tuần tự (Mutex FIFO) đảm bảo các completion events được xử lý tuần tự,
  // loại trừ race condition khi hoàn thành dồn dập hoặc giữa gameplay và startup recovery.
  Future<dynamic> _processingQueue = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _processingQueue = _processingQueue.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  /// Xử lý ván chơi vừa chiến thắng theo đúng trình tự bắt buộc 4 bước:
  /// 1. Persist Completed Session xuống đĩa (kèm attemptId, completedAtIso, earnedStars).
  /// 2. Enqueue Completion Event vào Outbox (PendingCompletionLocalDataSource).
  /// 3. Clear Active Session (chỉ chạy sau khi enqueue thành công).
  /// 4. Phân phối Event: Campaign -> Daily Challenge -> Dequeue Outbox.
  Future<bool> processWinningGame({
    required PuzzleLevel level,
    required Graph graph,
    required ColorInventory inventory,
    required int remainingMistakes,
    required int mistakesCount,
    required int hintsUsed,
    required bool hasUsedContinue,
    required List<GameMove> undoHistory,
    required String attemptId,
    required int earnedStars,
  }) {
    return _synchronized(() async {
      final now = _nowProvider();
      final timestampIso = now.toIso8601String();
      final completedDate = timestampIso.substring(0, 10);

      // BƯỚC 1: Persist Completed Session
      final sessionSaved = await _sessionRepository.saveActiveSession(
        levelId: level.id,
        graph: graph,
        remainingMistakes: remainingMistakes,
        mistakesCount: mistakesCount,
        hintsUsed: hintsUsed,
        hasUsedContinue: hasUsedContinue,
        undoHistory: undoHistory,
        attemptId: attemptId,
        completedAtIso: timestampIso,
        earnedStars: earnedStars,
      );

      if (!sessionSaved) {
        // Ghi session thất bại -> Dừng, không xóa session, không phân phối event
        return false;
      }

      // BƯỚC 2: Enqueue Completion Event vào Outbox
      final event = LevelCompletionEvent(
        attemptId: attemptId,
        levelId: level.id,
        earnedStars: earnedStars,
        hintsUsed: hintsUsed,
        mistakesCount: mistakesCount,
        completedDate: completedDate,
        timestampIso: timestampIso,
      );

      final bool enqueued;
      try {
        enqueued = await _outboxDataSource.enqueue(event);
      } on OutboxPayloadConflictException catch (_) {
        // Xung đột payload trong Outbox: Dừng ngay lập tức, không xóa session, không phân phối event
        return false;
      }

      if (!enqueued) {
        // Ghi Outbox thất bại -> Giữ Completed Session trên đĩa để recovery sau
        return false;
      }

      // BƯỚC 3: Clear Active Session có điều kiện (chỉ xóa nếu đúng attemptId của ván thắng)
      // Enqueue đã thành công trên đĩa -> Xóa Active Session
      await _sessionRepository.clearActiveSessionIfMatches(
        expectedAttemptId: attemptId,
      );

      // BƯỚC 4: Process Event (Campaign -> Daily Challenge -> Dequeue Outbox)
      return await _processEventInternal(event);
    });
  }

  /// Xử lý nội bộ phân phối một Event theo thứ tự nghiêm ngặt:
  /// 1. CampaignNotifier.recordLevelCompletion()
  /// 2. DailyChallengeRepository.recordCompletion()
  /// 3. PendingCompletionLocalDataSource.dequeue()
  Future<bool> _processEventInternal(LevelCompletionEvent event) async {
    // 4.1. Cập nhật Campaign Progress
    final campResult = await _campaignNotifier.recordLevelCompletion(
      levelId: event.levelId,
      mistakesCount: event.mistakesCount,
      hintsUsed: event.hintsUsed,
    );

    if (campResult == null) {
      // Campaign lưu đĩa thất bại -> Dừng, không gọi Challenge, không dequeue
      return false;
    }

    // 4.2. Cập nhật Daily Challenges
    // Repository tự kiểm tra: nếu completedDate != today thì bỏ qua an toàn và trả về true
    final challengeRecorded = await _challengeRepository.recordCompletion(event);
    if (!challengeRecorded) {
      // Challenge lưu đĩa thất bại -> Dừng, không dequeue
      return false;
    }

    // 4.3. Dequeue Event khỏi Outbox sau khi tất cả các bước đã hoàn tất
    final dequeued = await _outboxDataSource.dequeue(event.attemptId);
    return dequeued;
  }

  /// Quét và xử lý toàn bộ các sự kiện tồn đọng trong Outbox.
  /// Sẵn sàng phục vụ cho Startup Recovery trong Sub-phase 5.3.2.3.
  Future<bool> drainPendingOutbox() {
    return _synchronized(() async {
      final pendingEvents = await _outboxDataSource.getPendingEvents();
      if (pendingEvents.isEmpty) {
        return true;
      }

      var allSuccess = true;
      for (final event in pendingEvents) {
        final success = await _processEventInternal(event);
        if (!success) {
          allSuccess = false;
          // Dừng lại ở event đầu tiên gặp lỗi để bảo toàn thứ tự FIFO
          break;
        }
      }
      return allSuccess;
    });
  }
}

