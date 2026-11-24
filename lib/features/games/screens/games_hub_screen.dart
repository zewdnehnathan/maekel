import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/locale/language_picker.dart';
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
    final boards = ref.watch(addisLeaderboardProvider);

    return Scaffold(
      appBar: MaekelAppBar(
        title: AppLocalizations.of(context)!.gamesTitle,
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.languageTitle,
            onPressed: () => showLanguagePicker(context, ref),
            icon: const Icon(Icons.translate_rounded),
            color: MaekelColors.signal,
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.gamesRefreshBoard,
            onPressed: () => ref.invalidate(addisLeaderboardProvider),
            icon: const Icon(Icons.refresh_rounded),
            color: MaekelColors.signal,
          ),
        ],
      ),
      body: FuturisticBackdrop(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.gamesQuickPlay,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: MaekelColors.games,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.gamesHubBody,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MaekelColors.muted,
                    ),
              ),
              const SizedBox(height: 18),
              _GameEntry(
                title: AppLocalizations.of(context)!.tetris,
                subtitle: AppLocalizations.of(context)!.gamesTetrisSubtitle,
                icon: Icons.grid_view_rounded,
                onTap: () => context.push(AppRoutes.tetris),
              ),
              const SizedBox(height: 12),
              _GameEntry(
                title: AppLocalizations.of(context)!.brickBreaker,
                subtitle: AppLocalizations.of(context)!.gamesBrickSubtitle,
                icon: Icons.sports_esports_rounded,
                onTap: () => context.push(AppRoutes.brickBreaker),
              ),
              const SizedBox(height: 12),
              _GameEntry(
                title: AppLocalizations.of(context)!.candyCrush,
                subtitle: AppLocalizations.of(context)!.gamesCandySubtitle,
                icon: Icons.bubble_chart_rounded,
                onTap: () => context.push(AppRoutes.candyCrush),
              ),
              const SizedBox(height: 12),
              _GameEntry(
                title: AppLocalizations.of(context)!.roadFighter,
                subtitle: AppLocalizations.of(context)!.gamesRoadSubtitle,
                icon: Icons.directions_car_rounded,
                onTap: () => context.push(AppRoutes.roadFighter),
              ),
              const SizedBox(height: 28),
              Text(
                AppLocalizations.of(context)!.gamesAddisTop3,
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
                    AppLocalizations.of(context)!.gamesLeaderboardOffline,
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
                    const SizedBox(height: 12),
                    AddisLeaderboardCard(
                      game: ArcadeGame.roadFighter,
                      entries: data[ArcadeGame.roadFighter] ?? const [],
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
                      MaekelAppBar.displayTitle(title),
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
