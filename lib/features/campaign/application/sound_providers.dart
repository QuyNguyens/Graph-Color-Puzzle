import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier quản lý trạng thái bật/tắt âm thanh trò chơi theo Riverpod 3 Notifier API.
/// Sử dụng SharedPreferences làm nguồn lưu trữ duy nhất.
class SoundSettingsNotifier extends Notifier<bool> {
  static const String _prefKey = 'game_sound_enabled';

  @override
  bool build() {
    // Tự động khôi phục thiết lập đã lưu
    Future.microtask(() => _loadPreference());
    return true; // Mặc định bật âm thanh
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefKey);
      if (saved != null) {
        state = saved;
      }
    } catch (_) {
      // Giữ mặc định nếu có ngoại lệ đọc SharedPreferences
    }
  }

  /// Chuyển đổi trạng thái âm thanh và đồng bộ tức thì vào SharedPreferences.
  Future<void> toggle() async {
    final next = !state;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, next);
    } catch (_) {
      // Bỏ qua ngoại lệ ghi SharedPreferences
    }
  }
}

/// Provider toàn cục truy cập trạng thái âm thanh của ứng dụng theo Riverpod 3 API.
final soundSettingsProvider =
    NotifierProvider<SoundSettingsNotifier, bool>(SoundSettingsNotifier.new);
