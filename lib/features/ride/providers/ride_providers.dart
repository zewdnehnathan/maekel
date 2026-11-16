import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/ride_models.dart';

export '../../../core/network/api_providers.dart' show rideRepositoryProvider;

final rideUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).session?.userId;
});

final rideChangeTickProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(rideRepositoryProvider);
  var tick = 0;
  return repo.changes.map((_) => ++tick);
});

final ridePlacesProvider = Provider<List<RidePlace>>((ref) {
  ref.watch(rideChangeTickProvider);
  return ref.watch(rideRepositoryProvider).getPlaces();
});

final rideTripProvider = Provider.family<RideTrip?, String>((ref, id) {
  ref.watch(rideChangeTickProvider);
  return ref.watch(rideRepositoryProvider).getTrip(id);
});

final rideActiveTripProvider = Provider<RideTrip?>((ref) {
  ref.watch(rideChangeTickProvider);
  final userId = ref.watch(rideUserIdProvider);
  if (userId == null) return null;
  return ref.watch(rideRepositoryProvider).getActiveTripForPassenger(userId);
});

final rideHistoryProvider = Provider<List<RideTrip>>((ref) {
  ref.watch(rideChangeTickProvider);
  final userId = ref.watch(rideUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(rideRepositoryProvider).getTripsForPassenger(userId);
});

final rideDriverSessionProvider = Provider<DriverSession?>((ref) {
  ref.watch(rideChangeTickProvider);
  final userId = ref.watch(rideUserIdProvider);
  if (userId == null) return null;
  return ref.watch(rideRepositoryProvider).getDriverSession(userId);
});

final rideDriverActiveTripProvider = Provider<RideTrip?>((ref) {
  ref.watch(rideChangeTickProvider);
  final session = ref.watch(rideDriverSessionProvider);
  if (session == null) return null;
  return ref.watch(rideRepositoryProvider).getActiveTripForDriver(session.driverId);
});
