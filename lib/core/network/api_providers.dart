import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/events/services/api_events_repository.dart';
import '../../features/events/services/events_repository.dart';
import '../../features/food/services/api_food_repository.dart';
import '../../features/food/services/food_repository.dart';
import '../../features/market/services/api_market_repository.dart';
import '../../features/market/services/market_repository.dart';
import '../../features/ride/services/api_ride_repository.dart';
import '../../features/ride/services/ride_repository.dart';
import 'api_client.dart';
import 'token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStore: ref.watch(tokenStoreProvider));
});

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  final repo = ApiMarketRepository(ref.watch(apiClientProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  final repo = ApiFoodRepository(ref.watch(apiClientProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  final repo = ApiRideRepository(ref.watch(apiClientProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final repo = ApiEventsRepository(ref.watch(apiClientProvider));
  ref.onDispose(repo.dispose);
  return repo;
});
