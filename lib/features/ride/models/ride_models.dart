import 'package:latlong2/latlong.dart';

enum TripStatus {
  quoting,
  requested,
  matching,
  assigned,
  arriving,
  arrived,
  inProgress,
  completed,
  cancelled,
}

class RidePlace {
  const RidePlace({
    required this.id,
    required this.name,
    required this.subcity,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final String subcity;
  final double lat;
  final double lng;

  LatLng get point => LatLng(lat, lng);
}

class RideDriver {
  const RideDriver({
    required this.id,
    required this.name,
    required this.rating,
    required this.plate,
    required this.carModel,
    required this.photoHint,
    required this.phoneE164,
    this.lat,
    this.lng,
    this.isOnline = false,
    this.isApproved = false,
  });

  final String id;
  final String name;
  final double rating;
  final String plate;
  final String carModel;
  final String photoHint;
  final String phoneE164;
  final double? lat;
  final double? lng;
  final bool isOnline;
  final bool isApproved;

  LatLng? get point =>
      lat == null || lng == null ? null : LatLng(lat!, lng!);
}

class FareQuote {
  const FareQuote({
    required this.id,
    required this.pickupId,
    required this.dropoffId,
    required this.vehicleClass,
    required this.totalEtb,
    required this.etaMinutes,
    required this.createdAt,
    this.distanceKm,
    this.baseEtb,
    this.perKmEtb,
  });

  final String id;
  final String pickupId;
  final String dropoffId;
  final String vehicleClass;
  final int totalEtb;
  final int etaMinutes;
  final DateTime createdAt;
  final double? distanceKm;
  final int? baseEtb;
  final double? perKmEtb;
}

class RideFareConfig {
  const RideFareConfig({
    required this.baseEtb,
    required this.perKmEtb,
    required this.minFareEtb,
    required this.offerRadiusKm,
    required this.etaBaseMin,
    required this.etaMinPerKm,
    this.vehicleClass = 'Economy',
  });

  final int baseEtb;
  final double perKmEtb;
  final int minFareEtb;
  final double offerRadiusKm;
  final double etaBaseMin;
  final double etaMinPerKm;
  final String vehicleClass;
}

class RideTrip {
  const RideTrip({
    required this.id,
    required this.passengerId,
    required this.pickupId,
    required this.dropoffId,
    required this.fareEtb,
    required this.vehicleClass,
    required this.status,
    required this.createdAt,
    this.driverId,
    this.passengerRating,
    this.completedAt,
    this.etaMinutes,
    this.offerExpiresAt,
    this.cancelReason,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.distanceKm,
  });

  final String id;
  final String passengerId;
  final String pickupId;
  final String dropoffId;
  final int fareEtb;
  final String vehicleClass;
  final TripStatus status;
  final DateTime createdAt;
  final String? driverId;
  final int? passengerRating;
  final DateTime? completedAt;
  final int? etaMinutes;
  final DateTime? offerExpiresAt;
  final String? cancelReason;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final double? distanceKm;

  bool get canCancel =>
      status == TripStatus.requested ||
      status == TripStatus.matching ||
      status == TripStatus.assigned ||
      status == TripStatus.arriving;

  bool get wasNoDriver =>
      status == TripStatus.cancelled &&
      (cancelReason == 'no_driver' ||
          (cancelReason?.startsWith('no_driver') ?? false));

  LatLng? get pickupPoint =>
      pickupLat == null || pickupLng == null
          ? null
          : LatLng(pickupLat!, pickupLng!);

  LatLng? get dropoffPoint =>
      dropoffLat == null || dropoffLng == null
          ? null
          : LatLng(dropoffLat!, dropoffLng!);

  RideTrip copyWith({
    TripStatus? status,
    String? driverId,
    int? passengerRating,
    DateTime? completedAt,
    int? etaMinutes,
    DateTime? offerExpiresAt,
    String? cancelReason,
    bool clearOfferExpiresAt = false,
  }) {
    return RideTrip(
      id: id,
      passengerId: passengerId,
      pickupId: pickupId,
      dropoffId: dropoffId,
      fareEtb: fareEtb,
      vehicleClass: vehicleClass,
      status: status ?? this.status,
      createdAt: createdAt,
      driverId: driverId ?? this.driverId,
      passengerRating: passengerRating ?? this.passengerRating,
      completedAt: completedAt ?? this.completedAt,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      offerExpiresAt:
          clearOfferExpiresAt ? null : (offerExpiresAt ?? this.offerExpiresAt),
      cancelReason: cancelReason ?? this.cancelReason,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      distanceKm: distanceKm,
    );
  }
}

class DriverEarningsToday {
  const DriverEarningsToday({
    required this.totalEtb,
    required this.trips,
  });

  final int totalEtb;
  final List<RideTrip> trips;
}

/// Addis Ababa service area used for Ride geofencing.
bool isInRideServiceArea(LatLng point) {
  return point.latitude >= 8.83 &&
      point.latitude <= 9.15 &&
      point.longitude >= 38.62 &&
      point.longitude <= 39.0;
}

class DriverSession {
  const DriverSession({
    required this.driverId,
    required this.isOnline,
    required this.isApproved,
  });

  final String driverId;
  final bool isOnline;
  final bool isApproved;

  DriverSession copyWith({bool? isOnline, bool? isApproved}) {
    return DriverSession(
      driverId: driverId,
      isOnline: isOnline ?? this.isOnline,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

extension TripStatusLabel on TripStatus {
  String get label {
    switch (this) {
      case TripStatus.quoting:
        return 'Quote';
      case TripStatus.requested:
        return 'Requested';
      case TripStatus.matching:
        return 'Finding driver';
      case TripStatus.assigned:
        return 'Driver assigned';
      case TripStatus.arriving:
        return 'Driver arriving';
      case TripStatus.arrived:
        return 'Driver arrived';
      case TripStatus.inProgress:
        return 'On trip';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Rough Addis center used when no places are selected yet.
const LatLng kAddisCenter = LatLng(9.03, 38.75);
