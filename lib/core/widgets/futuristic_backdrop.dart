import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

/// Animated void scene: drifting signal orbs + faint tech grid.
class FuturisticBackdrop extends StatefulWidget {
  const FuturisticBackdrop({super.key, this.child});

  final Widget? child;

  @override
  State<FuturisticBackdrop> createState() => _FuturisticBackdropState();
}

class _FuturisticBackdropState extends State<FuturisticBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
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
        final t = _controller.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: MaekelColors.voidBlack),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    -0.75 + math.sin(t * math.pi * 2) * 0.15,
                    -0.85 + math.cos(t * math.pi * 2) * 0.1,
                  ),
                  radius: 1.15,
                  colors: [
                    MaekelColors.signal.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    0.9 + math.cos(t * math.pi * 2) * 0.12,
                    0.75 + math.sin(t * math.pi * 2) * 0.1,
                  ),
                  radius: 1.0,
                  colors: [
                    MaekelColors.amber.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    -0.2,
                    0.35 + math.sin(t * math.pi * 2 + 1) * 0.08,
                  ),
                  radius: 0.9,
                  colors: [
                    MaekelColors.violetFog.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            CustomPaint(painter: _GridPainter(progress: t)),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MaekelColors.grid
      ..strokeWidth = 1;

    const step = 42.0;
    final offset = (progress * step) % step;

    for (double x = -step + offset; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -step + offset * 0.6; y < size.height + step; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          MaekelColors.signal.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
