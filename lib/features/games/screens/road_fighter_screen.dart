import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../../core/widgets/maekel_app_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../components/score_submit_helper.dart';
import '../models/games_models.dart';
import '../road_fighter/road_fighter_audio.dart';
import '../road_fighter/road_fighter_engine.dart';

class RoadFighterScreen extends ConsumerStatefulWidget {
  const RoadFighterScreen({super.key});

  @override
  ConsumerState<RoadFighterScreen> createState() => _RoadFighterScreenState();
}

class _RoadFighterScreenState extends ConsumerState<RoadFighterScreen>
    with SingleTickerProviderStateMixin {
  late final RoadFighterEngine _engine;
  late final RoadFighterAudio _audio;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  bool _scoreSubmitted = false;

  @override
  void initState() {
    super.initState();
    _engine = RoadFighterEngine();
    _audio = RoadFighterAudio();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 0.0
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.05) {
      setState(() {});
      return;
    }
    setState(() => _engine.update(dt));
    final events = _engine.takeSfxEvents();
    if (events.isNotEmpty) {
      unawaited(_audio.handleEvents(events));
    }
    unawaited(
      _audio.syncEngine(
        running: _engine.isRunning,
        speed: _engine.speed,
        minSpeed: RoadFighterEngine.minSpeed,
        maxSpeed: RoadFighterEngine.maxSpeed,
      ),
    );
    _maybeSubmitScore();
  }

  void _maybeSubmitScore() {
    if (!_engine.isGameOver || _scoreSubmitted) return;
    _scoreSubmitted = true;
    unawaited(
      submitArcadeScore(
        context: context,
        ref: ref,
        game: ArcadeGame.roadFighter,
        score: _engine.score,
      ),
    );
  }

  void _restart() {
    unawaited(_audio.stopEngine());
    setState(() {
      _scoreSubmitted = false;
      _engine.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fuelPct = (_engine.fuel / 100).clamp(0.0, 1.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MaekelAppBar(
        title: AppLocalizations.of(context)!.roadFighter,
        actions: [
          IconButton(
            tooltip: _audio.isMuted
                ? AppLocalizations.of(context)!.gamesUnmute
                : AppLocalizations.of(context)!.gamesMute,
            onPressed: () async {
              await _audio.setMuted(!_audio.isMuted);
              if (mounted) setState(() {});
            },
            icon: Icon(
              _audio.isMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.gamesRestart,
            onPressed: _restart,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FuturisticBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Stat(
                      label: AppLocalizations.of(context)!.gamesScore,
                      value: '${_engine.score}',
                    ),
                    _Stat(
                      label: AppLocalizations.of(context)!.gamesKm,
                      value: '${_engine.distanceMeters}',
                    ),
                    _Stat(
                      label: AppLocalizations.of(context)!.gamesSpeed,
                      value: '${_engine.displaySpeed}',
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 88,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.gamesFuel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: MaekelColors.muted,
                                  letterSpacing: 1.1,
                                ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fuelPct,
                              minHeight: 10,
                              backgroundColor:
                                  MaekelColors.panelLift.withValues(alpha: 0.9),
                              color: fuelPct < 0.25
                                  ? MaekelColors.danger
                                  : const Color(0xFF5BE37D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      if ((_engine.playSize.width - size.width).abs() > 0.5 ||
                          (_engine.playSize.height - size.height).abs() > 0.5) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _engine.configure(size));
                        });
                      }
                      return GestureDetector(
                        onTap: () {
                          if (_engine.awaitingStart) {
                            setState(_engine.start);
                          } else if (_engine.isGameOver) {
                            _restart();
                          }
                        },
                        onPanDown: (d) {
                          if (_engine.awaitingStart) {
                            setState(_engine.start);
                          }
                          setState(() => _engine.movePlayerTo(d.localPosition.dx));
                        },
                        onPanUpdate: (d) {
                          setState(() => _engine.movePlayerTo(d.localPosition.dx));
                        },
                        onPanEnd: (_) => setState(() => _engine.setSteer(0)),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1C3A),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: MaekelColors.games.withValues(alpha: 0.45),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: CustomPaint(
                              painter: _RoadPainter(_engine),
                              size: size,
                              child: Stack(
                                children: [
                                  if (_engine.awaitingStart)
                                    _Banner(
                                      label: AppLocalizations.of(context)!
                                          .roadFighter
                                          .toUpperCase(),
                                      detail: AppLocalizations.of(context)!
                                          .gamesTapDragDrive,
                                    ),
                                  if (_engine.isGameOver)
                                    _Banner(
                                      label: _engine.endedByFuel
                                          ? AppLocalizations.of(context)!
                                              .gamesOutOfFuel
                                          : AppLocalizations.of(context)!
                                              .gamesCrash,
                                      detail: AppLocalizations.of(context)!
                                          .gamesScoreTapRetry(_engine.score),
                                    ),
                                  Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 14,
                                    child: Row(
                                      children: [
                                        _HoldButton(
                                          icon: Icons.chevron_left_rounded,
                                          onDown: () =>
                                              setState(() => _engine.setSteer(-1)),
                                          onUp: () =>
                                              setState(() => _engine.setSteer(0)),
                                        ),
                                        const Spacer(),
                                        _HoldButton(
                                          icon: Icons.chevron_right_rounded,
                                          onDown: () =>
                                              setState(() => _engine.setSteer(1)),
                                          onUp: () =>
                                              setState(() => _engine.setSteer(0)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.gamesRoadHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MaekelColors.muted,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: MaekelColors.muted,
                  letterSpacing: 1.1,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: MaekelColors.games,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.icon,
    required this.onDown,
    required this.onUp,
  });

  final IconData icon;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: Container(
        width: 64,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 34),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: MaekelColors.ink,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MaekelColors.muted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter(this.engine);
  final RoadFighterEngine engine;

  static const trafficColors = [
    Color(0xFFFFD84D), // yellow
    Color(0xFF4DA3FF), // blue
    Color(0xFFE8E8E8), // white
    Color(0xFFFF8A3D), // orange
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final roadL = engine.roadLeft;
    final roadR = engine.roadRight;

    // Outer water / tiles (left + right)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, roadL - 18, size.height),
      Paint()..color = const Color(0xFF2F6FBF),
    );
    canvas.drawRect(
      Rect.fromLTWH(roadR + 18, 0, size.width - roadR - 18, size.height),
      Paint()..color = const Color(0xFF2F6FBF),
    );

    // Speckle water tiles
    final speck = Paint()..color = const Color(0xFF9FD0FF);
    for (var y = -((engine.scroll * 0.15) % 24); y < size.height; y += 24) {
      for (var x = 4.0; x < roadL - 22; x += 18) {
        canvas.drawRect(Rect.fromLTWH(x, y, 8, 6), speck);
      }
      for (var x = roadR + 26; x < size.width - 4; x += 18) {
        canvas.drawRect(Rect.fromLTWH(x, y, 8, 6), speck);
      }
    }

    // Grass shoulders
    canvas.drawRect(
      Rect.fromLTWH(roadL - 18, 0, 18, size.height),
      Paint()..color = const Color(0xFF2F9B3A),
    );
    canvas.drawRect(
      Rect.fromLTWH(roadR, 0, 18, size.height),
      Paint()..color = const Color(0xFF2F9B3A),
    );

    // Guardrail stripes
    final railShift = engine.scroll % 20;
    for (var y = -railShift; y < size.height; y += 20) {
      final dark = ((y + railShift) ~/ 20).isEven;
      final paint = Paint()
        ..color = dark ? const Color(0xFF111111) : const Color(0xFFF5F5F5);
      canvas.drawRect(Rect.fromLTWH(roadL - 6, y, 6, 20), paint);
      canvas.drawRect(Rect.fromLTWH(roadR, y, 6, 20), paint);
    }

    // Road asphalt
    canvas.drawRect(
      Rect.fromLTWH(roadL, 0, roadR - roadL, size.height),
      Paint()..color = const Color(0xFF9AA0A8),
    );

    // Lane dashes
    final dashPaint = Paint()..color = const Color(0xFFF4F6F8);
    final dashShift = engine.scroll % 36;
    for (var lane = 1; lane < RoadFighterEngine.laneCount; lane++) {
      final x = roadL + engine.laneWidth * lane;
      for (var y = -dashShift; y < size.height; y += 36) {
        canvas.drawRect(Rect.fromLTWH(x - 2, y, 4, 18), dashPaint);
      }
    }

    // Edge lines
    canvas.drawRect(
      Rect.fromLTWH(roadL, 0, 3, size.height),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(roadR - 3, 0, 3, size.height),
      Paint()..color = Colors.white,
    );

    // Traffic / fuel
    for (final c in engine.cars) {
      if (!c.alive) continue;
      if (c.kind == RoadCarKind.fuel) {
        _drawCar(
          canvas,
          engine.carRect(c),
          body: const Color(0xFF3DDC6A),
          accent: const Color(0xFF0B5C24),
          label: 'F',
        );
      } else {
        _drawCar(
          canvas,
          engine.carRect(c),
          body: trafficColors[c.colorIndex % trafficColors.length],
          accent: const Color(0xFF222222),
          laneSwitcher: c.canSwitchLanes,
        );
      }
    }

    // Player — classic red Road Fighter car
    _drawCar(
      canvas,
      engine.playerRect,
      body: const Color(0xFFE53935),
      accent: const Color(0xFF7A1010),
      windshield: const Color(0xFFE8F4FF),
      isPlayer: true,
    );
  }

  void _drawCar(
    Canvas canvas,
    Rect rect, {
    required Color body,
    required Color accent,
    Color windshield = const Color(0xFFB8D4EA),
    String? label,
    bool isPlayer = false,
    bool laneSwitcher = false,
  }) {
    final px = 2.0;
    // Snap to pixel grid for arcade feel
    final left = (rect.left / px).round() * px;
    final top = (rect.top / px).round() * px;
    final w = (rect.width / px).round() * px;
    final h = (rect.height / px).round() * px;
    final r = Rect.fromLTWH(left, top, w, h);

    // Shadow
    canvas.drawRect(
      r.translate(0, 2),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    // Body
    canvas.drawRect(r, Paint()..color = body);

    // Hood / roof highlight
    canvas.drawRect(
      Rect.fromLTWH(r.left + 4, r.top + 4, r.width - 8, 8),
      Paint()..color = windshield,
    );
    canvas.drawRect(
      Rect.fromLTWH(r.left + 4, r.top + 16, r.width - 8, 6),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // Rear bumper
    canvas.drawRect(
      Rect.fromLTWH(r.left + 3, r.bottom - 8, r.width - 6, 5),
      Paint()..color = accent,
    );

    // Side mirrors / wheels
    canvas.drawRect(
      Rect.fromLTWH(r.left - 3, r.top + 10, 3, 8),
      Paint()..color = const Color(0xFF111111),
    );
    canvas.drawRect(
      Rect.fromLTWH(r.right, r.top + 10, 3, 8),
      Paint()..color = const Color(0xFF111111),
    );
    canvas.drawRect(
      Rect.fromLTWH(r.left - 3, r.bottom - 16, 3, 8),
      Paint()..color = const Color(0xFF111111),
    );
    canvas.drawRect(
      Rect.fromLTWH(r.right, r.bottom - 16, 3, 8),
      Paint()..color = const Color(0xFF111111),
    );

    if (isPlayer) {
      // Tiny blue rear lights like the reference
      canvas.drawRect(
        Rect.fromLTWH(r.left + 5, r.bottom - 7, 4, 3),
        Paint()..color = const Color(0xFF4FC3F7),
      );
      canvas.drawRect(
        Rect.fromLTWH(r.right - 9, r.bottom - 7, 4, 3),
        Paint()..color = const Color(0xFF4FC3F7),
      );
    }

    if (laneSwitcher) {
      canvas.drawRect(
        Rect.fromLTWH(r.left + 6, r.top + 22, r.width - 12, 4),
        Paint()..color = const Color(0xFFB388FF),
      );
    }

    if (label != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          r.center.dx - tp.width / 2,
          r.center.dy - tp.height / 2 + 2,
        ),
      );
    }

    // Outline
    canvas.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.black.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) => true;
}
