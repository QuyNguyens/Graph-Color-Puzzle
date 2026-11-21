import 'dart:convert';

import '../../domain/entities/active_session_metadata_result.dart';
import '../../domain/entities/color_inventory.dart';
import '../../domain/entities/game_move.dart';
import '../../domain/entities/graph.dart';
import '../../domain/entities/puzzle_color.dart';
import '../../domain/repositories/game_session_repository.dart';
import '../../domain/services/attempt_id_validator.dart';
import '../../domain/services/uuid_generator.dart';
import '../datasources/game_session_local_datasource.dart';
import '../models/saved_session_dto.dart';

/// Implementation của GameSessionRepository.
/// Tầng Data Layer, xử lý Serialization, Validation, Schema v4 Migration và Fallback an toàn.
class GameSessionRepositoryImpl implements GameSessionRepository {
  const GameSessionRepositoryImpl({
    required GameSessionLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final GameSessionLocalDataSource _localDataSource;

  @override
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
  }) async {
    final effectiveAttemptId = (attemptId != null && attemptId.trim().isNotEmpty)
        ? attemptId
        : UuidGenerator.generateAttemptId(levelId);

    final nodeColors = <String, String?>{
      for (final node in graph.nodes.values) node.id: node.currentColor?.code,
    };

    final dto = SavedSessionDto(
      attemptId: effectiveAttemptId,
      levelId: levelId,
      nodeColors: nodeColors,
      remainingMistakes: remainingMistakes,
      mistakesCount: mistakesCount,
      hintsUsed: hintsUsed,
      hasUsedContinue: hasUsedContinue,
      hasUsedUndo: hasUsedUndo,
      undoHistory: undoHistory.map(SavedMoveDto.fromEntity).toList(),
      completedAtIso: completedAtIso,
      earnedStars: earnedStars,
    );

    final rawJson = jsonEncode(dto.toJson());
    return await _localDataSource.saveRawSession(rawJson);
  }

  @override
  Future<RestoredGameSession?> loadActiveSession({
    required String levelId,
    required Graph initialGraph,
    required Map<dynamic, int> initialTargets,
  }) async {
    try {
      final rawJson = await _localDataSource.getRawSession();
      if (rawJson == null || rawJson.trim().isEmpty) return null;

      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        // Root không hợp lệ -> Trả về null, TUYỆT ĐỐI không xóa session trên đĩa
        return null;
      }

      // 1. Kiểm tra định dạng Session: Legacy v1–v3 hay Schema v4
      final isLegacy = SavedSessionDto.isLegacyJson(decoded);
      final migratedAttemptId =
          isLegacy ? UuidGenerator.generateAttemptId(levelId) : null;

      final dto = SavedSessionDto.fromJson(
        decoded,
        assignedAttemptId: migratedAttemptId,
      );

      // 2. Kiểm tra levelId
      if (dto.levelId != levelId) {
        // Dữ liệu thuộc level khác, bỏ qua
        return null;
      }

      // Tạo map tra cứu màu theo code
      final colorMap = <String, PuzzleColor>{
        for (final key in initialTargets.keys)
          if (key is PuzzleColor) key.code: key,
      };

      // 3. Tái tạo Graph và kiểm tra tính toàn vẹn của Locked Nodes
      final restoredNodes = Map.of(initialGraph.nodes);
      for (final entry in dto.nodeColors.entries) {
        final nodeId = entry.key;
        final colorCode = entry.value;

        final initialNode = initialGraph.getNode(nodeId);
        if (initialNode == null) {
          // Node ID không tồn tại trong level gốc -> Data hỏng, giữ nguyên đĩa để xử lý ở bước sau
          return null;
        }

        if (initialNode.isLocked) {
          // Locked Node bắt buộc phải giữ nguyên màu cố định ban đầu
          if (colorCode != initialNode.currentColor?.code) {
            return null;
          }
        } else {
          // Node thường
          if (colorCode != null) {
            final puzzleColor = colorMap[colorCode];
            if (puzzleColor == null) {
              return null;
            }
            restoredNodes[nodeId] = initialNode.copyWith(currentColor: puzzleColor);
          } else {
            restoredNodes[nodeId] = initialNode.copyWith(clearColor: true);
          }
        }
      }

      final restoredGraph = Graph(
        nodes: restoredNodes,
        edges: initialGraph.edges,
      );

      // Kiểm tra xem trạng thái khôi phục có vi phạm kề nhau không
      if (restoredGraph.hasAnyConflict()) {
        return null;
      }

      // 4. Tái tạo ColorInventory dựa trên màu THỰC TẾ của các node
      final targetCounts = <PuzzleColor, int>{
        for (final entry in initialTargets.entries)
          if (entry.key is PuzzleColor) entry.key as PuzzleColor: entry.value,
      };

      final actualUsedCounts = <PuzzleColor, int>{
        for (final color in targetCounts.keys) color: 0,
      };

      for (final node in restoredGraph.nodes.values) {
        if (node.currentColor != null) {
          final c = node.currentColor!;
          actualUsedCounts[c] = (actualUsedCounts[c] ?? 0) + 1;
        }
      }

      // Kiểm tra số lượng thực tế không được vượt quá target
      for (final entry in targetCounts.entries) {
        final color = entry.key;
        final target = entry.value;
        final actual = actualUsedCounts[color] ?? 0;
        if (actual > target) {
          return null;
        }
      }

      final restoredInventory = ColorInventory(
        targetCounts: targetCounts,
        usedCounts: actualUsedCounts,
      );

      // 5. Tái tạo Undo History
      final restoredHistory = <GameMove>[];
      for (final moveDto in dto.undoHistory) {
        final prev = moveDto.previousColorCode != null
            ? colorMap[moveDto.previousColorCode]
            : null;
        final next = moveDto.newColorCode != null
            ? colorMap[moveDto.newColorCode]
            : null;

        restoredHistory.add(GameMove(
          nodeId: moveDto.nodeId,
          previousColor: prev,
          newColor: next,
          timestamp: DateTime.tryParse(moveDto.timestampIso) ?? DateTime.now(),
        ));
      }

      // 6. Kiểm tra số lỗi còn lại hợp lệ, tổng lỗi đã mắc và số gợi ý đã dùng
      final remainingMistakes = (dto.remainingMistakes >= 0 && dto.remainingMistakes <= 2)
          ? dto.remainingMistakes
          : 2;
      final mistakesCount = (dto.mistakesCount >= 0) ? dto.mistakesCount : 0;
      final hintsUsed = (dto.hintsUsed >= 0) ? dto.hintsUsed : 0;

      // 7. Migration Schema v4 CHỈ persist đĩa khi toàn bộ validation đã thành công vượt qua
      if (isLegacy) {
        final saveOk = await _localDataSource
            .saveRawSession(jsonEncode(dto.toJson()));
        if (!saveOk) {
          // Lưu đĩa thất bại -> Giữ nguyên dữ liệu cũ trên đĩa, không restore với attemptId tạm
          return null;
        }
      }

      return RestoredGameSession(
        attemptId: dto.attemptId,
        levelId: levelId,
        graph: restoredGraph,
        inventory: restoredInventory,
        remainingMistakes: remainingMistakes,
        mistakesCount: mistakesCount,
        hintsUsed: hintsUsed,
        hasUsedContinue: dto.hasUsedContinue,
        hasUsedUndo: dto.hasUsedUndo,
        undoHistory: restoredHistory,
        completedAtIso: dto.completedAtIso,
        earnedStars: dto.earnedStars,
      );
    } catch (_) {
      // Fallback an toàn: Trả về null khi gặp bất kỳ ngoại lệ nào, TUYỆT ĐỐI không xóa session trên đĩa
      return null;
    }
  }

  @override
  Future<String?> getActiveSessionLevelId() async {
    try {
      final rawJson = await _localDataSource.getRawSession();
      if (rawJson == null || rawJson.trim().isEmpty) return null;

      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return null;

      final levelId = decoded['level_id'] as String?;
      return (levelId != null && levelId.isNotEmpty) ? levelId : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ActiveSessionMetadataResult> getActiveSessionMetadata() async {
    // 1. Đọc raw JSON từ DataSource (bắt ngoại lệ I/O storage tạm thời)
    final String? rawJson;
    try {
      rawJson = await _localDataSource.getRawSession();
    } catch (e) {
      return TransientSessionMetadataErrorResult(
        reason: 'Lỗi truy cập storage tạm thời khi đọc raw session: $e',
        error: e,
      );
    }

    // 2. Không có dữ liệu trên đĩa
    if (rawJson == null || rawJson.trim().isEmpty) {
      return const NoActiveSessionResult();
    }

    // 3. Decode JSON (bắt FormatException phân loại lỗi JSON malformed)
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException catch (e) {
      return CorruptedSessionMetadataResult(
        reason: 'JSON cú pháp không hợp lệ (malformed JSON)',
        error: e,
      );
    } catch (e) {
      return CorruptedSessionMetadataResult(
        reason: 'Lỗi giải mã JSON: $e',
        error: e,
      );
    }

    // 4. Kiểm tra Root Object phải là Map<String, dynamic>
    if (decoded is! Map<String, dynamic>) {
      return const CorruptedSessionMetadataResult(
        reason: 'Root JSON không phải là Map<String, dynamic>',
      );
    }

    // 5. Kiểm tra level_id bắt buộc
    final rawLevelId = decoded['level_id'];
    if (rawLevelId is! String || rawLevelId.trim().isEmpty) {
      return const CorruptedSessionMetadataResult(
        reason: 'level_id thiếu hoặc không phải chuỗi ký tự hợp lệ',
      );
    }
    final levelId = rawLevelId.trim();

    // 6. Kiểm tra attempt_id bắt buộc sử dụng AttemptIdValidator
    final rawAttemptId = decoded['attempt_id'];
    if (rawAttemptId is! String ||
        !AttemptIdValidator.isValidAttemptId(rawAttemptId,
            expectedLevelId: levelId)) {
      return CorruptedSessionMetadataResult(
        reason: 'attempt_id không hợp lệ theo AttemptIdValidator',
        rawLevelId: levelId,
      );
    }
    final attemptId = rawAttemptId;

    // 7. Kiểm tra mistakesCount và hintsUsed
    final int mistakesCount;
    final rawMistakes = decoded['mistakes_count'];
    if (rawMistakes is int && rawMistakes >= 0) {
      mistakesCount = rawMistakes;
    } else if (decoded.containsKey('remaining_mistakes') &&
        decoded['remaining_mistakes'] is int) {
      final remaining = decoded['remaining_mistakes'] as int;
      mistakesCount = (2 - remaining).clamp(0, 2);
    } else {
      return CorruptedSessionMetadataResult(
        reason: 'mistakes_count thiếu hoặc không hợp lệ',
        rawLevelId: levelId,
      );
    }

    final int hintsUsed;
    final rawHints = decoded['hints_used'];
    if (rawHints is int && rawHints >= 0) {
      hintsUsed = rawHints;
    } else if (!decoded.containsKey('hints_used')) {
      hintsUsed = 0;
    } else {
      return CorruptedSessionMetadataResult(
        reason: 'hints_used không hợp lệ',
        rawLevelId: levelId,
      );
    }

    // 8. Phân loại Playing Session vs Completed Session
    final hasCompletedAt =
        decoded.containsKey('completed_at') && decoded['completed_at'] != null;
    final hasEarnedStars =
        decoded.containsKey('earned_stars') && decoded['earned_stars'] != null;

    if (hasCompletedAt != hasEarnedStars) {
      return CorruptedSessionMetadataResult(
        reason:
            'Dữ liệu hoàn thành không đồng nhất: có completed_at=$hasCompletedAt nhưng earned_stars=$hasEarnedStars',
        rawLevelId: levelId,
      );
    }

    if (hasCompletedAt && hasEarnedStars) {
      final rawCompletedAt = decoded['completed_at'];
      final rawEarnedStars = decoded['earned_stars'];

      if (rawCompletedAt is! String ||
          rawCompletedAt.trim().isEmpty ||
          DateTime.tryParse(rawCompletedAt) == null) {
        return CorruptedSessionMetadataResult(
          reason:
              'completed_at không phải chuỗi thời gian ISO 8601 hợp lệ: $rawCompletedAt',
          rawLevelId: levelId,
        );
      }

      if (rawEarnedStars is! int || rawEarnedStars < 1 || rawEarnedStars > 3) {
        return CorruptedSessionMetadataResult(
          reason: 'earned_stars nằm ngoài miền hợp lệ 1..3: $rawEarnedStars',
          rawLevelId: levelId,
        );
      }

      return ValidCompletedSessionResult(
        levelId: levelId,
        attemptId: attemptId,
        earnedStars: rawEarnedStars,
        hintsUsed: hintsUsed,
        mistakesCount: mistakesCount,
        completedAtIso: rawCompletedAt,
      );
    } else {
      return ValidPlayingSessionResult(
        levelId: levelId,
        attemptId: attemptId,
        mistakesCount: mistakesCount,
        hintsUsed: hintsUsed,
      );
    }
  }

  @override
  Future<bool> clearActiveSession() async {
    return await _localDataSource.clearRawSession();
  }

  @override
  Future<bool> clearActiveSessionIfMatches({
    required String expectedAttemptId,
  }) async {
    if (expectedAttemptId.trim().isEmpty) return false;

    return await _localDataSource.clearRawSessionIf((rawJson) {
      if (rawJson == null || rawJson.trim().isEmpty) return false;
      try {
        final dynamic decoded = jsonDecode(rawJson);
        if (decoded is! Map<String, dynamic>) return false;
        final attemptId = decoded['attempt_id'];
        return attemptId == expectedAttemptId;
      } catch (_) {
        return false;
      }
    });
  }
}
