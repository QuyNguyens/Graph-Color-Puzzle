import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/level_completion_event.dart';
import '../models/pending_completion_event_dto.dart';

/// Ngoại lệ phát sinh khi enqueue một completion event có cùng attemptId
/// nhưng payload khác biệt so với event đã tồn tại trong Outbox.
class OutboxPayloadConflictException implements Exception {
  const OutboxPayloadConflictException({
    required this.attemptId,
    required this.existingEvent,
    required this.conflictingEvent,
  });

  final String attemptId;
  final LevelCompletionEvent existingEvent;
  final LevelCompletionEvent conflictingEvent;

  @override
  String toString() =>
      'OutboxPayloadConflictException: attemptId=$attemptId đã tồn tại trong Outbox nhưng payload không đồng nhất.';
}

/// DataSource quản lý hàng đợi Outbox (Pending Completion Events) trên SharedPreferences.
/// Sử dụng hàng đợi tuần tự (Mutex) đảm bảo mọi thao tác đọc-sửa-ghi luôn nguyên tử.
/// Tầng Data Layer.
class PendingCompletionLocalDataSource {
  PendingCompletionLocalDataSource({SharedPreferences? preferences})
      : _prefs = preferences;

  final SharedPreferences? _prefs;
  static const String _outboxKey = 'key_pending_challenge_events_v1';

  // Hàng đợi tuần tự (Mutex) serialize toàn bộ tác vụ Outbox
  Future<dynamic> _operationQueue = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<List<LevelCompletionEvent>> _readEvents() async {
    final prefs = await _getPrefs();
    final rawJson = prefs.getString(_outboxKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return [];
    }

    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! List<dynamic>) return [];

      return decoded
          .map((item) =>
              PendingCompletionEventDto.fromJson(item as Map<String, dynamic>)
                  .toEntity())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> _writeEvents(List<LevelCompletionEvent> events) async {
    try {
      final prefs = await _getPrefs();
      final dtos =
          events.map(PendingCompletionEventDto.fromEntity).map((d) => d.toJson()).toList();
      final rawJson = jsonEncode(dtos);
      final success = await prefs.setString(_outboxKey, rawJson);
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Đọc danh sách sự kiện hoàn thành đang tồn đọng trong Outbox.
  Future<List<LevelCompletionEvent>> getPendingEvents() {
    return _synchronized(() => _readEvents());
  }

  /// Đẩy một sự kiện hoàn thành vào Outbox.
  /// - Case A (Chưa tồn tại attemptId): Thêm event, lưu đĩa, trả về boolean từ SharedPreferences.
  /// - Case B (Đã tồn tại attemptId và payload đồng nhất): Idempotent success, trả về `true`.
  /// - Case C (Đã tồn tại attemptId nhưng payload khác biệt): Ném `OutboxPayloadConflictException`,
  ///   tuyệt đối không ghi đè, không xóa, bảo toàn 100% Outbox hiện tại.
  Future<bool> enqueue(LevelCompletionEvent event) {
    return _synchronized(() async {
      final events = await _readEvents();

      final existingIndex =
          events.indexWhere((e) => e.attemptId == event.attemptId);
      if (existingIndex != -1) {
        final existingEvent = events[existingIndex];
        // So sánh toàn bộ 7 trường nghiệp vụ thông qua operator == của LevelCompletionEvent:
        // (attemptId, levelId, earnedStars, hintsUsed, mistakesCount, completedDate, timestampIso)
        if (existingEvent == event) {
          return true; // Case B: Idempotent success (payload hoàn toàn đồng nhất)
        } else {
          // Case C: Xung đột payload
          throw OutboxPayloadConflictException(
            attemptId: event.attemptId,
            existingEvent: existingEvent,
            conflictingEvent: event,
          );
        }
      }

      // Case A: Chưa tồn tại attemptId
      events.add(event);
      final success = await _writeEvents(events);
      return success;
    });
  }

  /// Xóa sự kiện khỏi Outbox sau khi các hệ thống đã xử lý và lưu đĩa thành công.
  /// - Idempotent: Nếu không tìm thấy `attemptId`, coi như đã xóa và trả về `true`.
  /// - Kiểm tra boolean trả về từ SharedPreferences.
  Future<bool> dequeue(String attemptId) {
    return _synchronized(() async {
      final events = await _readEvents();
      final initialLength = events.length;
      events.removeWhere((e) => e.attemptId == attemptId);

      if (events.length == initialLength) {
        return true; // Không còn trong Outbox -> Idempotent success
      }

      final success = await _writeEvents(events);
      return success;
    });
  }

  /// Dọn sạch toàn bộ Outbox (dùng cho debug/test).
  Future<bool> clearAll() {
    return _synchronized(() async {
      try {
        final prefs = await _getPrefs();
        final success = await prefs.remove(_outboxKey);
        return success;
      } catch (_) {
        return false;
      }
    });
  }
}

