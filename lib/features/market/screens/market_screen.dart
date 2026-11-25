import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../components/ad_card.dart';
import '../components/market_shell.dart';
import '../models/market_models.dart';
import '../providers/market_providers.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  IconData _iconFor(String name) {
    switch (name) {
      case 'phone':
        return Icons.smartphone_rounded;
      case 'devices':
        return Icons.devices_other_rounded;
      case 'car':
        return Icons.directions_car_filled_rounded;
      case 'home':
        return Icons.apartment_rounded;
      case 'chair':
        return Icons.chair_rounded;
      case 'checkroom':
        return Icons.checkroom_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(marketCategoriesProvider);
    final ads = ref.watch(marketSearchProvider);
    final favorites = ref.watch(favoriteIdsProvider);
    final filters = ref.watch(marketFiltersProvider);
    final subcities = ref.watch(marketSubcitiesProvider);

    return MarketShell(
      title: AppLocalizations.of(context)!.marketTitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.marketSell),
        backgroundColor: MaekelColors.signal,
        foregroundColor: MaekelColors.voidBlack,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context)!.marketSellAction),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text(
            AppLocalizations.of(context)!.marketSubtitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.marketBlurb,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) =>
                ref.read(marketFiltersProvider.notifier).setQuery(v),
            style: const TextStyle(color: MaekelColors.ink),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.marketSearchHint,
              prefixIcon: Icon(Icons.search_rounded, color: MaekelColors.signal),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: filters.subcity != null
                      ? localizedPlace(
                          AppLocalizations.of(context)!,
                          filters.subcity!,
                        )
                      : AppLocalizations.of(context)!.marketAllAreas,
                  selected: filters.subcity != null,
                  onTap: () => _pickSubcity(context, ref, subcities),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: filters.condition?.localized(
                        AppLocalizations.of(context)!,
                      ) ??
                      AppLocalizations.of(context)!.marketCondition,
                  selected: filters.condition != null,
                  onTap: () => _pickCondition(context, ref),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _priceLabel(context, filters),
                  selected: filters.minPrice != null || filters.maxPrice != null,
                  onTap: () => _pickPrice(context, ref),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: switch (filters.sort) {
                    AdSort.newest =>
                      AppLocalizations.of(context)!.marketSortNewest,
                    AdSort.priceLow =>
                      AppLocalizations.of(context)!.marketSortPriceUpChip,
                    AdSort.priceHigh =>
                      AppLocalizations.of(context)!.marketSortPriceDownChip,
                  },
                  selected: true,
                  onTap: () => _pickSort(context, ref),
                ),
                if (filters.categoryId != null ||
                    filters.subcity != null ||
                    filters.condition != null ||
                    filters.minPrice != null ||
                    filters.maxPrice != null ||
                    filters.query.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppLocalizations.of(context)!.clear,
                    selected: false,
                    onTap: () =>
                        ref.read(marketFiltersProvider.notifier).reset(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.marketCategories.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final allSelected = filters.categoryId == null;
                  return InkWell(
                    onTap: () {
                      ref.read(marketFiltersProvider.notifier).setCategory(null);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      width: 108,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: allSelected
                            ? MaekelColors.signal.withValues(alpha: 0.14)
                            : MaekelColors.panel.withValues(alpha: 0.8),
                        border: Border.all(
                          color: allSelected
                              ? MaekelColors.signal.withValues(alpha: 0.5)
                              : MaekelColors.glassBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.apps_rounded, color: MaekelColors.amber),
                          const Spacer(),
                          Text(
                            AppLocalizations.of(context)!.marketAllCategories,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final c = categories[index - 1];
                final selected = filters.categoryId == c.id;
                return InkWell(
                  onTap: () {
                    ref.read(marketFiltersProvider.notifier).setCategory(c.id);
                    context.push('${AppRoutes.market}/c/${c.id}');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    width: 108,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: selected
                          ? MaekelColors.signal.withValues(alpha: 0.14)
                          : MaekelColors.panel.withValues(alpha: 0.8),
                      border: Border.all(
                        color: selected
                            ? MaekelColors.signal.withValues(alpha: 0.5)
                            : MaekelColors.glassBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_iconFor(c.iconName), color: MaekelColors.amber),
                        const Spacer(),
                        Text(
                          c.localized(AppLocalizations.of(context)!),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: MaekelColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.marketNearYou.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.marketAdsCount(ads.length),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ads.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                AppLocalizations.of(context)!.marketNoMatch,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ads.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, index) {
                final ad = ads[index];
                final userId = ref.read(marketUserIdProvider);
                return AdCard(
                  ad: ad,
                  isFavorite: favorites.contains(ad.id),
                  onTap: () => context.push('${AppRoutes.market}/ads/${ad.id}'),
                  onFavoriteTap: userId == null
                      ? null
                      : () {
                          ref.read(marketRepositoryProvider).toggleFavorite(
                                userId,
                                ad.id,
                              );
                        },
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _pickSubcity(
    BuildContext context,
    WidgetRef ref,
    List<String> subcities,
  ) async {
    final current = ref.read(marketFiltersProvider).subcity;
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: MaekelColors.panel,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.marketAllAreas),
                trailing: current == null
                    ? const Icon(Icons.check, color: MaekelColors.signal)
                    : null,
                onTap: () => Navigator.pop(context, ''),
              ),
              ...subcities.map(
                (s) => ListTile(
                  title: Text(
                    localizedPlace(AppLocalizations.of(context)!, s),
                  ),
                  trailing: current == s
                      ? const Icon(Icons.check, color: MaekelColors.signal)
                      : null,
                  onTap: () => Navigator.pop(context, s),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    ref.read(marketFiltersProvider.notifier).setSubcity(
          picked.isEmpty ? null : picked,
        );
  }

  String _priceLabel(BuildContext context, MarketFilters filters) {
    final l10n = AppLocalizations.of(context)!;
    final min = filters.minPrice;
    final max = filters.maxPrice;
    if (min != null && max != null) {
      return l10n.marketPriceRangeMinMax(min, max);
    }
    if (min != null) return l10n.marketPriceRangeMinPlus(min);
    if (max != null) return l10n.marketPriceRangeUpTo(max);
    return l10n.marketPriceRange;
  }

  Future<void> _pickPrice(BuildContext context, WidgetRef ref) async {
    final current = ref.read(marketFiltersProvider);
    final minController = TextEditingController(
      text: current.minPrice?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: current.maxPrice?.toString() ?? '',
    );
    final applied = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: MaekelColors.panel,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.marketPriceRangeEtb,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: MaekelColors.ink),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.marketMinimum,
                    hintText: AppLocalizations.of(context)!.marketAny,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: MaekelColors.ink),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.marketMaximum,
                    hintText: AppLocalizations.of(context)!.marketAny,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref
                              .read(marketFiltersProvider.notifier)
                              .setPriceRange();
                          Navigator.pop(context, true);
                        },
                        child: Text(AppLocalizations.of(context)!.clear),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final min = int.tryParse(minController.text.trim());
                          final max = int.tryParse(maxController.text.trim());
                          if (min != null && max != null && min > max) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!
                                      .marketMinMaxError,
                                ),
                              ),
                            );
                            return;
                          }
                          ref.read(marketFiltersProvider.notifier).setPriceRange(
                                min: min,
                                max: max,
                              );
                          Navigator.pop(context, true);
                        },
                        child: Text(AppLocalizations.of(context)!.apply),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    minController.dispose();
    maxController.dispose();
    if (applied != true) return;
  }

  Future<void> _pickCondition(BuildContext context, WidgetRef ref) async {
    final current = ref.read(marketFiltersProvider).condition;
    final picked = await showModalBottomSheet<AdCondition?>(
      context: context,
      backgroundColor: MaekelColors.panel,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.marketAnyCondition),
                onTap: () => Navigator.pop(context, null),
              ),
              ...AdCondition.values.map(
                (c) => ListTile(
                  title: Text(c.localized(AppLocalizations.of(context)!)),
                  trailing: current == c
                      ? const Icon(Icons.check, color: MaekelColors.signal)
                      : null,
                  onTap: () => Navigator.pop(context, c),
                ),
              ),
            ],
          ),
        );
      },
    );
    ref.read(marketFiltersProvider.notifier).setCondition(picked);
  }

  Future<void> _pickSort(BuildContext context, WidgetRef ref) async {
    final current = ref.read(marketFiltersProvider).sort;
    final picked = await showModalBottomSheet<AdSort>(
      context: context,
      backgroundColor: MaekelColors.panel,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in AdSort.values)
                ListTile(
                  title: Text(switch (s) {
                    AdSort.newest =>
                      AppLocalizations.of(context)!.marketSortNewest,
                    AdSort.priceLow =>
                      AppLocalizations.of(context)!.marketSortPriceLow,
                    AdSort.priceHigh =>
                      AppLocalizations.of(context)!.marketSortPriceHigh,
                  }),
                  trailing: current == s
                      ? const Icon(Icons.check, color: MaekelColors.signal)
                      : null,
                  onTap: () => Navigator.pop(context, s),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      ref.read(marketFiltersProvider.notifier).setSort(picked);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? MaekelColors.signal.withValues(alpha: 0.14)
              : MaekelColors.panel,
          border: Border.all(
            color: selected
                ? MaekelColors.signal.withValues(alpha: 0.5)
                : MaekelColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? MaekelColors.signal : MaekelColors.ink,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
