import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../l10n/app_localizations.dart';
import '../models/games_models.dart';

class AddisLeaderboardCard extends StatelessWidget {
  const AddisLeaderboardCard({
    super.key,
    required this.game,
    required this.entries,
    this.compact = false,
  });

  final ArcadeGame game;
  final List<LeaderboardEntry> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      accent: MaekelColors.games,
      padding: EdgeInsets.all(compact ? 14 : 18),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: MaekelColors.amber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.gamesTop3Title(game.localized(AppLocalizations.of(context)!)),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: MaekelColors.games,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              AppLocalizations.of(context)!.gamesNoScores,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MaekelColors.muted,
                  ),
            )
          else
            ...entries.map((e) {
              final medal = switch (e.rank) {
                1 => '1',
                2 => '2',
                3 => '3',
                _ => '${e.rank}',
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: e.rank == 1
                            ? MaekelColors.amber.withValues(alpha: 0.18)
                            : MaekelColors.panelLift.withValues(alpha: 0.8),
                        border: Border.all(
                          color: e.rank == 1
                              ? MaekelColors.amber.withValues(alpha: 0.5)
                              : MaekelColors.glassBorder,
                        ),
                      ),
                      child: Text(
                        medal,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: e.rank == 1
                              ? MaekelColors.amber
                              : MaekelColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: MaekelColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${e.score}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: MaekelColors.games,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
