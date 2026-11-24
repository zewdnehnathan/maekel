import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius = 24,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final edge = accent ?? MaekelColors.signal;

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // Solid fill on web — BackdropFilter often paints as an opaque grey
        // slab in CanvasKit once Ethiopic fonts are in the tree.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kIsWeb
              ? [
                  MaekelColors.panelLift.withValues(alpha: 0.98),
                  MaekelColors.panel.withValues(alpha: 0.96),
                ]
              : [
                  MaekelColors.panelLift.withValues(alpha: 0.72),
                  MaekelColors.panel.withValues(alpha: 0.55),
                ],
        ),
        border: Border.all(
          color: Color.lerp(MaekelColors.glassBorder, edge, 0.35)!,
        ),
        boxShadow: [
          BoxShadow(
            color: edge.withValues(alpha: 0.12),
            blurRadius: 28,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: kIsWeb
          ? panel
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: panel,
            ),
    );
  }
}
