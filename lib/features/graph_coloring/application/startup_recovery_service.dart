import '../../campaign/domain/repositories/campaign_progress_repository.dart';
import '../data/datasources/pending_completion_local_datasource.dart';
import '../domain/entities/active_session_metadata_result.dart';
import '../domain/entities/level_completion_event.dart';
import '../domain/repositories/daily_challenge_repository.dart';
import '../domain/repositories/game_session_repository.dart';
import 'completion_event_processor.dart';
import 'startup_recovery_state.dart';

/// Hàm ủy quyền kiểm tra metadata session trên đĩa.
/// Cho phép tiêm phụ thuộc kiểm tra metadata trước khi contract chính thức được bổ sung vào GameSessionRepository ở Sub-phase 5.3.2.3.2.
typedef SessionMetadataInspector = Future<ActiveSessionMetadataResult> Function();

/// Application Service điều phối quy trình Startup Recovery và đảm bảo tính nhất quán dữ liệu sau crash.
/// Tầng Application Layer.
class StartupRecoveryService {
  StartupRecoveryService({
    required GameSessionRepository sessionRepository,
    required PendingCompletionLocalDataSource outboxDataSource,
    required DailyChallengeRepository challengeRepository,
    required CampaignProgressRepository campaignProgressRepository,
    required CompletionEventProcessor completionProcessor,
    SessionMetadataInspector? metadataInspector,
    DateTime Function()? nowProvider,
  })  : _sessionRepository = sessionRepository,
        _outboxDataSource = outboxDataSource,
        _challengeRepository = challengeRepository,
        _campaignProgressRepository = campaignProgressRepository,
        _completionProcessor = completionProcessor,
        _metadataInspector = metadataInspector,
        _nowProvider = nowProvider ?? DateTime.now;

  final GameSessionRepository _sessionRepository;
  final PendingCompletionLocalDataSource _outboxDataSource;
  final DailyChallengeRepository _challengeRepository;
  final CampaignProgressRepository _campaignProgressRepository;
  final CompletionEventProcessor _completionProcessor;
  final SessionMetadataInspector? _metadataInspector;
  final DateTime Function() _nowProvider;

  String _getTodayString() {
    return _nowProvider().toIso8601String().substring(0, 10);
  }

  /// Thực thi toàn bộ chu trình phục hồi sự cố khi ứng dụng khởi động.
  /// Tuân thủ quy trình 5 bước A -> E và cơ chế Fail-Safe bảo toàn dữ liệu.
  Future<StartupRecoveryState> runRecovery() async {
    try {
      // BƯỚC A: Đọc và thẩm định Active Session Metadata
      final metadataResult = await (_metadataInspector?.call() ??
          _sessionRepository.getActiveSessionMetadata());

      // BƯỚC B & C: Phân loại và xử lý theo từng subtype
      return await _handleMetadataResult(metadataResult);
    } catch (e) {
      // Bắt mọi ngoại lệ I/O hoặc storage, chuyển sang failedSafe, TUYỆT ĐỐI không xóa session
      return StartupRecoveryState(
        status: RecoveryStatus.failedSafe,
        errorMessage: 'Lỗi phục hồi sự cố: $e',
      );
    }
  }

  Future<StartupRecoveryState> _handleMetadataResult(
    ActiveSessionMetadataResult result,
  ) async {
    switch (result) {
      // TRƯỜNG HỢP 1: Không có session trên đĩa
      case NoActiveSessionResult():
        return await _drainOutboxAndComplete();

      // TRƯỜNG HỢP 2: Ván chơi dở dang hợp lệ (đang chơi)
      case ValidPlayingSessionResult():
        // Giữ nguyên session trên đĩa cho Continue, chỉ drain Outbox nếu có event tồn đọng
        return await _drainOutboxAndComplete();

      // TRƯỜNG HỢP 3: Ván chơi đã thắng hợp lệ (cần phân phối và dọn đĩa an toàn)
      case ValidCompletedSessionResult():
        return await _handleCompletedSession(result);

      // TRƯỜNG HỢP 4: Metadata bị lỗi / hỏng cú pháp
      case CorruptedSessionMetadataResult():
        // Chuyển sang failedSafe, BẢO TOÀN DỮ LIỆU, KHÔNG CLEAR SESSION
        return StartupRecoveryState(
          status: RecoveryStatus.failedSafe,
          blockedLevelId: result.rawLevelId,
          errorMessage: 'Dữ liệu phiên chơi bị lỗi: ${result.reason}',
        );

      // TRƯỜNG HỢP 5: Lỗi truy cập bộ nhớ tạm thời (I/O, storage channel failure)
      case TransientSessionMetadataErrorResult():
        // Chuyển sang failedSafe, BẢO TOÀN DỮ LIỆU, TUYỆT ĐỐI KHÔNG XÓA SESSION
        return StartupRecoveryState(
          status: RecoveryStatus.failedSafe,
          errorMessage: 'Lỗi truy cập bộ nhớ tạm thời: ${result.reason}',
        );
    }
  }

  /// Xử lý ván chơi đã hoàn thành còn lưu trên đĩa với bảo vệ Ghost Session đa nguồn
  Future<StartupRecoveryState> _handleCompletedSession(
    ValidCompletedSessionResult session,
  ) async {
    final attemptId = session.attemptId;
    final levelId = session.levelId;

    // 1. Kiểm tra xem Event đã nằm trong Outbox chưa
    final pendingEvents = await _outboxDataSource.getPendingEvents();
    final alreadyInOutbox = pendingEvents.any((e) => e.attemptId == attemptId);

    if (alreadyInOutbox) {
      // Event đã an toàn trong Outbox -> Chỉ cần dọn sạch Active Session trên đĩa nếu đúng attemptId
      final clearSuccess = await _sessionRepository.clearActiveSessionIfMatches(
        expectedAttemptId: attemptId,
      );
      if (!clearSuccess) {
        return StartupRecoveryState(
          status: RecoveryStatus.blocked,
          blockedLevelId: levelId,
          errorMessage:
              'Chiến thắng đã lưu Outbox nhưng không thể dọn dẹp ván chơi trên bộ nhớ.',
          pendingEventsCount: pendingEvents.length,
        );
      }
      return await _drainOutboxAndComplete();
    }

    // 2. Event chưa có trong Outbox: Phân định Ghost Session Cùng Ngày vs Khác Ngày
    final today = _getTodayString();
    final completedDate = session.completedAtIso.length >= 10
        ? session.completedAtIso.substring(0, 10)
        : today;
    final isSameDay = completedDate == today;

    if (isSameDay) {
      // 2.1. CÙNG NGÀY: Kiểm tra Daily Challenge State
      final challengeState = await _challengeRepository.getDailyChallengeState();
      if (challengeState.date == today &&
          challengeState.isAttemptProcessed(attemptId)) {
        // GHOST CÙNG NGÀY: Đã phân phối xong hoàn toàn trong ngày hôm nay!
        // Hành động: Dọn dẹp session trên đĩa nếu đúng attemptId, TUYỆT ĐỐI KHÔNG re-enqueue vào Outbox
        final clearSuccess = await _sessionRepository.clearActiveSessionIfMatches(
          expectedAttemptId: attemptId,
        );
        if (!clearSuccess) {
          return StartupRecoveryState(
            status: RecoveryStatus.blocked,
            blockedLevelId: levelId,
            errorMessage:
                'Ghost Session đã hoàn tất nhưng không thể dọn dẹp bộ nhớ.',
            pendingEventsCount: pendingEvents.length,
          );
        }
        return await _drainOutboxAndComplete();
      }
    } else {
      // 2.2. KHÁC NGÀY: Kiểm tra Campaign Progress
      final campaignProgress = await _campaignProgressRepository.loadProgress();
      final levelProgress = campaignProgress.getLevelProgress(levelId);
      final isOutcomeEquivalent = levelProgress.isCompleted &&
          levelProgress.bestStars >= session.earnedStars;

      if (isOutcomeEquivalent) {
        // GHOST KHÁC NGÀY: Campaign đã đạt mốc sao tối ưu từ trước, Daily Challenge ngày cũ đã hết hạn.
        // Bằng chứng tương đương kết quả (Outcome Equivalence).
        // Hành động: Dọn dẹp session trên đĩa nếu đúng attemptId, TUYỆT ĐỐI KHÔNG re-enqueue (chặn Infinite Re-enqueue Loop).
        final clearSuccess = await _sessionRepository.clearActiveSessionIfMatches(
          expectedAttemptId: attemptId,
        );
        if (!clearSuccess) {
          return StartupRecoveryState(
            status: RecoveryStatus.blocked,
            blockedLevelId: levelId,
            errorMessage:
                'Ghost Session ngày cũ không thể dọn dẹp bộ nhớ.',
            pendingEventsCount: pendingEvents.length,
          );
        }
        return await _drainOutboxAndComplete();
      }
    }

    // 2.3. CHƯA PHÂN PHỐI: Tái tạo LevelCompletionEvent và đưa vào Outbox
    final event = LevelCompletionEvent(
      attemptId: attemptId,
      levelId: levelId,
      earnedStars: session.earnedStars,
      hintsUsed: session.hintsUsed,
      mistakesCount: session.mistakesCount,
      completedDate: completedDate,
      timestampIso: session.completedAtIso,
    );

    // Ghi bền vững vào Outbox trước (bắt ngoại lệ xung đột payload nếu có)
    final bool enqueueSuccess;
    try {
      enqueueSuccess = await _outboxDataSource.enqueue(event);
    } on OutboxPayloadConflictException catch (e) {
      return StartupRecoveryState(
        status: RecoveryStatus.blocked,
        blockedLevelId: levelId,
        errorMessage:
            'Xung đột dữ liệu Outbox cho attempt $attemptId: $e. Đã khóa để bảo vệ dữ liệu.',
        pendingEventsCount: pendingEvents.length,
      );
    }

    if (!enqueueSuccess) {
      // Ghi Outbox thất bại -> BẢO TOÀN DỮ LIỆU GỐC, KHÔNG XÓA ACTIVE SESSION
      return StartupRecoveryState(
        status: RecoveryStatus.blocked,
        blockedLevelId: levelId,
        errorMessage:
            'Không thể lưu sự kiện chiến thắng vào hàng đợi Outbox. Đã khóa để bảo vệ dữ liệu.',
        pendingEventsCount: pendingEvents.length,
      );
    }

    // Sau khi enqueue thành công -> Dọn dẹp Active Session trên đĩa có điều kiện
    final clearSuccess = await _sessionRepository.clearActiveSessionIfMatches(
      expectedAttemptId: attemptId,
    );
    if (!clearSuccess) {
      return StartupRecoveryState(
        status: RecoveryStatus.blocked,
        blockedLevelId: levelId,
        errorMessage:
            'Chiến thắng đã lưu Outbox an toàn nhưng chưa thể dọn dẹp ván chơi trên đĩa.',
        pendingEventsCount: pendingEvents.length + 1,
      );
    }

    // BƯỚC E: Drain Outbox và hoàn tất
    return await _drainOutboxAndComplete();
  }

  /// Quét sạch các sự kiện tồn đọng trong Outbox và chuyển trạng thái sang ready
  Future<StartupRecoveryState> _drainOutboxAndComplete() async {
    // Gọi CompletionEventProcessor để phân phối tuần tự Outbox dưới khóa Mutex
    await _completionProcessor.drainPendingOutbox();

    final remainingEvents = await _outboxDataSource.getPendingEvents();
    return StartupRecoveryState(
      status: RecoveryStatus.ready,
      pendingEventsCount: remainingEvents.length,
    );
  }
}
