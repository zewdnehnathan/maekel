import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/futuristic_backdrop.dart';

class MarketShell extends StatelessWidget {
  const MarketShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.showBottomNav = true,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBottomNav;

  int _indexForLocation(String loc) {
    if (loc.startsWith(AppRoutes.marketFavorites)) return 2;
    if (loc.startsWith(AppRoutes.marketMessages)) return 3;
    if (loc.startsWith(AppRoutes.marketMyAds) ||
        loc.startsWith(AppRoutes.marketSell)) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(loc);

    return Scaffold(
      extendBody: true,
      floatingActionButton: floatingActionButton,
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
                              letterSpacing: 1.2,
                            ),
                      ),
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
              indicatorColor: MaekelColors.signal.withValues(alpha: 0.18),
              selectedIndex: index,
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go(AppRoutes.market);
                  case 1:
                    context.go(AppRoutes.marketMyAds);
                  case 2:
                    context.go(AppRoutes.marketFavorites);
                  case 3:
                    context.go(AppRoutes.marketMessages);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Browse',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  label: 'My ads',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  label: 'Saved',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  label: 'Chats',
                ),
              ],
            )
          : null,
    );
  }
}
