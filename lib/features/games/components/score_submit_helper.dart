import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../models/games_models.dart';
import '../providers/games_providers.dart';
import '../../../l10n/app_localizations.dart';

Future<void> submitArcadeScore({
  required BuildContext context,
  required WidgetRef ref,
  required ArcadeGame game,
  required int score,
}) async {
  if (score <= 0) return;

  final api = ref.read(gamesApiProvider);
  String? displayName;

  try {
    final profile = await api.fetchMyProfile();
    if (!context.mounted) return;
    if (profile == null) {
      displayName = await _askDisplayName(context);
      if (!context.mounted) return;
      if (displayName == null || displayName.trim().length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.gamesScoreNotSaved),
          ),
        );
        return;
      }
    }

    final result = await api.submitScore(
      game: game,
      score: score,
      displayName: displayName,
    );

    ref.invalidate(addisLeaderboardProvider);
    ref.invalidate(gamesProfileProvider);

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final message = result.isNewBest
        ? l10n.gamesPersonalBest(result.personalBest)
        : l10n.gamesScoreSavedBest(result.personalBest);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } on ApiException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.gamesSyncFailed)),
    );
  }
}

Future<String?> _askDisplayName(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: MaekelColors.panel,
        title: Text(AppLocalizations.of(context)!.gamesChooseUsername),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.gamesUsernameHint,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: MaekelColors.muted,
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 24,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.gamesUsernameLabel,
                hintText: AppLocalizations.of(context)!.gamesUsernameHintExample,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.skip),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.gamesSaveScore),
          ),
        ],
      );
    },
  );
}
