import 'package:shared_preferences/shared_preferences.dart';

/// DataSource truy xuất bộ nhớ cục bộ bằng SharedPreferences.
/// Sử dụng hàng đợi tuần tự (FIFO Queue) để loại bỏ hoàn toàn race condition
/// giữa các thao tác save và clear bất đồng bộ.
/// Tầng Data Layer.
class GameSessionLocalDataSource {
  GameSessionLocalDataSource({SharedPreferences? preferences})
      : _prefs = preferences;

  final SharedPreferences? _prefs;
  static const String _sessionKey = 'key_active_game_session_v1';

  // Chained Future đảm bảo mọi thao tác ghi/xóa vào SharedPreferences luôn chạy tuần tự theo thứ tự gọi
  Future<dynamic> _writeQueue = Future.value();

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<bool> saveRawSession(String jsonString) {
    var result = false;
    _writeQueue = _writeQueue.then((_) async {
      try {
        final prefs = await _getPrefs();
        result = await prefs.setString(_sessionKey, jsonString);
      } catch (_) {
        result = false;
      }
    }).catchError((_) {
      result = false;
    });

    return _writeQueue.then((_) => result);
  }

  Future<String?> getRawSession() async {
    await _writeQueue;
    final prefs = await _getPrefs();
    return prefs.getString(_sessionKey);
  }

  Future<bool> clearRawSession() {
    var result = false;
    _writeQueue = _writeQueue.then((_) async {
      try {
        final prefs = await _getPrefs();
        result = await prefs.remove(_sessionKey);
      } catch (_) {
        result = false;
      }
    }).catchError((_) {
      result = false;
    });

    return _writeQueue.then((_) => result);
  }

  /// Xóa session có điều kiện tuần tự trên _writeQueue:
  /// Đọc session hiện tại, kiểm tra predicate bên trong cùng một tác vụ serialize trên _writeQueue,
  /// và chỉ remove khi predicate trả về true.
  Future<bool> clearRawSessionIf(bool Function(String? rawJson) predicate) {
    var result = false;
    _writeQueue = _writeQueue.then((_) async {
      try {
        final prefs = await _getPrefs();
        final current = prefs.getString(_sessionKey);
        if (predicate(current)) {
          result = await prefs.remove(_sessionKey);
        } else {
          result = false;
        }
      } catch (_) {
        result = false;
      }
    }).catchError((_) {
      result = false;
    });

    return _writeQueue.then((_) => result);
  }
}
