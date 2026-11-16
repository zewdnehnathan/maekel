import 'dart:async';
import 'dart:math';

import '../models/ride_models.dart';

abstract class RideRepository {
  List<RidePlace> getPlaces();
  RidePlace? getPlace(String id);
  RideDriver? getDriver(String id);
  Future<FareQuote> getQuote({
    required String pickupId,
    required String dropoffId,
  });
  Future<RideTrip> requestTrip({
    required String passengerId,
    required FareQuote quote,
  });
  RideTrip? getTrip(String id);
  RideTrip? getActiveTripForPassenger(String passengerId);
  List<RideTrip> getTripsForPassenger(String passengerId);
  Future<RideTrip> cancelTrip(String tripId);
  Future<RideTrip> rateTrip(String tripId, int stars);
  DriverSession getDriverSession(String userId);
  Future<DriverSession> setDriverOnline(String userId, bool online);
  List<RideTrip> getOpenOffersForDriver(String driverId);
  RideTrip? getActiveTripForDriver(String driverId);
  Future<RideTrip> acceptOffer(String tripId, String driverId);
  Future<RideTrip> driverAdvance(String tripId);
  Future<RideTrip> confirmCash(String tripId);
  Stream<void> get changes;
}

class InMemoryRideRepository implements RideRepository {
  InMemoryRideRepository() {
    _seed();
  }

  final _controller = StreamController<void>.broadcast();
  final _places = <RidePlace>[];
  final _drivers = <RideDriver>[];
  final _trips = <RideTrip>[];
  final _driverSessions = <String, DriverSession>{};
  int _seq = 300;
  final _rng = Random();

  static const vehicleClass = 'Economy';

  void _notify() => _controller.add(null);

  String _id(String prefix) {
    _seq += 1;
    return '$prefix-$_seq';
  }

  void _seed() {
    _places.addAll(const [
      RidePlace(
        id: 'p-bole',
        name: 'Bole Atlas',
        subcity: 'Bole',
        lat: 8.9978,
        lng: 38.7869,
      ),
      RidePlace(
        id: 'p-airport',
        name: 'Bole Airport',
        subcity: 'Bole',
        lat: 8.9779,
        lng: 38.7993,
      ),
      RidePlace(
        id: 'p-cmc',
        name: 'CMC Michael',
        subcity: 'Yeka',
        lat: 9.0227,
        lng: 38.8228,
      ),
      RidePlace(
        id: 'p-piassa',
        name: 'Piassa',
        subcity: 'Arada',
        lat: 9.033,
        lng: 38.752,
      ),
      RidePlace(
        id: 'p-mexico',
        name: 'Mexico Square',
        subcity: 'Kirkos',
        lat: 9.0105,
        lng: 38.7445,
      ),
      RidePlace(
        id: 'p-sarbet',
        name: 'Sarbet',
        subcity: 'Nifas Silk',
        lat: 8.9806,
        lng: 38.7578,
      ),
    ]);

    _drivers.addAll(const [
      RideDriver(
        id: 'drv-1',
        name: 'Abebe G.',
        rating: 4.9,
        plate: 'AA-3-12345',
        carModel: 'Toyota Corolla',
        photoHint: 'AG',
        phoneE164: '+251911200001',
        lat: 9.01,
        lng: 38.78,
      ),
      RideDriver(
        id: 'drv-2',
        name: 'Mulu S.',
        rating: 4.7,
        plate: 'AA-4-77821',
        carModel: 'Hyundai Accent',
        photoHint: 'MS',
        phoneE164: '+251911200002',
        lat: 9.02,
        lng: 38.76,
      ),
    ]);
  }

  @override
  Stream<void> get changes => _controller.stream;

  @override
  List<RidePlace> getPlaces() => List.unmodifiable(_places);

  @override
  RidePlace? getPlace(String id) {
    for (final p in _places) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  RideDriver? getDriver(String id) {
    for (final d in _drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Future<FareQuote> getQuote({
    required String pickupId,
    required String dropoffId,
  }) async {
    if (pickupId == dropoffId) {
      throw StateError('Pickup and dropoff must differ');
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final base = 120 + _rng.nextInt(80);
    final distanceFactor = (pickupId.hashCode - dropoffId.hashCode).abs() % 200;
    final total = base + distanceFactor + 50;
    return FareQuote(
      id: _id('quote'),
      pickupId: pickupId,
      dropoffId: dropoffId,
      vehicleClass: vehicleClass,
      totalEtb: total,
      etaMinutes: 8 + _rng.nextInt(10),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<RideTrip> requestTrip({
    required String passengerId,
    required FareQuote quote,
  }) async {
    final existing = getActiveTripForPassenger(passengerId);
    if (existing != null) {
      throw StateError('You already have an active trip');
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final trip = RideTrip(
      id: _id('trip'),
      passengerId: passengerId,
      pickupId: quote.pickupId,
      dropoffId: quote.dropoffId,
      fareEtb: quote.totalEtb,
      vehicleClass: quote.vehicleClass,
      status: TripStatus.requested,
      createdAt: DateTime.now(),
    );
    _trips.insert(0, trip);
    _notify();
    unawaited(_autoMatch(trip.id));
    return trip;
  }

  Future<void> _autoMatch(String tripId) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx < 0) return;
    if (_trips[idx].status == TripStatus.cancelled) return;
    _trips[idx] = _trips[idx].copyWith(status: TripStatus.matching);
    _notify();

    await Future<void>.delayed(const Duration(seconds: 2));
    final i2 = _trips.indexWhere((t) => t.id == tripId);
    if (i2 < 0 || _trips[i2].status == TripStatus.cancelled) return;

    // Prefer an online demo driver session if any; else assign seed driver.
    String driverId = _drivers.first.id;
    for (final session in _driverSessions.values) {
      if (session.isOnline && session.isApproved) {
        driverId = session.driverId;
        break;
      }
    }
    _trips[i2] = _trips[i2].copyWith(
      status: TripStatus.assigned,
      driverId: driverId,
    );
    _notify();

    await Future<void>.delayed(const Duration(seconds: 2));
    final i3 = _trips.indexWhere((t) => t.id == tripId);
    if (i3 < 0 || _trips[i3].status == TripStatus.cancelled) return;
    if (_trips[i3].status == TripStatus.assigned) {
      _trips[i3] = _trips[i3].copyWith(status: TripStatus.arriving);
      _notify();
    }
  }

  @override
  RideTrip? getTrip(String id) {
    for (final t in _trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  RideTrip? getActiveTripForPassenger(String passengerId) {
    for (final t in _trips) {
      if (t.passengerId == passengerId &&
          t.status != TripStatus.completed &&
          t.status != TripStatus.cancelled) {
        return t;
      }
    }
    return null;
  }

  @override
  List<RideTrip> getTripsForPassenger(String passengerId) {
    final list = _trips.where((t) => t.passengerId == passengerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<RideTrip> cancelTrip(String tripId) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx < 0) throw StateError('Trip not found');
    if (!_trips[idx].canCancel) {
      throw StateError('Cannot cancel now');
    }
    _trips[idx] = _trips[idx].copyWith(status: TripStatus.cancelled);
    _notify();
    return _trips[idx];
  }

  @override
  Future<RideTrip> rateTrip(String tripId, int stars) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx < 0) throw StateError('Trip not found');
    if (_trips[idx].status != TripStatus.completed) {
      throw StateError('Trip not completed');
    }
    _trips[idx] = _trips[idx].copyWith(passengerRating: stars.clamp(1, 5));
    _notify();
    return _trips[idx];
  }

  String _driverIdForUser(String userId) => 'drv-user-$userId';

  @override
  DriverSession getDriverSession(String userId) {
    final id = _driverIdForUser(userId);
    return _driverSessions.putIfAbsent(
      userId,
      () => DriverSession(driverId: id, isOnline: false, isApproved: true),
    );
  }

  @override
  Future<DriverSession> setDriverOnline(String userId, bool online) async {
    final current = getDriverSession(userId);
    // Ensure driver profile exists for this user.
    if (getDriver(current.driverId) == null) {
      _drivers.add(
        RideDriver(
          id: current.driverId,
          name: 'You (Driver)',
          rating: 5.0,
          plate: 'AA-DEMO-01',
          carModel: 'Economy sedan',
          photoHint: 'YO',
          phoneE164: userId.replaceFirst('user-', '+'),
        ),
      );
    }
    final next = current.copyWith(isOnline: online);
    _driverSessions[userId] = next;
    _notify();
    return next;
  }

  @override
  List<RideTrip> getOpenOffersForDriver(String driverId) {
    return _trips
        .where(
          (t) =>
              t.status == TripStatus.matching ||
              (t.status == TripStatus.assigned && t.driverId == driverId),
        )
        .toList();
  }

  @override
  RideTrip? getActiveTripForDriver(String driverId) {
    for (final t in _trips) {
      if (t.driverId == driverId &&
          t.status != TripStatus.completed &&
          t.status != TripStatus.cancelled &&
          t.status != TripStatus.requested &&
          t.status != TripStatus.matching) {
        return t;
      }
    }
    return null;
  }

  @override
  Future<RideTrip> acceptOffer(String tripId, String driverId) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx < 0) throw StateError('Trip not found');
    _trips[idx] = _trips[idx].copyWith(
      driverId: driverId,
      status: TripStatus.assigned,
    );
    _notify();
    return _trips[idx];
  }

  @override
  Future<RideTrip> driverAdvance(String tripId) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx < 0) throw StateError('Trip not found');
    final t = _trips[idx];
    final next = switch (t.status) {
      TripStatus.assigned => TripStatus.arriving,
      TripStatus.arriving => TripStatus.arrived,
      TripStatus.arrived => TripStatus.inProgress,
      TripStatus.inProgress => TripStatus.completed,
      _ => t.status,
    };
    _trips[idx] = t.copyWith(
      status: next,
      completedAt: next == TripStatus.completed ? DateTime.now() : null,
    );
    _notify();
    return _trips[idx];
  }

  @override
  Future<RideTrip> confirmCash(String tripId) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx < 0) throw StateError('Trip not found');
    if (_trips[idx].status != TripStatus.inProgress &&
        _trips[idx].status != TripStatus.completed) {
      throw StateError('Trip not ready for cash confirm');
    }
    _trips[idx] = _trips[idx].copyWith(
      status: TripStatus.completed,
      completedAt: DateTime.now(),
    );
    _notify();
    return _trips[idx];
  }
}
