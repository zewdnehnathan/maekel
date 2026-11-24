import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';
import '../components/events_shell.dart';
import '../models/events_models.dart';
import '../providers/events_providers.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(eventsRepositoryProvider).refreshCatalog(
            filters: ref.read(eventsFiltersProvider),
          );
      if (!mounted) return;
      setState(() => _loading = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _onSearch(String value) {
    ref.read(eventsFiltersProvider.notifier).setQuery(value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).session;
    final categories = ref.watch(eventsCategoriesProvider);
    final subcities = ref.watch(eventsSubcitiesProvider);
    final filters = ref.watch(eventsFiltersProvider);
    final catalog = ref.watch(eventsCatalogProvider);

    return EventsShell(
      title: AppLocalizations.of(context)!.eventsTitle,
      actions: [
        if (session?.isEventsOps == true)
          IconButton(
            tooltip: AppLocalizations.of(context)!.eventsOps,
            onPressed: () => context.push(AppRoutes.eventsOps),
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.eventsCreate,
          onPressed: () => context.push(AppRoutes.eventsCreate),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            TextField(
              controller: _search,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.eventsSearchHint,
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(AppLocalizations.of(context)!.all),
                      selected: filters.categoryId == null,
                      onSelected: (_) {
                        ref
                            .read(eventsFiltersProvider.notifier)
                            .setCategory(null);
                        _reload();
                      },
                    ),
                  ),
                  ...categories.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c.name),
                        selected: filters.categoryId == c.id,
                        onSelected: (_) {
                          ref
                              .read(eventsFiltersProvider.notifier)
                              .setCategory(c.id);
                          _reload();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(AppLocalizations.of(context)!.eventsAnyArea),
                      selected: filters.subcity == null,
                      onSelected: (_) {
                        ref
                            .read(eventsFiltersProvider.notifier)
                            .setSubcity(null);
                        _reload();
                      },
                    ),
                  ),
                  ...subcities.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          localizedPlace(AppLocalizations.of(context)!, s),
                        ),
                        selected: filters.subcity == s,
                        onSelected: (_) {
                          ref
                              .read(eventsFiltersProvider.notifier)
                              .setSubcity(s);
                          _reload();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: MaekelColors.danger))
            else if (catalog.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  AppLocalizations.of(context)!.eventsEmpty,
                  style: const TextStyle(color: MaekelColors.muted),
                ),
              )
            else
              ...catalog.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EventCard(
                    event: e,
                    onTap: () => context.push('${AppRoutes.events}/${e.id}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final MaekelEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final when = _formatWhen(event.startsAt, l10n);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassPanel(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.displayImageUrls.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      event.displayImageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: MaekelColors.panelLift,
                        child: Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    event.priceLabelLocalized(l10n),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: MaekelColors.events,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$when · ${localizedPlace(l10n, event.subcity)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MaekelColors.muted,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${event.venueName} · ${event.categoryName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                event.isSoldOut
                    ? l10n.eventsSoldOut
                    : l10n.eventsSeatsLeft(event.seatsLeft),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: event.isSoldOut
                          ? MaekelColors.danger
                          : MaekelColors.signal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatWhen(DateTime dt, AppLocalizations l10n) {
  final local = dt.toLocal();
  final months = [
    l10n.eventsMonthJan,
    l10n.eventsMonthFeb,
    l10n.eventsMonthMar,
    l10n.eventsMonthApr,
    l10n.eventsMonthMay,
    l10n.eventsMonthJun,
    l10n.eventsMonthJul,
    l10n.eventsMonthAug,
    l10n.eventsMonthSep,
    l10n.eventsMonthOct,
    l10n.eventsMonthNov,
    l10n.eventsMonthDec,
  ];
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day}, $hh:$mm';
}
