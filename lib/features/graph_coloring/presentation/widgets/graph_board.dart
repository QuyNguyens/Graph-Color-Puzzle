import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/entities/game_move.dart';
import '../../domain/entities/graph.dart';
import '../../domain/entities/graph_edge.dart';
import '../../domain/entities/puzzle_color.dart';
import '../models/active_edge_animation.dart';
import '../theme/puzzle_color_palette.dart';
import 'graph_edge_painter.dart';
import 'graph_node_widget.dart';

/// Bàn cờ hiển thị đồ thị và các node tương tác.
/// Tự động căn chỉnh tọa độ node và đường nối theo kích thước thực tế của màn hình.
/// Hỗ trợ hoạt họa lan tỏa màu sắc dạng thác nước (Staggered Waterfall) và va chạm đa sóng.
class GraphBoard extends StatefulWidget {
  const GraphBoard({
    super.key,
    required this.graph,
    required this.onColorDropped,
    required this.onNodeTapped,
    this.hintedNodeId,
    this.hintedColor,
    this.attemptId = '',
    this.historyLength = 0,
    this.lastMove,
    this.isInitializing = false,
    this.showColoredLines = true,
  });

  final Graph graph;
  final void Function(String nodeId, PuzzleColor color) onColorDropped;
  final ValueChanged<String> onNodeTapped;
  final String? hintedNodeId;
  final PuzzleColor? hintedColor;
  final String attemptId;
  final int historyLength;
  final GameMove? lastMove;
  final bool isInitializing;
  final bool showColoredLines;

  @override
  State<GraphBoard> createState() => _GraphBoardState();
}

class _GraphBoardState extends State<GraphBoard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  final ChangeNotifier _repaintNotifier = ChangeNotifier();
  final Map<GraphEdge, ActiveEdgeAnimation> _activeAnimations = {};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final currentMs = _stopwatch.elapsedMilliseconds;

    // Loại bỏ các hoạt họa đã hoàn tất toàn bộ chu trình lan tỏa
    _activeAnimations.removeWhere((edge, anim) => anim.isComplete(currentMs));

    if (_activeAnimations.isEmpty) {
      _stopTicker();
    }

    // Thông báo cho CustomPainter repaint mà không rebuild cây Widget
    _repaintNotifier.notifyListeners();
  }

  void _startTicker() {
    if (!_ticker.isActive) {
      if (!_stopwatch.isRunning) {
        _stopwatch.start();
      }
      _ticker.start();
    }
  }

  void _stopTicker() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _stopwatch.reset();
    _stopwatch.stop();
  }

  void _clearAllAnimations() {
    _activeAnimations.clear();
    _stopTicker();
    _repaintNotifier.notifyListeners();
  }

  @override
  void didUpdateWidget(GraphBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1. Lifecycle Guard: Attempt thay đổi (Restart, Replay, Retry), hoặc đang load từ DB
    final isAttemptChanged = oldWidget.attemptId != widget.attemptId;
    final isLoadingOrRestoring =
        widget.isInitializing || oldWidget.isInitializing;
    if (isAttemptChanged || isLoadingOrRestoring) {
      _clearAllAnimations();
      return;
    }

    // 1.1 Line Settings Guard: Nếu người chơi vừa tắt cơ chế line màu, xóa toàn bộ hoạt họa
    if (oldWidget.showColoredLines != widget.showColoredLines && !widget.showColoredLines) {
      _clearAllAnimations();
      return;
    }

    // 2. Undo Guard: Lịch sử bị rút ngắn
    if (widget.historyLength < oldWidget.historyLength) {
      _clearAllAnimations();
      return;
    }

    // 3. Color Removal Guard: Xóa màu node (newColor == null)
    if (widget.historyLength == oldWidget.historyLength + 1 &&
        widget.lastMove?.newColor == null) {
      _clearAllAnimations();
      return;
    }

    // 4. Kiểm tra nghiêm ngặt 8 điều kiện của một nước đi tiến hợp lệ (Forward color move)
    final isHistoryIncremented =
        widget.historyLength == oldWidget.historyLength + 1;
    final lastMove = widget.lastMove;

    if (isHistoryIncremented && lastMove != null && lastMove.newColor != null) {
      final oldNode = oldWidget.graph.getNode(lastMove.nodeId);
      final newNode = widget.graph.getNode(lastMove.nodeId);

      final isOldColorMatch = oldNode?.currentColor == lastMove.previousColor;
      final isNewColorMatch = newNode?.currentColor == lastMove.newColor;
      final isColorActuallyChanged =
          lastMove.previousColor != lastMove.newColor;

      if (isOldColorMatch && isNewColorMatch && isColorActuallyChanged) {
        if (widget.showColoredLines) {
          _onForwardColorMove(
            movedNodeId: lastMove.nodeId,
            newColor: lastMove.newColor!,
            oldGraph: oldWidget.graph,
            newGraph: widget.graph,
          );
        }
      }
    }
  }

  void _onForwardColorMove({
    required String movedNodeId,
    required PuzzleColor newColor,
    required Graph oldGraph,
    required Graph newGraph,
  }) {
    final uiNewColor = PuzzleColorPalette.getColor(newColor);
    final currentMs = _stopwatch.elapsedMilliseconds;

    // 1. Thu thập tất cả các cạnh trực tiếp nối với movedNodeId
    final incidentEdges = widget.graph.edges
        .where((e) => e.contains(movedNodeId))
        .toList();

    // 2. Sắp xếp thứ tự kích hoạt cạnh có tính tất định (Deterministic order)
    // Sắp xếp theo ID của đỉnh đối diện để đảm bảo ổn định 100% trên mọi thiết bị và nền tảng
    incidentEdges.sort((a, b) {
      final otherA = a.getOther(movedNodeId);
      final otherB = b.getOther(movedNodeId);
      return otherA.compareTo(otherB);
    });

    // 3. Đăng ký hoạt họa lan tỏa có độ trễ thác nước (Staggered Waterfall)
    for (int i = 0; i < incidentEdges.length; i++) {
      final edge = incidentEdges[i];
      final delayMs = i * EdgeAnimationConstants.edgeStaggerDelayMs;
      final scheduledStartMs = currentMs + delayMs;

      _scheduleEdgePropagation(
        edge: edge,
        movedNodeId: movedNodeId,
        newColor: uiNewColor,
        scheduledStartMs: scheduledStartMs,
        currentMs: currentMs,
        oldGraph: oldGraph,
        newGraph: newGraph,
      );
    }

    _startTicker();
  }

  void _scheduleEdgePropagation({
    required GraphEdge edge,
    required String movedNodeId,
    required Color newColor,
    required int scheduledStartMs,
    required int currentMs,
    required Graph oldGraph,
    required Graph newGraph,
  }) {
    final isMovedU = movedNodeId == edge.u;
    final otherNodeId = isMovedU ? edge.v : edge.u;
    final otherNodeNew = newGraph.getNode(otherNodeId);
    final isOtherColored = otherNodeNew?.currentColor != null;

    final existingAnim = _activeAnimations[edge];

    if (existingAnim == null) {
      // -------------------------------------------------------------
      // KỊCH BẢN 1: Cạnh chưa có hoạt họa đang chạy (xuất phát mới)
      // -------------------------------------------------------------
      final (baseColorU, baseColorV) = _resolveUnderlyingColors(oldGraph, edge);

      // Nếu đỉnh đối diện đã có màu, sóng dừng ở trung điểm (0.5).
      // Nếu đỉnh đối diện chưa có màu, sóng quét trọn vẹn 100% toàn bộ cạnh.
      final targetPos = isOtherColored ? 0.5 : (isMovedU ? 1.0 : 0.0);

      if (isMovedU) {
        final waveU = PropagationWave(
          startPos: 0.0,
          targetPos: targetPos,
          startTimeMs: scheduledStartMs,
          durationMs: EdgeAnimationConstants.edgePropagationDurationMs,
          color: newColor,
        );
        _activeAnimations[edge] = ActiveEdgeAnimation(
          edge: edge,
          underlyingColorU: baseColorU,
          underlyingColorV: baseColorV,
          waveU: waveU,
        );
      } else {
        final waveV = PropagationWave(
          startPos: 1.0,
          targetPos: targetPos,
          startTimeMs: scheduledStartMs,
          durationMs: EdgeAnimationConstants.edgePropagationDurationMs,
          color: newColor,
        );
        _activeAnimations[edge] = ActiveEdgeAnimation(
          edge: edge,
          underlyingColorU: baseColorU,
          underlyingColorV: baseColorV,
          waveV: waveV,
        );
      }
    } else {
      // -------------------------------------------------------------
      // KỊCH BẢN 2: Cạnh ĐÃ CÓ HOẠT HỌA (Xử lý gián đoạn Same-Edge Interruption)
      // -------------------------------------------------------------
      if (!isMovedU && existingAnim.waveU != null) {
        // Đỉnh U đang lan tỏa, nay đỉnh V được tô màu
        final sU = existingAnim.waveU!.getPosition(currentMs);

        if (sU < 0.5) {
          // Trường hợp A: Sóng U chưa tới trung điểm (sU < 0.5)
          // Cho sóng U tiếp tục từ vị trí sU hiện tại đến 0.5
          final remainingDuration = (EdgeAnimationConstants.edgePropagationDurationMs *
                  ((0.5 - sU) / 0.5))
              .round()
              .clamp(80, EdgeAnimationConstants.edgePropagationDurationMs);

          final continuedWaveU = PropagationWave(
            startPos: sU,
            targetPos: 0.5,
            startTimeMs: currentMs,
            durationMs: remainingDuration,
            color: existingAnim.waveU!.color,
          );
          final newWaveV = PropagationWave(
            startPos: 1.0,
            targetPos: 0.5,
            startTimeMs: scheduledStartMs,
            durationMs: EdgeAnimationConstants.edgePropagationDurationMs,
            color: newColor,
          );

          _activeAnimations[edge] = ActiveEdgeAnimation(
            edge: edge,
            underlyingColorU: existingAnim.underlyingColorU,
            underlyingColorV: existingAnim.underlyingColorV,
            waveU: continuedWaveU,
            waveV: newWaveV,
          );
        } else {
          // Trường hợp B: Sóng U đã vượt qua trung điểm (Overshoot sU >= 0.5)
          // Đóng băng Red overshoot ở vị trí sU, sóng V mới sẽ tiến vào và phủ đè dần lên nó
          final newWaveV = PropagationWave(
            startPos: 1.0,
            targetPos: 0.5,
            startTimeMs: scheduledStartMs,
            durationMs: EdgeAnimationConstants.edgePropagationDurationMs,
            color: newColor,
          );

          _activeAnimations[edge] = ActiveEdgeAnimation(
            edge: edge,
            underlyingColorU: existingAnim.underlyingColorU,
            underlyingColorV: existingAnim.underlyingColorV,
            waveU: null,
            waveV: newWaveV,
            frozenOvershootU: sU,
          );
        }
      } else if (isMovedU && existingAnim.waveV != null) {
        // Đỉnh V đang lan tỏa, nay đỉnh U được tô màu (đối xứng)
        final sV = existingAnim.waveV!.getPosition(currentMs);

        if (sV > 0.5) {
          // Trường hợp A: Sóng V chưa tới trung điểm (sV > 0.5)
          final remainingDuration = (EdgeAnimationConstants.edgePropagationDurationMs *
                  ((sV - 0.5) / 0.5))
              .round()
              .clamp(80, EdgeAnimationConstants.edgePropagationDurationMs);

          final continuedWaveV = PropagationWave(
            startPos: sV,
            targetPos: 0.5,
            startTimeMs: currentMs,
            durationMs: remainingDuration,
            color: existingAnim.waveV!.color,
          );
          final newWaveU = PropagationWave(
            startPos: 0.0,
            targetPos: 0.5,
            startTimeMs: scheduledStartMs,
            durationMs: EdgeAnimationConstants.edgePropagationDurationMs,
            color: newColor,
          );

          _activeAnimations[edge] = ActiveEdgeAnimation(
            edge: edge,
            underlyingColorU: existingAnim.underlyingColorU,
            underlyingColorV: existingAnim.underlyingColorV,
            waveU: newWaveU,
            waveV: continuedWaveV,
          );
        } else {
          // Trường hợp B: Sóng V đã vượt qua trung điểm (Overshoot sV <= 0.5)
          final newWaveU = PropagationWave(
            startPos: 0.0,
            targetPos: 0.5,
            startTimeMs: scheduledStartMs,
            durationMs: EdgeAnimationConstants.edgePropagationDurationMs,
            color: newColor,
          );

          _activeAnimations[edge] = ActiveEdgeAnimation(
            edge: edge,
            underlyingColorU: existingAnim.underlyingColorU,
            underlyingColorV: existingAnim.underlyingColorV,
            waveU: newWaveU,
            waveV: null,
            frozenOvershootV: sV,
          );
        }
      } else {
        // Trường hợp cùng 1 đỉnh được đổi màu đè lên trước khi sóng cũ xong
        final (baseColorU, baseColorV) = _resolveUnderlyingColors(oldGraph, edge);
        final targetPos = isOtherColored ? 0.5 : (isMovedU ? 1.0 : 0.0);

        if (isMovedU) {
          final waveU = PropagationWave(
            startPos: 0.0,
            targetPos: targetPos,
            startTimeMs: scheduledStartMs,
            durationMs: EdgeAnimationConstants.edgePropagationDurationMs,
            color: newColor,
          );
          _activeAnimations[edge] = ActiveEdgeAnimation(
            edge: edge,
            underlyingColorU: baseColorU,
            underlyingColorV: baseColorV,
            waveU: waveU,
          );
        } else {
          final waveV = PropagationWave(
            startPos: 1.0,
            targetPos: targetPos,
            startTimeMs: scheduledStartMs,
            durationMs: EdgeAnimationConstants.edgePropagationDurationMs,
            color: newColor,
          );
          _activeAnimations[edge] = ActiveEdgeAnimation(
            edge: edge,
            underlyingColorU: baseColorU,
            underlyingColorV: baseColorV,
            waveV: waveV,
          );
        }
      }
    }
  }

  /// Trích xuất màu nền tĩnh của cạnh trước khi xảy ra nước đi mới.
  (Color, Color) _resolveUnderlyingColors(Graph graph, GraphEdge edge) {
    final nodeU = graph.getNode(edge.u);
    final nodeV = graph.getNode(edge.v);

    final colorU = nodeU?.currentColor;
    final colorV = nodeV?.currentColor;

    if (colorU == null && colorV == null) {
      return (AppColors.graphEdge, AppColors.graphEdge);
    }
    if (colorU != null && colorV == null) {
      final cU = PuzzleColorPalette.getColor(colorU);
      return (cU, cU);
    }
    if (colorU == null && colorV != null) {
      final cV = PuzzleColorPalette.getColor(colorV);
      return (cV, cV);
    }
    return (
      PuzzleColorPalette.getColor(colorU),
      PuzzleColorPalette.getColor(colorV),
    );
  }

  int _getElapsedMs() => _stopwatch.elapsedMilliseconds;

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
    _repaintNotifier.dispose();
    _activeAnimations.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = constraints.maxWidth;
        final boardHeight = constraints.maxHeight;
        final halfNode = GraphNodeWidget.nodeSize / 2;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Vẽ các đường nối giữa các đỉnh (với viền cạnh dịu mắt & hiệu ứng lan tỏa động)
            RepaintBoundary(
              child: CustomPaint(
                size: Size(boardWidth, boardHeight),
                painter: GraphEdgePainter(
                  graph: widget.graph,
                  highlightedNodeId: widget.hintedNodeId,
                  activeAnimations: _activeAnimations,
                  getElapsedMs: _getElapsedMs,
                  showColoredLines: widget.showColoredLines,
                  repaint: _repaintNotifier,
                ),
              ),
            ),

            // 2. Định vị từng node trên bàn cờ
            ...widget.graph.nodes.values.map((node) {
              final posX = node.x * boardWidth - halfNode;
              final posY = node.y * boardHeight - halfNode;
              final isNodeHinted = node.id == widget.hintedNodeId;

              return Positioned(
                left: posX,
                top: posY,
                child: GraphNodeWidget(
                  node: node,
                  isHinted: isNodeHinted,
                  hintedColor: isNodeHinted ? widget.hintedColor : null,
                  onColorDropped: (color) =>
                      widget.onColorDropped(node.id, color),
                  onTap: () => widget.onNodeTapped(node.id),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
