import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/daily_colored_lines_local_datasource.dart';
import '../data/repositories/daily_colored_lines_repository_impl.dart';
import '../domain/repositories/daily_colored_lines_repository.dart';

export 'daily_colored_lines_notifier.dart';
export '../domain/repositories/daily_colored_lines_repository.dart';

/// Provider cung cấp Data Source cho Daily Colored Lines Quota.
final dailyColoredLinesLocalDataSourceProvider =
    Provider<DailyColoredLinesLocalDataSource>((ref) {
  return DailyColoredLinesLocalDataSource();
});

/// Provider cung cấp Repository quản lý hạn ngạch Colored Lines hằng ngày.
final dailyColoredLinesRepositoryProvider =
    Provider<DailyColoredLinesRepository>((ref) {
  final dataSource = ref.watch(dailyColoredLinesLocalDataSourceProvider);
  return DailyColoredLinesRepositoryImpl(localDataSource: dataSource);
});

/// Notifier quản lý trạng thái bật/tắt đường nối màu (Colored Lines) trong game.
/// Khi BẬT: Các đường nối giữa các đỉnh sẽ đổi màu và hiển thị hiệu ứng sóng màu khi tô đỉnh.
/// Khi TẮT: Các đường nối giữ màu trung tính tĩnh, không vẽ màu khi di chuyển bóng vào đỉnh.
/// Sử dụng SharedPreferences làm nguồn lưu trữ bền vững duy nhất.
class ColoredLinesSettingsNotifier extends Notifier<bool> {
  static const String _prefKey = 'game_colored_lines_enabled';

  @override
  bool build() {
    Future.microtask(() => _loadPreference());
    return true; // Mặc định ban đầu bật đường nối màu nếu còn lượt
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

  /// Chuyển đổi trạng thái bật/tắt đường nối màu và lưu vào SharedPreferences.
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

  /// Thiết lập trực tiếp trạng thái bật/tắt đường nối màu.
  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {
      // Bỏ qua ngoại lệ ghi SharedPreferences
    }
  }
}

/// Provider toàn cục truy cập trạng thái bật/tắt đường nối màu.
final coloredLinesSettingsProvider =
    NotifierProvider<ColoredLinesSettingsNotifier, bool>(
  ColoredLinesSettingsNotifier.new,
);
