Graph Coloring – Original UI Sound Effects
===========================================

Files:
- move_color.wav    Successful color placement
- undo.wav          Undo action
- hint.wav          Hint request/result
- replay.wav        Restart/replay action
- win.wav           Level completed
- lose.wav          Level failed / game over
- invalid_move.wav  Rejected placement

Format: WAV, PCM 16-bit, mono, 44.1 kHz.
All sounds are original synthesized effects created for this project.
Suggested Flutter asset directory: assets/audio/

Suggested pubspec.yaml:
flutter:
  assets:
    - assets/audio/

Integration notes:
- Keep the existing sound setting/provider as the single source of truth.
- Respect game_sound_enabled before every playback.
- Avoid overlapping repeated effects; stop/replace or throttle short UI effects as appropriate.
- Trigger sounds only after the corresponding game action is confirmed, not on tentative animation frames.
