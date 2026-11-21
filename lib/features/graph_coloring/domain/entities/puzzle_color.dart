/// Value object biểu diễn màu sắc logic trong bài toán tô màu đồ thị.
/// Tầng Domain thuần Dart, không phụ thuộc Flutter.
class PuzzleColor {
  const PuzzleColor({
    required this.id,
    required this.code,
    required this.label,
  });

  final int id;
  final String code;
  final String label;

  static const red = PuzzleColor(id: 1, code: 'RED', label: 'Đỏ');
  static const blue = PuzzleColor(id: 2, code: 'BLUE', label: 'Xanh dương');
  static const yellow = PuzzleColor(id: 3, code: 'YELLOW', label: 'Vàng');
  static const green = PuzzleColor(id: 4, code: 'GREEN', label: 'Xanh lá');
  static const purple = PuzzleColor(id: 5, code: 'PURPLE', label: 'Tím');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PuzzleColor && other.id == id && other.code == code;
  }

  @override
  int get hashCode => Object.hash(id, code);

  @override
  String toString() => 'PuzzleColor($code, label: $label)';
}

