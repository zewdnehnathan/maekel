import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../../core/widgets/module_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _brandController;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlide;

  @override
  void initState() {
    super.initState();
    _brandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _brandFade = CurvedAnimation(
      parent: _brandController,
      curve: Curves.easeOutCubic,
    );
    _brandSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _brandController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(authProvider).session;

    return Scaffold(
      body: FuturisticBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _brandFade,
                  child: SlideTransition(
                    position: _brandSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ADDIS OS',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(letterSpacing: 2.2),
                                  ),
                                  const SizedBox(height: 6),
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return const LinearGradient(
                                        colors: [
                                          MaekelColors.ink,
                                          MaekelColors.signal,
                                          MaekelColors.amber,
                                        ],
                                      ).createShader(bounds);
                                    },
                                    child: Text(
                                      l10n.appName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontSize: 54,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.signOut,
                              onPressed: () {
                                ref.read(authProvider.notifier).signOut();
                                context.go(AppRoutes.auth);
                              },
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    MaekelColors.panel.withValues(alpha: 0.7),
                                side: const BorderSide(
                                  color: MaekelColors.glassBorder,
                                ),
                              ),
                              icon: const Icon(Icons.power_settings_new_rounded),
                              color: MaekelColors.signal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.homeGreeting,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: MaekelColors.muted,
                              ),
                        ),
                        if (session != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: MaekelColors.signal.withValues(alpha: 0.08),
                              border: Border.all(
                                color:
                                    MaekelColors.signal.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              '${session.phoneE164}  ·  ${AppConstants.cityName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: MaekelColors.signal,
                                    letterSpacing: 0.8,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                          if (session.isPlatformAdmin ||
                              session.isMarketModerator ||
                              session.isFoodOps ||
                              session.isRideOps ||
                              session.isEventsOps) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (session.isMarketModerator)
                                  TextButton.icon(
                                    onPressed: () =>
                                        context.push(AppRoutes.marketOps),
                                    icon: const Icon(
                                      Icons.admin_panel_settings_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Market ops'),
                                  ),
                                if (session.isFoodOps)
                                  TextButton.icon(
                                    onPressed: () =>
                                        context.push(AppRoutes.foodOps),
                                    icon: const Icon(
                                      Icons.ramen_dining_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Food ops'),
                                  ),
                                if (session.isRideOps)
                                  TextButton.icon(
                                    onPressed: () =>
                                        context.push(AppRoutes.rideOps),
                                    icon: const Icon(
                                      Icons.local_taxi_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Ride ops'),
                                  ),
                                if (session.isEventsOps)
                                  TextButton.icon(
                                    onPressed: () =>
                                        context.push(AppRoutes.eventsOps),
                                    icon: const Icon(
                                      Icons.event_available_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Events ops'),
                                  ),
                                if (session.isPlatformAdmin)
                                  TextButton.icon(
                                    onPressed: () =>
                                        context.push(AppRoutes.adminStaff),
                                    icon: const Icon(
                                      Icons.group_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Staff'),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.92,
                    children: [
                      ModuleCard(
                        title: l10n.moduleRide,
                        subtitle: l10n.moduleRideDesc,
                        icon: Icons.electric_car_rounded,
                        accent: MaekelColors.ride,
                        delay: const Duration(milliseconds: 120),
                        onTap: () => context.push(AppRoutes.ride),
                      ),
                      ModuleCard(
                        title: l10n.moduleMarket,
                        subtitle: l10n.moduleMarketDesc,
                        icon: Icons.hub_rounded,
                        accent: MaekelColors.market,
                        delay: const Duration(milliseconds: 220),
                        onTap: () => context.push(AppRoutes.market),
                      ),
                      ModuleCard(
                        title: l10n.moduleFood,
                        subtitle: l10n.moduleFoodDesc,
                        icon: Icons.ramen_dining_rounded,
                        accent: MaekelColors.food,
                        delay: const Duration(milliseconds: 320),
                        onTap: () => context.push(AppRoutes.food),
                      ),
                      ModuleCard(
                        title: l10n.moduleEvents,
                        subtitle: l10n.moduleEventsDesc,
                        icon: Icons.event_rounded,
                        accent: MaekelColors.events,
                        delay: const Duration(milliseconds: 420),
                        onTap: () => context.push(AppRoutes.events),
                      ),
                      ModuleCard(
                        title: l10n.moduleGames,
                        subtitle: l10n.moduleGamesDesc,
                        icon: Icons.videogame_asset_rounded,
                        accent: MaekelColors.games,
                        delay: const Duration(milliseconds: 520),
                        onTap: () => context.push(AppRoutes.games),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
