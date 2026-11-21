import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/campaign/application/sound_providers.dart';

/// Dịch vụ quản lý âm thanh tập trung (GameAudioService).
/// Tuân thủ nguyên tắc Clean Architecture, quản lý vòng đời AudioPlayer,
/// tôn trọng cài đặt âm thanh (soundSettingsProvider) làm single source of truth,
/// chống trùng lặp sự kiện và không bao giờ chặn UI thread.
class GameAudioService {
  GameAudioService(this._ref) {
    _init();
  }

  final Ref _ref;

  // Hằng số file âm thanh chuẩn xác theo assets/audio/
  static const String assetPrefix = 'assets/audio/';
  static const String soundMoveColor = 'move_color.wav';
  static const String soundUndo = 'undo.wav';
  static const String soundHint = 'hint.wav';
  static const String soundReplay = 'replay.wav';
  static const String soundWin = 'win.wav';
  static const String soundLose = 'lose.wav';
  static const String soundInvalidMove = 'invalid_move.wav';
  static const String soundVictoryAdvance = 'victory_advance.wav';
  static const String soundSelectColor = 'select_color.wav';

  // Player chuyên biệt cho hiệu ứng ngắn hạn (SFX)
  late final AudioPlayer _sfxPlayer;
  // Player chuyên biệt cho âm thanh kết thúc ván (Victory / Defeat)
  late final AudioPlayer _completionPlayer;

  // Chống kích hoạt trùng lặp ván chơi (Idempotency protection)
  String? _lastVictoryAttemptId;
  String? _lastDefeatAttemptId;

  // Throttling để tránh chồng lấn âm thanh quá dày đặc khi bấm nhanh
  final Map<String, DateTime> _lastPlayTime = {};
  static const Duration _sfxThrottleDuration = Duration(milliseconds: 60);

  bool _isDisposed = false;

  void _init() {
    AudioCache.instance.prefix = assetPrefix;

    _sfxPlayer = AudioPlayer();
    _completionPlayer = AudioPlayer();

    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency).catchError((_) {});
    _completionPlayer.setPlayerMode(PlayerMode.lowLatency).catchError((_) {});

    // Lắng nghe thay đổi cài đặt âm thanh: Nếu tắt, dừng ngay lập tức mọi âm thanh đang phát
    _ref.listen<bool>(soundSettingsProvider, (previous, next) {
      if (!next) {
        stopAll();
      }
    });
  }

  /// Kiểm tra xem âm thanh có được phép phát hay không dựa vào soundSettingsProvider
  bool get isSoundEnabled {
    if (_isDisposed) return false;
    return _ref.read(soundSettingsProvider);
  }

  /// Phát âm thanh chung kèm cơ chế Throttle và Error Handling an toàn tuyệt đối
  Future<void> _playSound({
    required AudioPlayer player,
    required String soundFile,
    bool checkThrottle = true,
  }) async {
    if (!isSoundEnabled || _isDisposed) return;

    if (checkThrottle) {
      final now = DateTime.now();
      final last = _lastPlayTime[soundFile];
      if (last != null && now.difference(last) < _sfxThrottleDuration) {
        return; // Bỏ qua nếu bấm quá nhanh trong khoảng throttle
      }
      _lastPlayTime[soundFile] = now;
    }

    try {
      // Dừng âm thanh trước đó trên cùng player để tránh chồng âm khó chịu
      await player.stop();
      if (!isSoundEnabled || _isDisposed) return;

      await player.play(
        AssetSource(soundFile),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Xử lý ngoại lệ âm thanh an toàn, tuyệt đối không làm gián đoạn game loop
    }
  }

  /// A. Nước đi tô màu hợp lệ (move_color.wav)
  /// Chỉ kích hoạt sau khi nước đi đã được thẩm định hợp lệ và ván chơi chưa hoàn thành.
  Future<void> playMoveColor() async {
    await _playSound(
      player: _sfxPlayer,
      soundFile: soundMoveColor,
    );
  }

  /// B. Hoàn tác (undo.wav)
  /// Chỉ kích hoạt khi thao tác hoàn tác thực sự thành công.
  Future<void> playUndo() async {
    await _playSound(
      player: _sfxPlayer,
      soundFile: soundUndo,
    );
  }

  /// C. Gợi ý (hint.wav)
  /// Chỉ kích hoạt khi gợi ý được tiêu thụ thành công và hiển thị trên bàn cờ.
  Future<void> playHint() async {
    await _playSound(
      player: _sfxPlayer,
      soundFile: soundHint,
    );
  }

  /// D. Chơi lại / Khởi động lại (replay.wav)
  /// Kích hoạt khi thao tác replay/restart được xác nhận và thực thi thành công.
  Future<void> playReplay() async {
    _lastVictoryAttemptId = null;
    _lastDefeatAttemptId = null;
    await _playSound(
      player: _sfxPlayer,
      soundFile: soundReplay,
      checkThrottle: true,
    );
  }

  /// E. Chiến thắng màn chơi (win.wav)
  /// Đảm bảo kích hoạt DUY NHẤT 1 lần cho mỗi attemptId hoàn thành.
  Future<void> playVictory({String? attemptId}) async {
    if (attemptId != null && attemptId.isNotEmpty) {
      if (_lastVictoryAttemptId == attemptId) {
        return; // Đã phát cho attempt này rồi, bỏ qua hoàn toàn
      }
      _lastVictoryAttemptId = attemptId;
    }

    await _playSound(
      player: _completionPlayer,
      soundFile: soundWin,
      checkThrottle: false,
    );
  }

  /// F. Thua cuộc / Hết lượt lỗi (lose.wav)
  /// Đảm bảo kích hoạt DUY NHẤT 1 lần cho mỗi attemptId thất bại.
  Future<void> playDefeat({String? attemptId}) async {
    if (attemptId != null && attemptId.isNotEmpty) {
      if (_lastDefeatAttemptId == attemptId) {
        return; // Đã phát cho attempt này rồi, bỏ qua hoàn toàn
      }
      _lastDefeatAttemptId = attemptId;
    }

    await _playSound(
      player: _completionPlayer,
      soundFile: soundLose,
      checkThrottle: false,
    );
  }

  /// G. Nước đi không hợp lệ (invalid_move.wav)
  /// Kích hoạt khi người chơi chọn sai node, màu xung đột hoặc không còn nghiệm.
  Future<void> playInvalidMove() async {
    await _playSound(
      player: _sfxPlayer,
      soundFile: soundInvalidMove,
    );
  }

  /// H. Chiến thắng & Chuyển màn tiếp theo (victory_advance.wav)
  /// Kích hoạt khi người chơi hoàn thành màn chơi hoặc khi bấm Next Level.
  /// Đảm bảo không phát lặp 2 lần trong cùng một phiên chuyển màn (victory-to-next-level transition).
  /// Nếu âm thanh chiến thắng đã phát ở màn chơi hiện tại, thao tác Next Level không phát lại.
  Future<void> playVictoryAdvance({String? attemptId}) async {
    if (attemptId != null && attemptId.isNotEmpty) {
      if (_lastVictoryAttemptId == attemptId) {
        return; // Đã phát âm thanh chiến thắng cho attempt này rồi, bỏ qua hoàn toàn
      }
      _lastVictoryAttemptId = attemptId;
    }

    await _playSound(
      player: _completionPlayer,
      soundFile: soundVictoryAdvance,
      checkThrottle: false,
    );
  }

  /// I. Chọn màu trong bảng màu (select_color.wav)
  /// Kích hoạt khi người chơi bấm chọn một màu từ Color Inventory.
  /// Chỉ phát đúng 1 lần cho mỗi lượt chọn màu, không lặp khi kéo thả hay rebuild.
  Future<void> playSelectColor() async {
    await _playSound(
      player: _sfxPlayer,
      soundFile: soundSelectColor,
      checkThrottle: true,
    );
  }

  /// Dừng toàn bộ âm thanh đang phát (ví dụ khi người chơi toggle tắt âm thanh)
  Future<void> stopAll() async {
    try {
      await Future.wait([
        _sfxPlayer.stop(),
        _completionPlayer.stop(),
      ]);
    } catch (_) {}
  }

  /// Hủy tài nguyên AudioPlayer an toàn khi Provider bị dispose
  void dispose() {
    _isDisposed = true;
    try {
      _sfxPlayer.dispose();
      _completionPlayer.dispose();
    } catch (_) {}
  }
}

/// Provider cung cấp GameAudioService tập trung cho toàn ứng dụng.
final gameAudioServiceProvider = Provider<GameAudioService>((ref) {
  final service = GameAudioService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
