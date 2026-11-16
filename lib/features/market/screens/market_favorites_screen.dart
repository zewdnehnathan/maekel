import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../components/ad_card.dart';
import '../components/market_shell.dart';
import '../providers/market_providers.dart';

class MarketFavoritesScreen extends ConsumerWidget {
  const MarketFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(favoriteAdsProvider);
    final favorites = ref.watch(favoriteIdsProvider);
    final userId = ref.watch(marketUserIdProvider);

    return MarketShell(
      title: 'Favorites',
      child: ads.isEmpty
          ? const Center(child: Text('No saved ads yet.'))
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
