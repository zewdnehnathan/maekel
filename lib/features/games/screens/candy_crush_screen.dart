import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../../core/widgets/maekel_app_bar.dart';
import '../candy_crush/candy_crush_engine.dart';
import '../components/score_submit_helper.dart';
import '../models/games_models.dart';

class CandyCrushScreen extends ConsumerStatefulWidget {
  const CandyCrushScreen({super.key});

  @override
  ConsumerState<CandyCrushScreen> createState() => _CandyCrushScreenState();
}

class _CandyCrushScreenState extends ConsumerState<CandyCrushScreen>
    with SingleTickerProviderStateMixin {
  late final CandyCrushEngine _engine;
  late final AnimationController _swapController;
  bool _scoreSubmitted = false;
  bool _playingFx = false;
  List<_ExplosionFx> _explosions = const [];

  int? _dragRow;
  int? _dragCol;
  Offset _dragOffset = Offset.zero;
  _SwapFlight? _swapFlight;

  static const _candyColors = <Color>[
    Color(0xFFFF5C7A),
    Color(0xFF6EC8FF),
    Color(0xFFFFB347),
    Color(0xFF2EF3C5),
    Color(0xFFC084FC),
    Color(0xFFFFE566),
  ];

  @override
  void initState() {
    super.initState();
    _engine = CandyCrushEngine();
    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _swapController.dispose();
    super.dispose();
  }

  void _maybeSubmitScore() {
    if (!_engine.isGameOver || _scoreSubmitted) return;
    _scoreSubmitted = true;
    unawaited(
      submitArcadeScore(
        context: context,
        ref: ref,
        game: ArcadeGame.candyCrush,
        score: _engine.score,
      ),
    );
  }

  Future<void> _onTileTap(int r, int c) async {
    if (_playingFx || _swapFlight != null || !_engine.canInteract) return;

    final from = _engine.selected;
    if (from != null && _engine.isAdjacent(from.$1, from.$2, r, c)) {
      await _animateAndCommitSwap(from.$1, from.$2, r, c);
      return;
    }

    final started = _engine.tapCell(r, c);
    setState(() {});
    if (!started) return;
    await _playCascadeExplosions();
    if (!mounted) return;
    setState(() {});
    _maybeSubmitScore();
  }

  void _onPanStart(int r, int c) {
    if (_playingFx || _swapFlight != null || !_engine.canInteract) return;
    setState(() {
      _engine.selected = null;
      _dragRow = r;
      _dragCol = c;
      _dragOffset = Offset.zero;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, double cellW, double cellH) {
    if (_dragRow == null || _dragCol == null) return;
    setState(() {
      var dx = _dragOffset.dx + details.delta.dx;
      var dy = _dragOffset.dy + details.delta.dy;
      // Lock to the stronger axis so swaps feel like Candy Crush.
      if (dx.abs() > dy.abs()) {
        dy = 0;
        dx = dx.clamp(-cellW, cellW);
      } else {
        dx = 0;
        dy = dy.clamp(-cellH, cellH);
      }
      _dragOffset = Offset(dx, dy);
    });
  }

  Future<void> _onPanEnd(double cellW, double cellH) async {
    final r = _dragRow;
    final c = _dragCol;
    if (r == null || c == null) return;

    final threshold = math.min(cellW, cellH) * 0.35;
    int? tr;
    int? tc;
    if (_dragOffset.dx >= threshold) {
      tr = r;
      tc = c + 1;
    } else if (_dragOffset.dx <= -threshold) {
      tr = r;
      tc = c - 1;
    } else if (_dragOffset.dy >= threshold) {
      tr = r + 1;
      tc = c;
    } else if (_dragOffset.dy <= -threshold) {
      tr = r - 1;
      tc = c;
    }

    setState(() {
      _dragRow = null;
      _dragCol = null;
      _dragOffset = Offset.zero;
    });

    if (tr == null ||
        tc == null ||
        tr < 0 ||
        tc < 0 ||
        tr >= CandyCrushEngine.rows ||
        tc >= CandyCrushEngine.cols) {
      return;
    }

    await _animateAndCommitSwap(r, c, tr, tc);
  }

  Future<void> _animateAndCommitSwap(
    int r1,
    int c1,
    int r2,
    int c2,
  ) async {
    if (_playingFx || _swapFlight != null || !_engine.canInteract) return;
    if (!_engine.isAdjacent(r1, c1, r2, c2)) return;

    final colorA = _engine.board[r1][c1];
    final colorB = _engine.board[r2][c2];
    if (colorA < 0 || colorB < 0) return;

    setState(() {
      _engine.selected = null;
      _swapFlight = _SwapFlight(
        r1: r1,
        c1: c1,
        r2: r2,
        c2: c2,
        colorA: colorA,
        colorB: colorB,
        reverse: false,
      );
    });

    _swapController.value = 0;
    await _swapController.forward();
    if (!mounted) return;

    final matched = _engine.swapCells(r1, c1, r2, c2);
    if (!mounted) return;

    if (matched) {
      setState(() => _swapFlight = null);
      await _playCascadeExplosions();
      if (!mounted) return;
      setState(() {});
      _maybeSubmitScore();
      return;
    }

    // Invalid swap — bounce back.
    setState(() {
      _swapFlight = _SwapFlight(
        r1: r1,
        c1: c1,
        r2: r2,
        c2: c2,
        colorA: colorA,
        colorB: colorB,
        reverse: true,
      );
    });
    _swapController.value = 0;
    await _swapController.forward();
    if (!mounted) return;
    setState(() => _swapFlight = null);
  }

  Future<void> _playCascadeExplosions() async {
    _playingFx = true;
    while (_engine.activeBlasts.isNotEmpty) {
      final wave = List<CandyBlast>.from(_engine.activeBlasts);
      setState(() {
        _explosions = [
          for (final blast in wave)
            _ExplosionFx(
              key: UniqueKey(),
              row: blast.row,
              col: blast.col,
              color: _candyColors[blast.colorIndex % _candyColors.length],
            ),
        ];
      });

      await Future<void>.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;

      final more = _engine.finishBlastWave();
      setState(() => _explosions = const []);

      if (!more) break;
      await Future<void>.delayed(const Duration(milliseconds: 70));
      if (!mounted) return;
      setState(() {});
    }
    _playingFx = false;
  }

  void _restart() {
    _swapController.stop();
    setState(() {
      _scoreSubmitted = false;
      _playingFx = false;
      _explosions = const [];
      _dragRow = null;
      _dragCol = null;
      _dragOffset = Offset.zero;
      _swapFlight = null;
      _engine.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final blasting = {
      for (final b in _engine.activeBlasts) (b.row, b.col),
    };
    final flight = _swapFlight;
    final hiddenDuringSwap = <(int, int)>{
      if (flight != null) (flight.r1, flight.c1),
      if (flight != null) (flight.r2, flight.c2),
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MaekelAppBar(
        title: 'Candy Crush',
        actions: [
          IconButton(
            tooltip: _engine.isPaused ? 'Resume' : 'Pause',
            onPressed: _playingFx || _swapFlight != null
                ? null
                : () => setState(_engine.togglePause),
            icon: Icon(
              _engine.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Restart',
            onPressed:
                _playingFx || _swapFlight != null ? null : _restart,
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
                    _Stat(label: 'MOVES', value: '${_engine.movesLeft}'),
                    _Stat(
                      label: 'COMBO',
                      value: _engine.combo > 0 ? 'x${_engine.combo}' : '—',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final cellW =
                                  constraints.maxWidth / CandyCrushEngine.cols;
                              final cellH =
                                  constraints.maxHeight / CandyCrushEngine.rows;

                              return AnimatedBuilder(
                                animation: _swapController,
                                builder: (context, _) {
                                  final t = Curves.easeInOut.transform(
                                    _swapController.value,
                                  );
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      for (var r = 0;
                                          r < CandyCrushEngine.rows;
                                          r++)
                                        for (var c = 0;
                                            c < CandyCrushEngine.cols;
                                            c++)
                                          Positioned(
                                            left: c * cellW +
                                                (_dragRow == r &&
                                                        _dragCol == c
                                                    ? _dragOffset.dx
                                                    : 0),
                                            top: r * cellH +
                                                (_dragRow == r &&
                                                        _dragCol == c
                                                    ? _dragOffset.dy
                                                    : 0),
                                            width: cellW,
                                            height: cellH,
                                            child: _CandyTile(
                                              colorIndex: _engine.board[r][c],
                                              colors: _candyColors,
                                              selected:
                                                  _engine.selected?.$1 == r &&
                                                      _engine.selected?.$2 ==
                                                          c,
                                              hidden: blasting.contains(
                                                    (r, c),
                                                  ) ||
                                                  hiddenDuringSwap.contains(
                                                    (r, c),
                                                  ),
                                              elevated: _dragRow == r &&
                                                  _dragCol == c,
                                              onTap: () => unawaited(
                                                _onTileTap(r, c),
                                              ),
                                              onPanStart: (_) =>
                                                  _onPanStart(r, c),
                                              onPanUpdate: (d) =>
                                                  _onPanUpdate(
                                                d,
                                                cellW,
                                                cellH,
                                              ),
                                              onPanEnd: (_) => unawaited(
                                                _onPanEnd(cellW, cellH),
                                              ),
                                              onPanCancel: () {
                                                setState(() {
                                                  _dragRow = null;
                                                  _dragCol = null;
                                                  _dragOffset = Offset.zero;
                                                });
                                              },
                                            ),
                                          ),
                                      if (flight != null) ...[
                                        _flyingCandy(
                                          cellW: cellW,
                                          cellH: cellH,
                                          fromR: flight.r1,
                                          fromC: flight.c1,
                                          toR: flight.r2,
                                          toC: flight.c2,
                                          colorIndex: flight.colorA,
                                          t: flight.reverse ? 1 - t : t,
                                        ),
                                        _flyingCandy(
                                          cellW: cellW,
                                          cellH: cellH,
                                          fromR: flight.r2,
                                          fromC: flight.c2,
                                          toR: flight.r1,
                                          toC: flight.c1,
                                          colorIndex: flight.colorB,
                                          t: flight.reverse ? 1 - t : t,
                                        ),
                                      ],
                                      for (final fx in _explosions)
                                        Positioned(
                                          left: fx.col * cellW,
                                          top: fx.row * cellH,
                                          width: cellW,
                                          height: cellH,
                                          child: _MatchExplosion(
                                            key: fx.key,
                                            color: fx.color,
                                          ),
                                        ),
                                      if (_engine.isPaused ||
                                          _engine.isGameOver)
                                        _OverlayBanner(
                                          label: _engine.isGameOver
                                              ? 'OUT OF MOVES'
                                              : 'PAUSED',
                                          detail: _engine.isGameOver
                                              ? 'Score ${_engine.score} · tap refresh'
                                              : 'Tap pause to resume',
                                        ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Drag a candy onto a neighbor · or tap-tap to swap',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MaekelColors.muted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _flyingCandy({
    required double cellW,
    required double cellH,
    required int fromR,
    required int fromC,
    required int toR,
    required int toC,
    required int colorIndex,
    required double t,
  }) {
    final left = (fromC + (toC - fromC) * t) * cellW;
    final top = (fromR + (toR - fromR) * t) * cellH;
    return Positioned(
      left: left,
      top: top,
      width: cellW,
      height: cellH,
      child: IgnorePointer(
        child: _CandyFace(
          color: _candyColors[colorIndex % _candyColors.length],
          selected: true,
          elevated: true,
        ),
      ),
    );
  }
}

class _SwapFlight {
  const _SwapFlight({
    required this.r1,
    required this.c1,
    required this.r2,
    required this.c2,
    required this.colorA,
    required this.colorB,
    required this.reverse,
  });

  final int r1;
  final int c1;
  final int r2;
  final int c2;
  final int colorA;
  final int colorB;
  final bool reverse;
}

class _ExplosionFx {
  const _ExplosionFx({
    required this.key,
    required this.row,
    required this.col,
    required this.color,
  });

  final Key key;
  final int row;
  final int col;
  final Color color;
}

class _MatchExplosion extends StatefulWidget {
  const _MatchExplosion({super.key, required this.color});

  final Color color;

  @override
  State<_MatchExplosion> createState() => _MatchExplosionState();
}

class _MatchExplosionState extends State<_MatchExplosion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expand;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _expand = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value.clamp(0.0, 1.0),
          child: CustomPaint(
            painter: _ExplosionPainter(
              progress: _expand.value.clamp(0.0, 1.4),
              color: widget.color,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _ExplosionPainter extends CustomPainter {
  _ExplosionPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.18 * (1 + progress * 1.8);

    final glow = Paint()
      ..color = color.withValues(alpha: 0.55 * (1 - progress.clamp(0, 1)))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius * 1.15, glow);

    final core = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(center, radius * 0.35, core);

    final burst = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const shards = 8;
    for (var i = 0; i < shards; i++) {
      final angle = (i / shards) * math.pi * 2;
      final inner = radius * 0.4;
      final outer = radius * (0.9 + (i.isEven ? 0.35 : 0.15));
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        burst,
      );
    }

    final spark = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (var i = 0; i < shards; i++) {
      final angle = (i / shards) * math.pi * 2 + 0.2;
      final dist = radius * 1.05;
      canvas.drawCircle(
        center + Offset(math.cos(angle) * dist, math.sin(angle) * dist),
        2.2,
        spark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExplosionPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _CandyTile extends StatelessWidget {
  const _CandyTile({
    required this.colorIndex,
    required this.colors,
    required this.selected,
    required this.hidden,
    required this.elevated,
    required this.onTap,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  final int colorIndex;
  final List<Color> colors;
  final bool selected;
  final bool hidden;
  final bool elevated;
  final VoidCallback onTap;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onPanCancel;

  @override
  Widget build(BuildContext context) {
    if (hidden || colorIndex < 0) {
      return const SizedBox.expand();
    }

    final color = colorIndex < colors.length
        ? colors[colorIndex]
        : MaekelColors.muted;

    return GestureDetector(
      onTap: onTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      behavior: HitTestBehavior.opaque,
      child: _CandyFace(
        color: color,
        selected: selected || elevated,
        elevated: elevated,
      ),
    );
  }
}

class _CandyFace extends StatelessWidget {
  const _CandyFace({
    required this.color,
    required this.selected,
    required this.elevated,
  });

  final Color color;
  final bool selected;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()
          ..scaleByDouble(elevated ? 1.08 : 1.0, elevated ? 1.08 : 1.0, 1, 1),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.92),
          border: Border.all(
            color: selected ? Colors.white : color.withValues(alpha: 0.35),
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: elevated ? 0.65 : 0.28),
              blurRadius: elevated ? 16 : 6,
              spreadRadius: elevated ? 1 : 0,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.35),
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
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: MaekelColors.panel.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MaekelColors.glassBorder),
        ),
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
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MaekelColors.games,
                  ),
            ),
          ],
        ),
      ),
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
      color: MaekelColors.voidBlack.withValues(alpha: 0.62),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: MaekelColors.games,
                    letterSpacing: 1.4,
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
