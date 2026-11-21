import 'dart:math';

/// Bộ sinh định danh duy nhất ngẫu nhiên UUID v4 (RFC 4122).
/// Thuần Dart, không phụ thuộc package ngoài, sử dụng Random.secure().
class UuidGenerator {
  static final Random _secureRandom = Random.secure();

  /// Sinh chuỗi UUID v4 chuẩn dạng: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  static String generateV4() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4 (0100)
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant RFC 4122 (10xx)

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Sinh định danh attemptId chuẩn UUID v4 thuần RFC 4122:
  /// xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  /// Không ghép tiền tố, không ghép levelId.
  static String generateAttemptId([String? levelId]) {
    return generateV4();
  }
}

