import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/futuristic_backdrop.dart';

class FoodShell extends StatelessWidget {
  const FoodShell({
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

  int _indexFor(String loc) {
    if (loc.startsWith(AppRoutes.foodOrders)) return 1;
    if (loc.startsWith(AppRoutes.foodCart)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final index = _indexFor(loc);

    return Scaffold(
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
                              letterSpacing: 1.1,
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
              indicatorColor: MaekelColors.food.withValues(alpha: 0.22),
              selectedIndex: index.clamp(0, 2),
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go(AppRoutes.food);
                  case 1:
                    context.go(AppRoutes.foodOrders);
                  case 2:
                    context.go(AppRoutes.foodCart);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.restaurant_rounded),
                  label: 'Browse',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: 'Orders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shopping_bag_outlined),
                  label: 'Cart',
                ),
              ],
            )
          : null,
    );
  }
}
