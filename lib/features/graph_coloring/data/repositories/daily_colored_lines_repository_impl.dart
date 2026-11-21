import 'dart:async';
import 'dart:convert';

import '../../domain/repositories/daily_colored_lines_repository.dart';
import '../datasources/daily_colored_lines_local_datasource.dart';

/// Triển khai DailyColoredLinesRepository với hàng đợi bất đồng bộ nguyên tử.
/// Đảm bảo tính nhất quán dữ liệu và loại trừ race condition.
class DailyColoredLinesRepositoryImpl implements DailyColoredLinesRepository {
  DailyColoredLinesRepositoryImpl({
    required DailyColoredLinesLocalDataSource localDataSource,
    DateTime Function()? nowProvider,
  })  : _localDataSource = localDataSource,
        _nowProvider = nowProvider ?? DateTime.now;

  final DailyColoredLinesLocalDataSource _localDataSource;
  final DateTime Function() _nowProvider;

  // Hàng đợi tuần tự (Mutex) đảm bảo các thao tác đọc-sửa-ghi luôn nguyên tử
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

  String _getTodayString() {
    return _nowProvider().toIso8601String().substring(0, 10);
  }

  /// Đọc quota hiện tại, tự động kiểm tra ngày và reset về maxDailyQuota (5) nếu sang ngày mới.
  Future<int> _readAndSyncQuota() async {
    final today = _getTodayString();
    final rawJson = await _localDataSource.getRawQuota();

    if (rawJson == null || rawJson.trim().isEmpty) {
      // Chưa từng lưu dữ liệu -> Khởi tạo maxDailyQuota (5) cho ngày hôm nay
      await _saveQuota(
        date: today,
        remaining: DailyColoredLinesRepository.maxDailyQuota,
      );
      return DailyColoredLinesRepository.maxDailyQuota;
    }

    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        await _saveQuota(
          date: today,
          remaining: DailyColoredLinesRepository.maxDailyQuota,
        );
        return DailyColoredLinesRepository.maxDailyQuota;
      }

      final savedDate = decoded['date'] as String?;
      final savedRemaining = decoded['remaining'] as int?;

      // Nếu đã sang ngày mới -> reset cứng về maxDailyQuota (5), không cộng dồn
      if (savedDate != today) {
        await _saveQuota(
          date: today,
          remaining: DailyColoredLinesRepository.maxDailyQuota,
        );
        return DailyColoredLinesRepository.maxDailyQuota;
      }

      // Vẫn trong ngày cũ -> không âm
      final validRemaining =
          (savedRemaining ?? DailyColoredLinesRepository.maxDailyQuota);
      return validRemaining < 0 ? 0 : validRemaining;
    } catch (_) {
      // Dữ liệu JSON bị hỏng -> fallback về maxDailyQuota
      await _saveQuota(
        date: today,
        remaining: DailyColoredLinesRepository.maxDailyQuota,
      );
      return DailyColoredLinesRepository.maxDailyQuota;
    }
  }

  Future<void> _saveQuota({required String date, required int remaining}) async {
    final payload = jsonEncode({
      'date': date,
      'remaining': remaining < 0 ? 0 : remaining,
    });
    await _localDataSource.saveRawQuota(payload);
  }

  @override
  Future<int> getRemainingQuota() {
    return _synchronized(() => _readAndSyncQuota());
  }

  @override
  Future<int?> consumeQuota() {
    return _synchronized(() async {
      final currentRemaining = await _readAndSyncQuota();

      // Nếu đã hết quota trong ngày -> Trả về null
      if (currentRemaining <= 0) {
        return null;
      }

      final newRemaining = currentRemaining - 1;
      final today = _getTodayString();
      await _saveQuota(date: today, remaining: newRemaining);

      return newRemaining;
    });
  }

  @override
  Future<int> addQuotaReward({int amount = 1}) {
    return _synchronized(() async {
      final currentRemaining = await _readAndSyncQuota();
      final effectiveAmount = amount > 0 ? amount : 1;
      final newRemaining = currentRemaining + effectiveAmount;
      final today = _getTodayString();
      await _saveQuota(date: today, remaining: newRemaining);

      return newRemaining;
    });
  }

  @override
  Future<void> resetDailyQuota() {
    return _synchronized(() async {
      final today = _getTodayString();
      await _saveQuota(
        date: today,
        remaining: DailyColoredLinesRepository.maxDailyQuota,
      );
    });
  }
}
