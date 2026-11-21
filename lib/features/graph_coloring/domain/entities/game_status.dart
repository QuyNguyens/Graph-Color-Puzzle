/// Trạng thái vòng đời của một màn chơi (Game Session).
/// Tầng Domain thuần Dart.
enum GameStatus {
  /// Đang chơi bình thường, mọi thao tác kéo thả/chạm/undo đều khả dụng.
  playing,

  /// Đã hoàn thành level trọn vẹn, thỏa mãn 100% ràng buộc.
  completed,

  /// Thất bại (hết lượt lỗi và tiếp tục mắc lỗi No Solution).
  gameOver,
}

