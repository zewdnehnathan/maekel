import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/market_models.dart';

export '../../../core/network/api_providers.dart' show marketRepositoryProvider;

final marketUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).session?.userId;
});

final marketChangeTickProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(marketRepositoryProvider);
  var tick = 0;
  return repo.changes.map((_) => ++tick);
});

final marketCategoriesProvider = Provider<List<MarketCategory>>((ref) {
  ref.watch(marketChangeTickProvider);
  return ref.watch(marketRepositoryProvider).getCategories();
});

final marketSubcitiesProvider = Provider<List<String>>((ref) {
  return ref.watch(marketRepositoryProvider).getSubcities();
});

final marketFiltersProvider =
    NotifierProvider<MarketFiltersNotifier, MarketFilters>(
  MarketFiltersNotifier.new,
);

class MarketFiltersNotifier extends Notifier<MarketFilters> {
  @override
  MarketFilters build() => const MarketFilters();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setCategory(String? categoryId) {
    state = categoryId == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(categoryId: categoryId);
  }

  void setSubcity(String? subcity) {
    state = subcity == null
        ? state.copyWith(clearSubcity: true)
        : state.copyWith(subcity: subcity);
  }

  void setCondition(AdCondition? condition) {
    state = condition == null
        ? state.copyWith(clearCondition: true)
        : state.copyWith(condition: condition);
  }

  void setSort(AdSort sort) => state = state.copyWith(sort: sort);

  void setPriceRange({int? min, int? max}) {
    state = state.copyWith(
      minPrice: min,
      maxPrice: max,
      clearMinPrice: min == null,
      clearMaxPrice: max == null,
    );
  }

  void reset() => state = const MarketFilters();
}

final marketSearchProvider = Provider<List<MarketAd>>((ref) {
  ref.watch(marketChangeTickProvider);
  final filters = ref.watch(marketFiltersProvider);
  return ref.watch(marketRepositoryProvider).searchAds(filters);
});

final marketAdProvider = Provider.family<MarketAd?, String>((ref, adId) {
  ref.watch(marketChangeTickProvider);
  return ref.watch(marketRepositoryProvider).getAd(adId);
});

final marketSellerProvider = Provider.family<MarketSeller?, String>((ref, id) {
  ref.watch(marketChangeTickProvider);
  return ref.watch(marketRepositoryProvider).getSeller(id);
});

final myAdsProvider = Provider<List<MarketAd>>((ref) {
  ref.watch(marketChangeTickProvider);
  final userId = ref.watch(marketUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(marketRepositoryProvider).getAdsForSeller(userId);
});

final favoriteIdsProvider = Provider<Set<String>>((ref) {
  ref.watch(marketChangeTickProvider);
  final userId = ref.watch(marketUserIdProvider);
  if (userId == null) return const {};
  return ref.watch(marketRepositoryProvider).getFavoriteIds(userId);
});

final favoriteAdsProvider = Provider<List<MarketAd>>((ref) {
  ref.watch(marketChangeTickProvider);
  final ids = ref.watch(favoriteIdsProvider);
  final repo = ref.watch(marketRepositoryProvider);
  return ids
      .map(repo.getAd)
      .whereType<MarketAd>()
      .where((a) => a.status == AdStatus.approved)
      .toList();
});

final marketThreadsProvider = Provider<List<ChatThread>>((ref) {
  ref.watch(marketChangeTickProvider);
  final userId = ref.watch(marketUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(marketRepositoryProvider).getThreadsForUser(userId);
});

final marketMessagesProvider =
    Provider.family<List<ChatMessage>, String>((ref, threadId) {
  ref.watch(marketChangeTickProvider);
  return ref.watch(marketRepositoryProvider).getMessages(threadId);
});
