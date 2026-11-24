import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../l10n/app_localizations.dart';

class MarketSafetyBanner extends StatelessWidget {
  const MarketSafetyBanner({
    super.key,
    this.message,
    this.compact = false,
  });

  /// When null, uses [AppLocalizations.marketSafetyBody] (or short if compact).
  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = message ??
        (compact ? l10n.marketSafetyShort : l10n.marketSafetyBody);

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
          text,
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
        text,
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
        title: Text(AppLocalizations.of(context)!.marketBeforeContact),
        content: Text(AppLocalizations.of(context)!.marketSafetyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.marketIUnderstand),
          ),
        ],
      );
    },
  );
  return ok == true;
}
