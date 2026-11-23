import 'dart:async';

import '../../../core/network/api_client.dart';
import '../models/ride_models.dart';
import 'ride_repository.dart';

/// HTTP ride repo with an in-memory cache seeded from gateway catalogs.
class ApiRideRepository implements RideRepository {
  ApiRideRepository(this._client) {
    _seedLocalCatalog();
    unawaited(refreshCatalog());
    _poll = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_pollActive());
    });
  }

  final ApiClient _client;
  final _controller = StreamController<void>.broadcast();
  Timer? _poll;

  final List<RidePlace> _places = [];
  final List<RideDriver> _drivers = [];
  final List<RideTrip> _trips = [];
  DriverSession? _driverSession;
  bool _authed = false;

  void dispose() {
    _poll?.cancel();
    _controller.close();
  }

  void _notify() => _controller.add(null);

  Future<void> refreshCatalog() async {
    try {
      final placesRaw = await _client.get('/v1/ride/places');
      _places
        ..clear()
        ..addAll(
          ((placesRaw as Map)['items'] as List)
              .cast<Map<String, dynamic>>()
              .map(_parsePlace),
        );
      for (final id in ['drv-1', 'drv-2']) {
        try {
          final raw = await _client.get('/v1/ride/drivers/$id')
              as Map<String, dynamic>;
          final driver = _parseDriver(raw);
          final idx = _drivers.indexWhere((d) => d.id == driver.id);
          if (idx >= 0) {
            _drivers[idx] = driver;
          } else {
            _drivers.add(driver);
          }
        } catch (_) {}
      }
      _notify();
    } catch (_) {}
  }

  Future<void> refreshAuthed(String userId) async {
    _authed = true;
    try {
      final history = await _client.get('/v1/ride/trips', auth: true);
      _trips
        ..clear()
        ..addAll(
          ((history as Map)['items'] as List)
              .cast<Map<String, dynamic>>()
              .map(_parseTrip),
        );
      for (final t in List.of(_trips)) {
        await _ensureDriverCached(t.driverId);
      }
      final active = await _client.get('/v1/ride/trips/active', auth: true);
      if (active is Map<String, dynamic>) {
        final trip = _parseTrip(active);
        _upsertTrip(trip);
        await _ensureDriverCached(trip.driverId);
      }
      final me = await _client.get('/v1/ride/driver/me', auth: true)
          as Map<String, dynamic>;
      _driverSession = DriverSession(
        driverId: me['id'] as String,
        isOnline: me['isOnline'] as bool? ?? false,
        isApproved: me['isApproved'] as bool? ?? true,
      );
      final driver = _parseDriver(me);
      final idx = _drivers.indexWhere((d) => d.id == driver.id);
      if (idx >= 0) {
        _drivers[idx] = driver;
      } else {
        _drivers.add(driver);
      }
      try {
        final offers = await _client.get('/v1/ride/driver/offers', auth: true);
        for (final raw in ((offers as Map)['items'] as List)
            .cast<Map<String, dynamic>>()) {
          _upsertTrip(_parseTrip(raw), notify: false);
        }
        final driverActive =
            await _client.get('/v1/ride/driver/active', auth: true);
        if (driverActive is Map<String, dynamic>) {
          _upsertTrip(_parseTrip(driverActive), notify: false);
        }
      } catch (_) {}
      _notify();
    } catch (_) {}
  }

  Future<void> _pollActive() async {
    if (!_authed) return;
    try {
      final active = await _client.get('/v1/ride/trips/active', auth: true);
      if (active is Map<String, dynamic>) {
        final trip = _parseTrip(active);
        _upsertTrip(trip, notify: false);
        // Refresh live GPS for the assigned driver.
        if (trip.driverId != null) {
          try {
            final raw = await _client.get('/v1/ride/drivers/${trip.driverId}')
                as Map<String, dynamic>;
            final driver = _parseDriver(raw);
            final idx = _drivers.indexWhere((d) => d.id == driver.id);
            if (idx >= 0) {
              _drivers[idx] = driver;
            } else {
              _drivers.add(driver);
            }
          } catch (_) {}
        }
      }

      final history = await _client.get('/v1/ride/trips', auth: true);
      final list = ((history as Map)['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(_parseTrip)
          .toList();
      for (final t in list) {
        _upsertTrip(t, notify: false);
      }

      // Keep Drive offers/active fresh for two-phone / role-switch flows.
      if (_driverSession != null) {
        try {
          final offers = await _client.get(
            '/v1/ride/driver/offers',
            auth: true,
          );
          for (final raw in ((offers as Map)['items'] as List)
              .cast<Map<String, dynamic>>()) {
            _upsertTrip(_parseTrip(raw), notify: false);
          }
          final driverActive =
              await _client.get('/v1/ride/driver/active', auth: true);
          if (driverActive is Map<String, dynamic>) {
            _upsertTrip(_parseTrip(driverActive), notify: false);
          }
        } catch (_) {}
      }

      _notify();
    } catch (_) {}
  }

  Future<void> _ensureDriverCached(String? driverId) async {
    if (driverId == null || getDriver(driverId) != null) return;
    try {
      final raw =
          await _client.get('/v1/ride/drivers/$driverId') as Map<String, dynamic>;
      final driver = _parseDriver(raw);
      final idx = _drivers.indexWhere((d) => d.id == driver.id);
      if (idx >= 0) {
        _drivers[idx] = driver;
      } else {
        _drivers.add(driver);
      }
    } catch (_) {}
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
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final raw = await _client.post(
      '/v1/ride/quotes',
      auth: true,
      body: {
        'pickupId': pickupId,
        'dropoffId': dropoffId,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
      },
    ) as Map<String, dynamic>;
    final breakdown = raw['breakdown'] as Map<String, dynamic>?;
    return FareQuote(
      id: raw['id'] as String,
      pickupId: raw['pickupId'] as String,
      dropoffId: raw['dropoffId'] as String,
      vehicleClass: raw['vehicleClass'] as String,
      totalEtb: (raw['totalEtb'] as num).toInt(),
      etaMinutes: (raw['etaMinutes'] as num).toInt(),
      createdAt: DateTime.now(),
      distanceKm: (raw['distanceKm'] as num?)?.toDouble(),
      baseEtb: (breakdown?['baseEtb'] as num?)?.toInt(),
      perKmEtb: (breakdown?['perKmEtb'] as num?)?.toDouble(),
    );
  }

  @override
  Future<RideTrip> requestTrip({
    required String passengerId,
    required FareQuote quote,
  }) async {
    final raw = await _client.post(
      '/v1/ride/trips',
      auth: true,
      body: {'quoteId': quote.id},
      headers: {'Idempotency-Key': quote.id},
    ) as Map<String, dynamic>;
    final trip = _parseTrip(raw);
    _upsertTrip(trip);
    return trip;
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
    final raw = await _client.post(
      '/v1/ride/trips/$tripId/cancel',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertTrip(_parseTrip(raw));
  }

  @override
  Future<RideTrip> rateTrip(String tripId, int stars) async {
    final raw = await _client.post(
      '/v1/ride/trips/$tripId/rate',
      auth: true,
      body: {'stars': stars},
    ) as Map<String, dynamic>;
    return _upsertTrip(_parseTrip(raw));
  }

  @override
  DriverSession getDriverSession(String userId) {
    return _driverSession ??
        DriverSession(
          driverId: 'drv-user-$userId',
          isOnline: false,
          isApproved: true,
        );
  }

  @override
  Future<DriverSession> setDriverOnline(String userId, bool online) async {
    final raw = await _client.post(
      '/v1/ride/driver/online',
      auth: true,
      body: {'online': online},
    ) as Map<String, dynamic>;
    _driverSession = DriverSession(
      driverId: raw['id'] as String,
      isOnline: raw['isOnline'] as bool? ?? online,
      isApproved: raw['isApproved'] as bool? ?? true,
    );
    final driver = _parseDriver(raw);
    final idx = _drivers.indexWhere((d) => d.id == driver.id);
    if (idx >= 0) {
      _drivers[idx] = driver;
    } else {
      _drivers.add(driver);
    }
    _notify();
    return _driverSession!;
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
    final raw = await _client.post(
      '/v1/ride/driver/trips/$tripId/accept',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertTrip(_parseTrip(raw));
  }

  @override
  Future<RideTrip> driverAdvance(String tripId) async {
    final raw = await _client.post(
      '/v1/ride/driver/trips/$tripId/advance',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertTrip(_parseTrip(raw));
  }

  @override
  Future<RideTrip> confirmCash(String tripId) async {
    final raw = await _client.post(
      '/v1/ride/driver/trips/$tripId/confirm-cash',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertTrip(_parseTrip(raw));
  }

  @override
  Future<DriverEarningsToday> getDriverEarningsToday(String driverId) async {
    final raw = await _client.get(
      '/v1/ride/driver/earnings/today',
      auth: true,
    ) as Map<String, dynamic>;
    final trips = ((raw['items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_parseTrip)
        .toList();
    for (final t in trips) {
      _upsertTrip(t, notify: false);
    }
    _notify();
    return DriverEarningsToday(
      totalEtb: (raw['totalEtb'] as num?)?.toInt() ?? 0,
      trips: trips,
    );
  }

  @override
  Future<RideTrip> reportTripProblem({
    required String tripId,
    required String reason,
    String? note,
  }) async {
    final raw = await _client.post(
      '/v1/ride/driver/trips/$tripId/report',
      auth: true,
      body: {
        'reason': reason,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    ) as Map<String, dynamic>;
    return _upsertTrip(_parseTrip(raw));
  }

  RideTrip _upsertTrip(RideTrip trip, {bool notify = true}) {
    final idx = _trips.indexWhere((t) => t.id == trip.id);
    if (idx >= 0) {
      _trips[idx] = trip;
    } else {
      _trips.insert(0, trip);
    }
    if (notify) _notify();
    return trip;
  }

  void _seedLocalCatalog() {
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

  RidePlace _parsePlace(Map<String, dynamic> j) {
    return RidePlace(
      id: j['id'] as String,
      name: j['name'] as String,
      subcity: j['subcity'] as String,
      lat: (j['lat'] as num?)?.toDouble() ?? kAddisCenter.latitude,
      lng: (j['lng'] as num?)?.toDouble() ?? kAddisCenter.longitude,
    );
  }

  RideDriver _parseDriver(Map<String, dynamic> j) {
    return RideDriver(
      id: j['id'] as String,
      name: j['name'] as String,
      rating: (j['rating'] as num).toDouble(),
      plate: j['plate'] as String,
      carModel: j['carModel'] as String,
      photoHint: j['photoHint'] as String,
      phoneE164: j['phoneE164'] as String,
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      isOnline: j['isOnline'] as bool? ?? false,
      isApproved: j['isApproved'] as bool? ?? false,
    );
  }

  RideTrip _parseTrip(Map<String, dynamic> j) {
    return RideTrip(
      id: j['id'] as String,
      passengerId: j['passengerId'] as String,
      pickupId: j['pickupId'] as String,
      dropoffId: j['dropoffId'] as String,
      fareEtb: (j['fareEtb'] as num).toInt(),
      vehicleClass: j['vehicleClass'] as String,
      status: TripStatus.values.byName(j['status'] as String),
      createdAt: DateTime.parse(j['createdAt'].toString()),
      driverId: j['driverId'] as String?,
      passengerRating: (j['passengerRating'] as num?)?.toInt(),
      completedAt: j['completedAt'] == null
          ? null
          : DateTime.parse(j['completedAt'].toString()),
      etaMinutes: (j['etaMinutes'] as num?)?.toInt(),
      offerExpiresAt: j['offerExpiresAt'] == null
          ? null
          : DateTime.tryParse(j['offerExpiresAt'].toString()),
      cancelReason: j['cancelReason'] as String?,
      pickupLat: (j['pickupLat'] as num?)?.toDouble(),
      pickupLng: (j['pickupLng'] as num?)?.toDouble(),
      dropoffLat: (j['dropoffLat'] as num?)?.toDouble(),
      dropoffLng: (j['dropoffLng'] as num?)?.toDouble(),
      distanceKm: (j['distanceKm'] as num?)?.toDouble(),
    );
  }

  Future<void> postDriverLocation({
    required double lat,
    required double lng,
  }) async {
    await _client.post(
      '/v1/ride/driver/location',
      auth: true,
      body: {'lat': lat, 'lng': lng},
    );
  }

  Future<RideFareConfig> getFareConfig() async {
    final raw = await _client.get('/v1/ride/config') as Map<String, dynamic>;
    return _parseFareConfig(raw);
  }

  Future<RideFareConfig> updateFareConfig(RideFareConfig config) async {
    final raw = await _client.patch(
      '/v1/ride/ops/config',
      auth: true,
      body: {
        'baseEtb': config.baseEtb,
        'perKmEtb': config.perKmEtb,
        'minFareEtb': config.minFareEtb,
        'offerRadiusKm': config.offerRadiusKm,
        'etaBaseMin': config.etaBaseMin,
        'etaMinPerKm': config.etaMinPerKm,
      },
    ) as Map<String, dynamic>;
    return _parseFareConfig(raw);
  }

  Future<List<RideDriver>> getOpsDrivers() async {
    final raw = await _client.get('/v1/ride/ops/drivers', auth: true);
    final items = ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(_parseDriver)
        .toList();
    for (final d in items) {
      final idx = _drivers.indexWhere((x) => x.id == d.id);
      if (idx >= 0) {
        _drivers[idx] = d;
      } else {
        _drivers.add(d);
      }
    }
    _notify();
    return items;
  }

  Future<RideDriver> setDriverApproved({
    required String driverId,
    required bool approved,
  }) async {
    final raw = await _client.post(
      '/v1/ride/ops/drivers/$driverId/approve',
      auth: true,
      body: {'approved': approved},
    ) as Map<String, dynamic>;
    final driver = _parseDriver(raw);
    final idx = _drivers.indexWhere((d) => d.id == driver.id);
    if (idx >= 0) {
      _drivers[idx] = driver;
    } else {
      _drivers.add(driver);
    }
    _notify();
    return driver;
  }

  Future<List<RideTrip>> getOpsActiveTrips() async {
    final raw = await _client.get('/v1/ride/ops/trips/active', auth: true);
    final items = ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(_parseTrip)
        .toList();
    for (final t in items) {
      _upsertTrip(t, notify: false);
    }
    _notify();
    return items;
  }

  Future<RideTrip> opsCancelTrip(String tripId, {String? note}) async {
    final raw = await _client.post(
      '/v1/ride/ops/trips/$tripId/cancel',
      auth: true,
      body: {if (note != null && note.isNotEmpty) 'note': note},
    ) as Map<String, dynamic>;
    return _upsertTrip(_parseTrip(raw));
  }

  RideFareConfig _parseFareConfig(Map<String, dynamic> raw) {
    return RideFareConfig(
      baseEtb: (raw['baseEtb'] as num).toInt(),
      perKmEtb: (raw['perKmEtb'] as num).toDouble(),
      minFareEtb: (raw['minFareEtb'] as num).toInt(),
      offerRadiusKm: (raw['offerRadiusKm'] as num).toDouble(),
      etaBaseMin: (raw['etaBaseMin'] as num).toDouble(),
      etaMinPerKm: (raw['etaMinPerKm'] as num).toDouble(),
      vehicleClass: raw['vehicleClass'] as String? ?? 'Economy',
    );
  }
}
