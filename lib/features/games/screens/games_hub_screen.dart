import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/maekel_app_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../components/addis_leaderboard_card.dart';
import '../models/games_models.dart';
import '../providers/games_providers.dart';

class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final boards = ref.watch(addisLeaderboardProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MaekelAppBar(
        title: l10n.gamesTitle,
        actions: [
          IconButton(
            tooltip: 'Refresh leaderboard',
            onPressed: () => ref.invalidate(addisLeaderboardProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FuturisticBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const SizedBox(height: 8),
              Text(
                'QUICK PLAY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: MaekelColors.games,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Play offline, sync your best scores to the Addis board.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MaekelColors.muted,
                    ),
              ),
              const SizedBox(height: 18),
              _GameEntry(
                title: l10n.tetris,
                subtitle: 'Stack · clear lines · level up',
                icon: Icons.grid_view_rounded,
                onTap: () => context.push(AppRoutes.tetris),
              ),
              const SizedBox(height: 12),
              _GameEntry(
                title: l10n.brickBreaker,
                subtitle: 'Bounce · smash bricks · survive',
                icon: Icons.sports_esports_rounded,
                onTap: () => context.push(AppRoutes.brickBreaker),
              ),
              const SizedBox(height: 12),
              _GameEntry(
                title: l10n.candyCrush,
                subtitle: 'Swap · match 3 · cascade score',
                icon: Icons.bubble_chart_rounded,
                onTap: () => context.push(AppRoutes.candyCrush),
              ),
              const SizedBox(height: 28),
              Text(
                'ADDIS TOP 3',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: MaekelColors.games,
                    ),
              ),
              const SizedBox(height: 12),
              boards.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => GlassPanel(
                  accent: MaekelColors.danger,
                  child: Text(
                    'Leaderboard offline — start backend games-service to see Addis top 3.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MaekelColors.muted,
                        ),
                  ),
                ),
                data: (data) => Column(
                  children: [
                    AddisLeaderboardCard(
                      game: ArcadeGame.tetris,
                      entries: data[ArcadeGame.tetris] ?? const [],
                    ),
                    const SizedBox(height: 12),
                    AddisLeaderboardCard(
                      game: ArcadeGame.brickBreaker,
                      entries: data[ArcadeGame.brickBreaker] ?? const [],
                    ),
                    const SizedBox(height: 12),
                    AddisLeaderboardCard(
                      game: ArcadeGame.candyCrush,
                      entries: data[ArcadeGame.candyCrush] ?? const [],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameEntry extends StatelessWidget {
  const _GameEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassPanel(
          accent: MaekelColors.games,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          borderRadius: 18,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: MaekelColors.games.withValues(alpha: 0.14),
                  border: Border.all(
                    color: MaekelColors.games.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(icon, color: MaekelColors.games),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            letterSpacing: 1.1,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MaekelColors.muted,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_arrow_rounded,
                color: MaekelColors.games.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
