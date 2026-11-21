import 'package:shared_preferences/shared_preferences.dart';

/// Interface cho việc đọc và ghi raw JSON tiến trình Campaign.
/// Tầng Data Layer.
abstract class CampaignProgressLocalDataSource {
  Future<String?> getRawProgress();
  Future<void> saveRawProgress(String rawJson);
  Future<void> clearRawProgress();
}

/// Implementation của CampaignProgressLocalDataSource sử dụng SharedPreferences.
/// Sử dụng hàng đợi tuần tự (FIFO Queue) để loại bỏ hoàn toàn race condition khi ghi bất đồng bộ.
class CampaignProgressLocalDataSourceImpl
    implements CampaignProgressLocalDataSource {
  CampaignProgressLocalDataSourceImpl({SharedPreferences? preferences})
      : _prefs = preferences;

  final SharedPreferences? _prefs;
  static const String progressKey = 'key_campaign_progress_v1';

  // Hàng đợi FIFO đảm bảo các tác vụ ghi/xóa luôn được thực thi tuần tự
  Future<void> _writeQueue = Future.value();

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<String?> getRawProgress() async {
    final prefs = await _getPrefs();
    return prefs.getString(progressKey);
  }

  @override
  Future<void> saveRawProgress(String rawJson) {
    _writeQueue = _writeQueue.then((_) async {
      final prefs = await _getPrefs();
      await prefs.setString(progressKey, rawJson);
    }).catchError((_) {});
    return _writeQueue;
  }

  @override
  Future<void> clearRawProgress() {
    _writeQueue = _writeQueue.then((_) async {
      final prefs = await _getPrefs();
      await prefs.remove(progressKey);
    }).catchError((_) {});
    return _writeQueue;
  }
}

