import 'package:audioplayers/audioplayers.dart';

import 'road_fighter_engine.dart';

/// Arcade SFX for Road Fighter. Failures are swallowed so audio never blocks play.
class RoadFighterAudio {
  RoadFighterAudio();

  final AudioPlayer _engine = AudioPlayer();
  final AudioPlayer _oneshotA = AudioPlayer();
  final AudioPlayer _oneshotB = AudioPlayer();
  bool _muted = false;
  bool _enginePlaying = false;
  int _shot = 0;

  bool get isMuted => _muted;

  Future<void> setMuted(bool muted) async {
    _muted = muted;
    try {
      if (muted) {
        await _engine.stop();
        _enginePlaying = false;
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _engine.dispose();
      await _oneshotA.dispose();
      await _oneshotB.dispose();
    } catch (_) {}
  }

  Future<void> handleEvents(Iterable<RoadFighterSfxEvent> events) async {
    for (final e in events) {
      switch (e) {
        case RoadFighterSfxEvent.start:
          await _playOneShot('games/road_fighter/start.wav', volume: 0.7);
          await startEngine();
        case RoadFighterSfxEvent.fuel:
          await _playOneShot('games/road_fighter/fuel.wav', volume: 0.75);
        case RoadFighterSfxEvent.pass:
          await _playOneShot('games/road_fighter/pass.wav', volume: 0.35);
        case RoadFighterSfxEvent.crash:
          await stopEngine();
          await _playOneShot('games/road_fighter/crash.wav', volume: 0.9);
        case RoadFighterSfxEvent.outOfFuel:
          await stopEngine();
          await _playOneShot('games/road_fighter/out_of_fuel.wav', volume: 0.8);
      }
    }
  }

  Future<void> startEngine() async {
    if (_muted || _enginePlaying) return;
    try {
      await _engine.setReleaseMode(ReleaseMode.loop);
      await _engine.setVolume(0.28);
      await _engine.play(AssetSource('games/road_fighter/engine_loop.wav'));
      _enginePlaying = true;
    } catch (_) {
      _enginePlaying = false;
    }
  }

  Future<void> stopEngine() async {
    _enginePlaying = false;
    try {
      await _engine.stop();
    } catch (_) {}
  }

  Future<void> syncEngine({
    required bool running,
    required double speed,
    required double minSpeed,
    required double maxSpeed,
  }) async {
    if (_muted || !running) {
      if (_enginePlaying) await stopEngine();
      return;
    }
    if (!_enginePlaying) {
      await startEngine();
    }
    final t = ((speed - minSpeed) / (maxSpeed - minSpeed)).clamp(0.0, 1.0);
    final rate = 0.85 + t * 0.55;
    try {
      await _engine.setPlaybackRate(rate);
    } catch (_) {}
  }

  Future<void> _playOneShot(String asset, {required double volume}) async {
    if (_muted) return;
    final player = _shot.isEven ? _oneshotA : _oneshotB;
    _shot++;
    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(volume);
      await player.play(AssetSource(asset));
    } catch (_) {}
  }
}
