/// Dịch vụ kiểm tra tính hợp lệ của attemptId trong Game Session và Outbox.
/// Tuân thủ quy tắc bảo toàn định dạng, không tự ý trim hay normalize.
/// Tầng Domain thuần Dart, không phụ thuộc package ngoài.
class AttemptIdValidator {
  AttemptIdValidator._();

  // Bắt mọi ký tự whitespace: space, tab (\t), newline (\n), carriage return (\r), form feed (\f)
  static final RegExp _whitespaceRegex = RegExp(r'\s');

  // Regex UUID v4 RFC 4122 thuần chuẩn 36 ký tự:
  // xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx với y in [8, 9, a, b, A, B]
  static final RegExp _uuidV4Regex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  /// Kiểm tra tính hợp lệ của chuỗi attemptId.
  ///
  /// - Từ chối nếu chuỗi null, rỗng hoặc chứa bất kỳ ký tự khoảng trắng nào (không tự ý trim).
  /// - Chấp nhận UUID v4 thuần chuẩn RFC 4122.
  /// - Chấp nhận Legacy format dạng `att_${expectedLevelId}_${uuidV4}` (hỗ trợ cả levelId có dấu gạch dưới `_`).
  /// - Nếu không truyền [expectedLevelId], chấp nhận Legacy format bất kỳ có đuôi là UUID v4 hợp lệ.
  static bool isValidAttemptId(String? attemptId, {String? expectedLevelId}) {
    if (attemptId == null) {
      return false;
    }

    // 1. Từ chối chuỗi rỗng hoặc có chứa bất kỳ ký tự whitespace nào
    if (attemptId.isEmpty || _whitespaceRegex.hasMatch(attemptId)) {
      return false;
    }

    // 2. Kiểm tra định dạng chuẩn mới: UUID v4 thuần (36 ký tự)
    if (_uuidV4Regex.hasMatch(attemptId)) {
      return true;
    }

    // 3. Kiểm tra định dạng cũ hợp lệ (Legacy): att_{expectedLevelId}_{uuid}
    if (expectedLevelId != null) {
      final legacyPrefix = 'att_${expectedLevelId}_';
      if (attemptId.startsWith(legacyPrefix)) {
        final uuidPart = attemptId.substring(legacyPrefix.length);
        return _uuidV4Regex.hasMatch(uuidPart);
      }
      return false;
    } else {
      // Khi không có expectedLevelId: bóc tách phần UUID ở cuối (36 ký tự)
      // Cấu trúc: 'att_' + levelId + '_' + uuidV4
      // Độ dài tối thiểu: 4 ('att_') + 1 (levelId tối thiểu) + 1 ('_') + 36 (uuid) = 42 ký tự
      if (attemptId.startsWith('att_') && attemptId.length >= 42) {
        final lastUnderscoreIndex = attemptId.lastIndexOf('_');
        if (lastUnderscoreIndex >= 5) {
          // 'att_' dài 4, levelId ít nhất 1 ký tự, do đó lastUnderscoreIndex tối thiểu là 5
          final uuidPart = attemptId.substring(lastUnderscoreIndex + 1);
          return _uuidV4Regex.hasMatch(uuidPart);
        }
      }
      return false;
    }
  }

  /// Trích xuất UUID phần cốt lõi từ attemptId (cho dù là UUID v4 thuần hay legacy).
  /// Trả về null nếu attemptId không hợp lệ.
  static String? extractCoreUuid(String? attemptId, {String? expectedLevelId}) {
    if (!isValidAttemptId(attemptId, expectedLevelId: expectedLevelId)) {
      return null;
    }

    final id = attemptId!;
    if (_uuidV4Regex.hasMatch(id)) {
      return id;
    }

    if (expectedLevelId != null) {
      final legacyPrefix = 'att_${expectedLevelId}_';
      if (id.startsWith(legacyPrefix)) {
        return id.substring(legacyPrefix.length);
      }
    }

    final lastUnderscoreIndex = id.lastIndexOf('_');
    return id.substring(lastUnderscoreIndex + 1);
  }
}
