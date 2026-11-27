import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/food_models.dart';

export '../../../core/network/api_providers.dart' show foodRepositoryProvider;

final foodUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).session?.userId;
});

final foodChangeTickProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(foodRepositoryProvider);
  var tick = 0;
  return repo.changes.map((_) => ++tick);
});

final foodKindFilterProvider = StateProvider<MerchantKind?>((ref) => null);
final foodQueryProvider = StateProvider<String>((ref) => '');
final foodCoverageSubcityProvider = StateProvider<String?>((ref) => null);

final foodMerchantsProvider = Provider<List<FoodMerchant>>((ref) {
  ref.watch(foodChangeTickProvider);
  final kind = ref.watch(foodKindFilterProvider);
  final query = ref.watch(foodQueryProvider);
  final pin = ref.watch(foodCoverageSubcityProvider);
  var list =
      ref.watch(foodRepositoryProvider).getMerchants(kind: kind, query: query);
  if (pin != null && pin.isNotEmpty) {
    list = list.where((m) => m.covers(pin)).toList();
  }
  return list;
});

final foodMerchantProvider =
    Provider.family<FoodMerchant?, String>((ref, id) {
  ref.watch(foodChangeTickProvider);
  return ref.watch(foodRepositoryProvider).getMerchant(id);
});

final foodMenuProvider = Provider.family<List<MenuItem>, String>((ref, id) {
  ref.watch(foodChangeTickProvider);
  return ref.watch(foodRepositoryProvider).getMenu(id);
});

final foodCartProvider = Provider<FoodCart>((ref) {
  ref.watch(foodChangeTickProvider);
  return ref.watch(foodRepositoryProvider).getCart();
});

final foodOrdersProvider = Provider<List<FoodOrder>>((ref) {
  ref.watch(foodChangeTickProvider);
  final userId = ref.watch(foodUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(foodRepositoryProvider).getOrdersForCustomer(userId);
});

final foodOrderProvider = Provider.family<FoodOrder?, String>((ref, id) {
  ref.watch(foodChangeTickProvider);
  return ref.watch(foodRepositoryProvider).getOrder(id);
});
