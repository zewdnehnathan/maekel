import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/events_models.dart';

export '../../../core/network/api_providers.dart' show eventsRepositoryProvider;

final eventsUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).session?.userId;
});

final eventsChangeTickProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(eventsRepositoryProvider);
  var tick = 0;
  return repo.changes.map((_) => ++tick);
});

final eventsCategoriesProvider = Provider<List<EventCategory>>((ref) {
  ref.watch(eventsChangeTickProvider);
  return ref.watch(eventsRepositoryProvider).getCategories();
});

final eventsSubcitiesProvider = Provider<List<String>>((ref) {
  ref.watch(eventsChangeTickProvider);
  return ref.watch(eventsRepositoryProvider).getSubcities();
});

final eventsFiltersProvider =
    NotifierProvider<EventsFiltersNotifier, EventFilters>(
  EventsFiltersNotifier.new,
);

class EventsFiltersNotifier extends Notifier<EventFilters> {
  @override
  EventFilters build() => const EventFilters();

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

  void reset() => state = const EventFilters();
}

final eventsCatalogProvider = Provider<List<MaekelEvent>>((ref) {
  ref.watch(eventsChangeTickProvider);
  return ref.watch(eventsRepositoryProvider).getCatalog();
});

final eventProvider = Provider.family<MaekelEvent?, String>((ref, id) {
  ref.watch(eventsChangeTickProvider);
  return ref.watch(eventsRepositoryProvider).getEvent(id);
});

final myEventsProvider = Provider<List<MaekelEvent>>((ref) {
  ref.watch(eventsChangeTickProvider);
  return ref.watch(eventsRepositoryProvider).getMyEvents();
});

final myEventTicketsProvider = Provider<List<EventTicket>>((ref) {
  ref.watch(eventsChangeTickProvider);
  return ref.watch(eventsRepositoryProvider).getMyTickets();
});
