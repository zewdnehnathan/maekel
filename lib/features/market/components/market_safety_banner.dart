import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';

abstract final class MarketSafetyCopy {
  static const tip =
      'Meet in a public place. Inspect before you pay. Never send deposits to strangers. Maekel staff never ask for fees in chat.';

  static const shortTip =
      'Safety: Meet in public. Inspect before paying. Never send deposits to strangers.';

  static const chatBanner =
      'Safety banner: Meet publicly. Inspect before pay. Maekel staff never ask for fees here.';
}

class MarketSafetyBanner extends StatelessWidget {
  const MarketSafetyBanner({
    super.key,
    this.message = MarketSafetyCopy.tip,
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: MaekelColors.amber.withValues(alpha: 0.1),
          border: Border.all(
            color: MaekelColors.amber.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MaekelColors.amber,
                fontSize: 12,
              ),
        ),
      );
    }

    return GlassPanel(
      accent: MaekelColors.amber,
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MaekelColors.amber,
            ),
      ),
    );
  }
}

Future<bool> showMarketSafetyGate(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: MaekelColors.panel,
        title: const Text('Before you contact'),
        content: const Text(MarketSafetyCopy.tip),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I understand'),
          ),
        ],
      );
    },
  );
  return ok == true;
}
