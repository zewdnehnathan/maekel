import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/futuristic_backdrop.dart';
import '../../../l10n/app_localizations.dart';

class EventsShell extends StatelessWidget {
  const EventsShell({
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
    if (loc.startsWith(AppRoutes.eventsTickets)) return 2;
    if (loc.startsWith(AppRoutes.eventsMine) ||
        loc.startsWith(AppRoutes.eventsCreate)) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(loc);
    final l10n = AppLocalizations.of(context)!;

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
              selectedIndex: index,
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go(AppRoutes.events);
                  case 1:
                    context.go(AppRoutes.eventsMine);
                  case 2:
                    context.go(AppRoutes.eventsTickets);
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.event_outlined),
                  selectedIcon: const Icon(Icons.event),
                  label: l10n.eventsNavBrowse,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.campaign_outlined),
                  selectedIcon: const Icon(Icons.campaign),
                  label: l10n.eventsNavHost,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.confirmation_number_outlined),
                  selectedIcon: const Icon(Icons.confirmation_number),
                  label: l10n.eventsTickets,
                ),
              ],
            )
          : null,
    );
  }
}
