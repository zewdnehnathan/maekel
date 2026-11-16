import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../models/games_models.dart';
import '../providers/games_providers.dart';

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
          const SnackBar(
            content: Text('Score not saved — username required.'),
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
    final message = result.isNewBest
        ? 'New personal best: ${result.personalBest}'
        : 'Score saved. Best remains ${result.personalBest}';
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
      const SnackBar(content: Text('Could not sync score. Is the API running?')),
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
        title: const Text('Choose a username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shown on the Addis Ababa top 3 leaderboard.',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: MaekelColors.muted,
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'e.g. BoleAce',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save score'),
          ),
        ],
      );
    },
  );
}
