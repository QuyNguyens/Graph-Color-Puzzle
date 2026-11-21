import 'puzzle_color.dart';

/// Quản lý kho số lượng màu chính xác (Exact Inventory) trong level.
/// Đảm bảo tính bất biến (immutable) và bảo toàn số lượng.
/// Tầng Domain thuần Dart.
class ColorInventory {
  const ColorInventory({
    required this.targetCounts,
    required this.usedCounts,
  });

  /// Khởi tạo inventory ban đầu với số lượng đã dùng mặc định là 0.
  factory ColorInventory.initial(Map<PuzzleColor, int> targets) {
    return ColorInventory(
      targetCounts: Map.unmodifiable(targets),
      usedCounts: Map.unmodifiable({
        for (final color in targets.keys) color: 0,
      }),
    );
  }

  /// Số lượng mục tiêu cần sử dụng của từng màu.
  final Map<PuzzleColor, int> targetCounts;

  /// Số lượng hiện tại đang được tô trên bàn cờ.
  final Map<PuzzleColor, int> usedCounts;

  int getTarget(PuzzleColor color) => targetCounts[color] ?? 0;

  int getUsed(PuzzleColor color) => usedCounts[color] ?? 0;

  int getRemaining(PuzzleColor color) => getTarget(color) - getUsed(color);

  bool isAvailable(PuzzleColor color) => getRemaining(color) > 0;

  /// Kiểm tra toàn bộ inventory đã dùng đúng chính xác 100% số lượng mục tiêu chưa.
  bool isFullySatisfied() {
    for (final entry in targetCounts.entries) {
      final color = entry.key;
      final target = entry.value;
      final used = getUsed(color);
      if (used != target) return false;
    }
    return true;
  }

  /// Tăng số lượng đã dùng của 1 màu.
  ColorInventory useColor(PuzzleColor color) {
    if (!isAvailable(color)) {
      throw StateError('Màu ${color.code} đã dùng hết số lượng cho phép.');
    }
    final newUsed = Map<PuzzleColor, int>.from(usedCounts);
    newUsed[color] = getUsed(color) + 1;
    return ColorInventory(
      targetCounts: targetCounts,
      usedCounts: Map.unmodifiable(newUsed),
    );
  }

  /// Hoàn trả 1 đơn vị màu về kho khi xóa màu hoặc đổi màu.
  ColorInventory releaseColor(PuzzleColor color) {
    final currentUsed = getUsed(color);
    if (currentUsed <= 0) {
      throw StateError('Màu ${color.code} chưa được dùng, không thể hoàn trả.');
    }
    final newUsed = Map<PuzzleColor, int>.from(usedCounts);
    newUsed[color] = currentUsed - 1;
    return ColorInventory(
      targetCounts: targetCounts,
      usedCounts: Map.unmodifiable(newUsed),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ColorInventory) return false;
    if (targetCounts.length != other.targetCounts.length ||
        usedCounts.length != other.usedCounts.length) {
      return false;
    }
    for (final key in targetCounts.keys) {
      if (other.targetCounts[key] != targetCounts[key]) return false;
    }
    for (final key in usedCounts.keys) {
      if (other.usedCounts[key] != usedCounts[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(targetCounts.entries),
        Object.hashAll(usedCounts.entries),
      );

  @override
  String toString() {
    return 'ColorInventory(target: $targetCounts, used: $usedCounts)';
  }
}

