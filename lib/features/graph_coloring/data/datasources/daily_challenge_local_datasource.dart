import 'package:shared_preferences/shared_preferences.dart';

/// DataSource truy xuất SharedPreferences cho Daily Challenge State.
/// Tầng Data Layer.
class DailyChallengeLocalDataSource {
  DailyChallengeLocalDataSource({SharedPreferences? preferences})
      : _prefs = preferences;

  final SharedPreferences? _prefs;
  static const String _challengeKey = 'key_daily_challenge_state_v1';

  // Hàng đợi FIFO đảm bảo các thao tác đọc/ghi luôn được thực thi tuần tự
  Future<dynamic> _writeQueue = Future.value();

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Đọc chuỗi JSON lưu trữ thử thách (chờ các tác vụ ghi đang chạy).
  Future<String?> getRawChallenge() async {
    await _writeQueue;
    final prefs = await _getPrefs();
    return prefs.getString(_challengeKey);
  }

  /// Lưu chuỗi JSON thử thách qua hàng đợi tuần tự.
  /// Kiểm tra trực tiếp giá trị boolean trả về từ SharedPreferences.
  Future<bool> saveRawChallenge(String jsonString) {
    var result = false;
    _writeQueue = _writeQueue.then((_) async {
      try {
        final prefs = await _getPrefs();
        result = await prefs.setString(_challengeKey, jsonString);
      } catch (_) {
        result = false;
      }
    }).catchError((_) {
      result = false;
    });

    return _writeQueue.then((_) => result);
  }

  /// Xóa dữ liệu thử thách (dùng cho debug/test).
  Future<bool> clearRawChallenge() {
    var result = false;
    _writeQueue = _writeQueue.then((_) async {
      try {
        final prefs = await _getPrefs();
        result = await prefs.remove(_challengeKey);
      } catch (_) {
        result = false;
      }
    }).catchError((_) {
      result = false;
    });

    return _writeQueue.then((_) => result);
  }
}

