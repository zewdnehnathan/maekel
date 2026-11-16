import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../../core/widgets/maekel_app_bar.dart';
import '../brick_breaker/brick_breaker_engine.dart';
import '../components/score_submit_helper.dart';
import '../models/games_models.dart';

class BrickBreakerScreen extends ConsumerStatefulWidget {
  const BrickBreakerScreen({super.key});

  @override
  ConsumerState<BrickBreakerScreen> createState() => _BrickBreakerScreenState();
}

class _BrickBreakerScreenState extends ConsumerState<BrickBreakerScreen>
    with SingleTickerProviderStateMixin {
  late final BrickBreakerEngine _engine;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  bool _scoreSubmitted = false;

  @override
  void initState() {
    super.initState();
    _engine = BrickBreakerEngine();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
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
    _maybeSubmitScore();
  }

  void _maybeSubmitScore() {
    if (!_engine.isGameOver || _scoreSubmitted) return;
    _scoreSubmitted = true;
    unawaited(
      submitArcadeScore(
        context: context,
        ref: ref,
        game: ArcadeGame.brickBreaker,
        score: _engine.score,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MaekelAppBar(
        title: 'Brick Breaker',
        actions: [
          IconButton(
            tooltip: 'Restart',
            onPressed: () => setState(() {
              _scoreSubmitted = false;
              _engine.reset();
            }),
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
                    _Stat(label: 'SCORE', value: '${_engine.score}'),
                    _Stat(label: 'LIVES', value: '${_engine.lives}'),
                    _Stat(label: 'LVL', value: '${_engine.level}'),
                    const Spacer(),
                    if (!_engine.ballLaunched && !_engine.isGameOver)
                      Text(
                        'TAP TO LAUNCH',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: MaekelColors.games,
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
                        onTap: () => setState(_engine.launch),
                        onPanUpdate: (d) {
                          setState(() {
                            _engine.movePaddleTo(d.localPosition.dx);
                          });
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: MaekelColors.deep.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: MaekelColors.games.withValues(alpha: 0.45),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: CustomPaint(
                              painter: _BrickPainter(_engine),
                              size: size,
                              child: Stack(
                                children: [
                                  if (_engine.isGameOver)
                                    const _Banner(
                                      label: 'GAME OVER',
                                      detail: 'Tap refresh to try again',
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
                  'Drag to move paddle · tap to launch',
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

class _BrickPainter extends CustomPainter {
  _BrickPainter(this.engine);
  final BrickBreakerEngine engine;

  static const brickColors = [
    Color(0xFF6EC8FF),
    Color(0xFF2EF3C5),
    Color(0xFFFFB347),
    Color(0xFFFF5C7A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Playfield grid whisper
    final grid = Paint()
      ..color = MaekelColors.grid
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    for (final brick in engine.bricks) {
      if (!brick.isAlive) continue;
      final color = brickColors[brick.colorIndex % brickColors.length];
      canvas.drawRRect(
        RRect.fromRectAndRadius(brick.rect, const Radius.circular(5)),
        Paint()..color = color.withValues(alpha: brick.hits > 1 ? 1 : 0.85),
      );
      if (brick.hits > 1) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            brick.rect.deflate(2),
            const Radius.circular(4),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white.withValues(alpha: 0.55),
        );
      }
    }

    // Paddle
    canvas.drawRRect(
      RRect.fromRectAndRadius(engine.paddle, const Radius.circular(10)),
      Paint()..color = MaekelColors.games,
    );

    // Ball
    canvas.drawCircle(
      engine.ball,
      BrickBreakerEngine.ballRadius,
      Paint()..color = MaekelColors.ink,
    );
    canvas.drawCircle(
      engine.ball,
      BrickBreakerEngine.ballRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = MaekelColors.signal,
    );
  }

  @override
  bool shouldRepaint(covariant _BrickPainter oldDelegate) => true;
}
