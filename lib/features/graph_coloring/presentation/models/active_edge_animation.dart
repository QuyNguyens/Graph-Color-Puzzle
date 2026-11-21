import 'package:flutter/material.dart';

import '../../domain/entities/graph_edge.dart';

/// Hằng số cấu hình thời gian hiệu ứng lan tỏa màu sắc trên cạnh đồ thị.
class EdgeAnimationConstants {
  const EdgeAnimationConstants._();

  /// Thời gian lan tỏa màu trên mỗi cạnh (mili-giây).
  static const int edgePropagationDurationMs = 350;

  /// Độ trễ giữa các cạnh liền kề tạo hiệu ứng thác nước (mili-giây).
  static const int edgeStaggerDelayMs = 70;

  /// Đường cong chuyển động mượt mà.
  static const Curve edgePropagationCurve = Curves.easeOutCubic;
}

/// Đại diện cho 1 sóng màu lan tỏa đơn hướng dọc theo cạnh.
class PropagationWave {
  const PropagationWave({
    required this.startPos,
    required this.targetPos,
    required this.startTimeMs,
    required this.durationMs,
    required this.color,
    this.curve = EdgeAnimationConstants.edgePropagationCurve,
  });

  /// Vị trí xuất phát của đầu sóng trên hệ tọa độ chuẩn hóa s trong khoảng [0.0, 1.0].
  final double startPos;

  /// Vị trí đích đến của đầu sóng s trong khoảng [0.0, 1.0] (thường là 0.5 hoặc 1.0).
  final double targetPos;

  /// Thời điểm bắt đầu chạy sóng (tính theo Stopwatch của GraphBoard).
  final int startTimeMs;

  /// Thời gian kéo dài của sóng (mili-giây).
  final int durationMs;

  /// Màu sắc đang lan tỏa.
  final Color color;

  /// Đường cong nội suy.
  final Curve curve;

  /// Tính toán vị trí hiện tại của đầu sóng s tại thời điểm [elapsedMs].
  double getPosition(int elapsedMs) {
    if (elapsedMs <= startTimeMs) return startPos;
    final elapsed = elapsedMs - startTimeMs;
    if (elapsed >= durationMs) return targetPos;
    final t = curve.transform(elapsed / durationMs);
    return startPos + t * (targetPos - startPos);
  }

  /// Kiểm tra sóng đã hoàn thành xong chưa.
  bool isComplete(int elapsedMs) => elapsedMs >= (startTimeMs + durationMs);

  /// Kiểm tra sóng đã thực sự bắt đầu lan tỏa chưa (hay đang trong thời gian chờ stagger delay).
  bool hasStarted(int elapsedMs) => elapsedMs >= startTimeMs;
}

/// Trạng thái hoạt họa đang hoạt động hoặc chờ kích hoạt trên một cạnh cụ thể.
class ActiveEdgeAnimation {
  ActiveEdgeAnimation({
    required this.edge,
    required this.underlyingColorU,
    required this.underlyingColorV,
    this.waveU,
    this.waveV,
    this.frozenOvershootU,
    this.frozenOvershootV,
  });

  /// Cạnh đồ thị tương ứng.
  final GraphEdge edge;

  /// Màu nền cơ sở phía đầu U trước khi sóng mới tràn qua.
  final Color underlyingColorU;

  /// Màu nền cơ sở phía đầu V trước khi sóng mới tràn qua.
  final Color underlyingColorV;

  /// Sóng lan tỏa từ đầu U hướng về V (hướng s tăng dần).
  final PropagationWave? waveU;

  /// Sóng lan tỏa từ đầu V hướng về U (hướng s giảm dần).
  final PropagationWave? waveV;

  /// Tọa độ overshoot từ phía U bị đóng băng khi có va chạm cùng cạnh (s >= 0.5).
  final double? frozenOvershootU;

  /// Tọa độ overshoot từ phía V bị đóng băng khi có va chạm cùng cạnh (s <= 0.5).
  final double? frozenOvershootV;

  /// Kiểm tra cạnh đã hoàn thành toàn bộ hoạt họa chưa.
  bool isComplete(int elapsedMs) {
    final uDone = waveU == null || waveU!.isComplete(elapsedMs);
    final vDone = waveV == null || waveV!.isComplete(elapsedMs);
    return uDone && vDone;
  }
}
