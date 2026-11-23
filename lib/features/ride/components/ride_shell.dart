import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../auth/providers/auth_provider.dart';

class RideShell extends ConsumerWidget {
  const RideShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showBottomNav = true,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBottomNav;

  int _indexFor(String loc) {
    if (loc.startsWith(AppRoutes.rideDriver)) return 2;
    if (loc.startsWith(AppRoutes.rideHistory)) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).uri.toString();
    final index = _indexFor(loc);
    final isOps = ref.watch(authProvider).session?.isRideOps == true;

    return Scaffold(
      body: FuturisticBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.home);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: MaekelColors.signal,
                    ),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              letterSpacing: 1.1,
                            ),
                      ),
                    ),
                    if (isOps)
                      IconButton(
                        onPressed: () => context.push(AppRoutes.rideOps),
                        icon: const Icon(Icons.admin_panel_settings_rounded),
                        color: MaekelColors.ride,
                        tooltip: 'Ride ops',
                      ),
                    ...?actions,
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? NavigationBar(
              backgroundColor: MaekelColors.deep.withValues(alpha: 0.96),
              indicatorColor: MaekelColors.ride.withValues(alpha: 0.2),
              selectedIndex: index.clamp(0, 2),
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go(AppRoutes.ride);
                  case 1:
                    context.go(AppRoutes.rideHistory);
                  case 2:
                    context.go(AppRoutes.rideDriver);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.hail_rounded),
                  label: 'Ride',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_rounded),
                  label: 'Trips',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_taxi_rounded),
                  label: 'Drive',
                ),
              ],
            )
          : null,
    );
  }
}
