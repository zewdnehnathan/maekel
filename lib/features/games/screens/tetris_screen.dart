import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../../core/widgets/maekel_app_bar.dart';
import '../components/score_submit_helper.dart';
import '../models/games_models.dart';
import '../tetris/tetris_engine.dart';

class TetrisScreen extends ConsumerStatefulWidget {
  const TetrisScreen({super.key});

  @override
  ConsumerState<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends ConsumerState<TetrisScreen> {
  late final TetrisEngine _engine;
  Timer? _timer;
  Offset? _dragStart;
  Duration _interval = const Duration(milliseconds: 700);
  bool _scoreSubmitted = false;

  @override
  void initState() {
    super.initState();
    _engine = TetrisEngine();
    _armTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    _interval = _engine.tickInterval;
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted) return;
      setState(() => _engine.tick());
      _maybeSubmitScore();
      if (_engine.tickInterval != _interval) {
        _armTimer();
      }
    });
  }

  void _maybeSubmitScore() {
    if (!_engine.isGameOver || _scoreSubmitted) return;
    _scoreSubmitted = true;
    unawaited(
      submitArcadeScore(
        context: context,
        ref: ref,
        game: ArcadeGame.tetris,
        score: _engine.score,
      ),
    );
  }

  void _mutate(VoidCallback action) {
    setState(action);
    _maybeSubmitScore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MaekelAppBar(
        title: 'Tetris',
        actions: [
          IconButton(
            tooltip: _engine.isPaused ? 'Resume' : 'Pause',
            onPressed: () => _mutate(_engine.togglePause),
            icon: Icon(
              _engine.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Restart',
            onPressed: () => _mutate(() {
              _scoreSubmitted = false;
              _engine.reset();
              _armTimer();
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
                _Hud(
                  score: _engine.score,
                  lines: _engine.lines,
                  level: _engine.level,
                  next: _engine.next,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onHorizontalDragStart: (d) =>
                          _dragStart = d.globalPosition,
                      onHorizontalDragUpdate: (d) {
                        final start = _dragStart;
                        if (start == null) return;
                        final dx = d.globalPosition.dx - start.dx;
                        if (dx > 28) {
                          _mutate(_engine.moveRight);
                          _dragStart = d.globalPosition;
                        } else if (dx < -28) {
                          _mutate(_engine.moveLeft);
                          _dragStart = d.globalPosition;
                        }
                      },
                      onVerticalDragUpdate: (d) {
                        if (d.primaryDelta != null && d.primaryDelta! > 10) {
                          _mutate(_engine.softDrop);
                        }
                      },
                      onTap: () => _mutate(_engine.rotate),
                      onDoubleTap: () => _mutate(_engine.hardDrop),
                      child: AspectRatio(
                        aspectRatio: _engine.columns / _engine.rows,
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
                              painter: _TetrisPainter(_engine),
                              child: Stack(
                                children: [
                                  if (_engine.isPaused || _engine.isGameOver)
                                    _OverlayBanner(
                                      label: _engine.isGameOver
                                          ? 'GAME OVER'
                                          : 'PAUSED',
                                      detail: _engine.isGameOver
                                          ? 'Tap refresh to play again'
                                          : 'Tap pause to resume',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Controls(
                  onLeft: () => _mutate(_engine.moveLeft),
                  onRight: () => _mutate(_engine.moveRight),
                  onRotate: () => _mutate(_engine.rotate),
                  onSoft: () => _mutate(_engine.softDrop),
                  onHard: () => _mutate(_engine.hardDrop),
                ),
                const SizedBox(height: 6),
                Text(
                  'Swipe · tap rotate · double-tap hard drop',
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

class _Hud extends StatelessWidget {
  const _Hud({
    required this.score,
    required this.lines,
    required this.level,
    required this.next,
  });

  final int score;
  final int lines;
  final int level;
  final Tetromino? next;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(label: 'SCORE', value: '$score'),
        _Stat(label: 'LINES', value: '$lines'),
        _Stat(label: 'LVL', value: '$level'),
        const Spacer(),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: MaekelColors.panel.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MaekelColors.glassBorder),
          ),
          child: CustomPaint(painter: _NextPainter(next)),
        ),
      ],
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

class _Controls extends StatelessWidget {
  const _Controls({
    required this.onLeft,
    required this.onRight,
    required this.onRotate,
    required this.onSoft,
    required this.onHard,
  });

  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onRotate;
  final VoidCallback onSoft;
  final VoidCallback onHard;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback onTap, {Color? color}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  (color ?? MaekelColors.panelLift).withValues(alpha: 0.95),
              foregroundColor: MaekelColors.ink,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onTap,
            child: Icon(icon),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn(Icons.chevron_left_rounded, onLeft),
        btn(Icons.rotate_right_rounded, onRotate, color: MaekelColors.games),
        btn(Icons.chevron_right_rounded, onRight),
        btn(Icons.arrow_downward_rounded, onSoft),
        btn(
          Icons.vertical_align_bottom_rounded,
          onHard,
          color: MaekelColors.amber,
        ),
      ],
    );
  }
}

class _OverlayBanner extends StatelessWidget {
  const _OverlayBanner({required this.label, required this.detail});

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

class _TetrisPainter extends CustomPainter {
  _TetrisPainter(this.engine);

  final TetrisEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / engine.columns;
    final cellH = size.height / engine.rows;
    final gridPaint = Paint()
      ..color = MaekelColors.grid
      ..strokeWidth = 1;

    for (var x = 0; x <= engine.columns; x++) {
      final dx = x * cellW;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 0; y <= engine.rows; y++) {
      final dy = y * cellH;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    void drawCell(int x, int y, Color color) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x * cellW + 1.5, y * cellH + 1.5, cellW - 3, cellH - 3),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = color);
    }

    for (var y = 0; y < engine.rows; y++) {
      for (var x = 0; x < engine.columns; x++) {
        final type = engine.grid[y][x];
        if (type != null) drawCell(x, y, _colorFor(type));
      }
    }

    final active = engine.active;
    if (active != null) {
      for (final c in active.cells()) {
        if (c.y < 0) continue;
        drawCell(c.x, c.y, _colorFor(active.type));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TetrisPainter oldDelegate) => true;
}

class _NextPainter extends CustomPainter {
  _NextPainter(this.type);
  final Tetromino? type;

  @override
  void paint(Canvas canvas, Size size) {
    if (type == null) return;
    final piece = Piece(type: type!, rotation: 0, originX: 0, originY: 0);
    final cells = piece.cells();
    var minX = cells.first.x;
    var maxX = cells.first.x;
    var minY = cells.first.y;
    var maxY = cells.first.y;
    for (final c in cells) {
      if (c.x < minX) minX = c.x;
      if (c.x > maxX) maxX = c.x;
      if (c.y < minY) minY = c.y;
      if (c.y > maxY) maxY = c.y;
    }
    final cols = maxX - minX + 1;
    final rows = maxY - minY + 1;
    final cell = (size.shortestSide * 0.7) / (cols > rows ? cols : rows);
    final ox = (size.width - cols * cell) / 2;
    final oy = (size.height - rows * cell) / 2;
    final paint = Paint()..color = _colorFor(type!);
    for (final c in cells) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            ox + (c.x - minX) * cell + 1,
            oy + (c.y - minY) * cell + 1,
            cell - 2,
            cell - 2,
          ),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NextPainter oldDelegate) =>
      oldDelegate.type != type;
}

Color _colorFor(Tetromino type) {
  switch (type) {
    case Tetromino.i:
      return const Color(0xFF6EC8FF);
    case Tetromino.o:
      return const Color(0xFFFFB347);
    case Tetromino.t:
      return const Color(0xFFC084FC);
    case Tetromino.s:
      return const Color(0xFF2EF3C5);
    case Tetromino.z:
      return const Color(0xFFFF5C7A);
    case Tetromino.j:
      return const Color(0xFF60A5FA);
    case Tetromino.l:
      return const Color(0xFFFF9F43);
  }
}
