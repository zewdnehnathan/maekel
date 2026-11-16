import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import 'futuristic_backdrop.dart';
import 'glass_panel.dart';
import 'maekel_app_bar.dart';

class StubScaffold extends StatelessWidget {
  const StubScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.footer,
  });

  final String title;
  final String body;
  final List<Widget>? actions;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MaekelAppBar(title: title, actions: actions),
      body: FuturisticBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: kToolbarHeight * 0.15),
                GlassPanel(
                  accent: MaekelColors.amber,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: MaekelColors.amber.withValues(alpha: 0.12),
                          border: Border.all(
                            color: MaekelColors.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'MODULE · ONLINE SOON',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: MaekelColors.amber,
                                fontSize: 11,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        body,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: MaekelColors.muted,
                              fontSize: 16,
                            ),
                      ),
                    ],
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 22),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
