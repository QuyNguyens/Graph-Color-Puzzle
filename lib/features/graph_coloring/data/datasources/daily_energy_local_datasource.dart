import 'package:shared_preferences/shared_preferences.dart';

/// Data Source lưu trữ hạn ngạch Daily Energy vào SharedPreferences.
/// Sử dụng FIFO Chained Future để serialize mọi thao tác ghi/xóa.
/// Tầng Data Layer.
class DailyEnergyLocalDataSource {
  DailyEnergyLocalDataSource({SharedPreferences? preferences})
      : _prefs = preferences;

  final SharedPreferences? _prefs;
  static const String _energyKey = 'key_daily_energy_quota_v1';

  Future<dynamic> _writeQueue = Future.value();

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Đọc chuỗi JSON lưu trữ năng lượng thô (chờ các thao tác ghi dở dang nếu có).
  Future<String?> getRawEnergy() async {
    await _writeQueue;
    final prefs = await _getPrefs();
    return prefs.getString(_energyKey);
  }

  /// Lưu chuỗi JSON năng lượng qua hàng đợi tuần tự FIFO.
  /// Kiểm tra trực tiếp giá trị boolean trả về từ SharedPreferences.
  Future<bool> saveRawEnergy(String jsonString) {
    var result = false;
    _writeQueue = _writeQueue.then((_) async {
      try {
        final prefs = await _getPrefs();
        result = await prefs.setString(_energyKey, jsonString);
      } catch (_) {
        result = false;
      }
    }).catchError((_) {
      result = false;
    });

    return _writeQueue.then((_) => result);
  }

  /// Xóa dữ liệu năng lượng (dùng cho debug/reset).
  Future<bool> clearRawEnergy() {
    var result = false;
    _writeQueue = _writeQueue.then((_) async {
      try {
        final prefs = await _getPrefs();
        result = await prefs.remove(_energyKey);
      } catch (_) {
        result = false;
      }
    }).catchError((_) {
      result = false;
    });

    return _writeQueue.then((_) => result);
  }
}
