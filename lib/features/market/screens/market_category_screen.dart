import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../components/ad_card.dart';
import '../components/market_shell.dart';
import '../models/market_models.dart';
import '../providers/market_providers.dart';
import '../../../l10n/app_localizations.dart';

class MarketCategoryScreen extends ConsumerStatefulWidget {
  const MarketCategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<MarketCategoryScreen> createState() =>
      _MarketCategoryScreenState();
}

class _MarketCategoryScreenState extends ConsumerState<MarketCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(marketFiltersProvider.notifier).setCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(marketCategoriesProvider);
    MarketCategory? category;
    for (final c in categories) {
      if (c.id == widget.categoryId) {
        category = c;
        break;
      }
    }
    final ads = ref
        .watch(marketSearchProvider)
        .where((a) => a.categoryId == widget.categoryId)
        .toList();
    final favorites = ref.watch(favoriteIdsProvider);
    final l10n = AppLocalizations.of(context)!;
    final title = category?.localized(l10n) ?? l10n.marketCategoryTitle;

    return MarketShell(
      title: title,
      showBottomNav: false,
      child: ads.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.marketNoAdsInCategory))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                          ref
                              .read(marketRepositoryProvider)
                              .toggleFavorite(userId, ad.id);
                        },
                );
              },
            ),
    );
  }
}
