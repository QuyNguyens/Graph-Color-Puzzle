import 'package:shared_preferences/shared_preferences.dart';

/// Data Source lưu trữ hạn ngạch Daily Colored Lines vào SharedPreferences.
/// Sử dụng FIFO Chained Future để serialize mọi thao tác ghi/xóa.
/// Tầng Data Layer.
class DailyColoredLinesLocalDataSource {
  DailyColoredLinesLocalDataSource({SharedPreferences? preferences})
      : _prefs = preferences;

  final SharedPreferences? _prefs;
  static const String _quotaKey = 'key_daily_colored_lines_quota_v1';

  Future<void> _writeQueue = Future.value();

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Đọc chuỗi JSON lưu trữ quota thô (chờ các thao tác ghi dở dang nếu có).
  Future<String?> getRawQuota() async {
    await _writeQueue;
    final prefs = await _getPrefs();
    return prefs.getString(_quotaKey);
  }

  /// Lưu chuỗi JSON quota qua hàng đợi tuần tự FIFO.
  Future<void> saveRawQuota(String jsonString) {
    _writeQueue = _writeQueue.then((_) async {
      final prefs = await _getPrefs();
      await prefs.setString(_quotaKey, jsonString);
    }).catchError((_) {});
    return _writeQueue;
  }

  /// Xóa dữ liệu quota (dùng cho debug/reset).
  Future<void> clearRawQuota() {
    _writeQueue = _writeQueue.then((_) async {
      final prefs = await _getPrefs();
      await prefs.remove(_quotaKey);
    }).catchError((_) {});
    return _writeQueue;
  }
}
