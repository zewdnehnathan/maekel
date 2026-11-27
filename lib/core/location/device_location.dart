import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../features/ride/models/ride_models.dart';

enum DeviceLocationCode {
  turnOn,
  denied,
  blocked,
  noPickupPlaces,
}

class DeviceLocationException implements Exception {
  DeviceLocationException(this.code);

  final DeviceLocationCode code;

  @override
  String toString() => code.name;
}

LocationSettings _freshLocationSettings({Duration? timeLimit}) {
  // Browsers often return a cached “last known” fix (e.g. an old home).
  // Force a fresh reading wherever the platform API allows it.
  final limit = timeLimit ?? const Duration(seconds: 15);
  if (kIsWeb) {
    return WebSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      maximumAge: Duration.zero,
      timeLimit: limit,
    );
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: false,
        timeLimit: limit,
      );
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.other,
        distanceFilter: 0,
        timeLimit: limit,
      );
    default:
      return LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        timeLimit: limit,
      );
  }
}

/// Current device position. Prefers a fresh GPS fix over cached last-known.
Future<LatLng> getDeviceLatLng({bool forceFresh = true}) async {
  final serviceOn = await Geolocator.isLocationServiceEnabled();
  if (!serviceOn) {
    throw DeviceLocationException(DeviceLocationCode.turnOn);
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw DeviceLocationException(DeviceLocationCode.denied);
  }
  if (permission == LocationPermission.deniedForever) {
    throw DeviceLocationException(DeviceLocationCode.blocked);
  }

  // On web, getCurrentPosition / lastKnown frequently return a stale home
  // fix with a “fresh” timestamp. Prefer a short watchPosition sample.
  if (kIsWeb || forceFresh) {
    final streamed = await _bestFreshFixFromStream();
    if (streamed != null) {
      return LatLng(streamed.latitude, streamed.longitude);
    }
  }

  Position? pos;
  try {
    pos = await Geolocator.getCurrentPosition(
      locationSettings: _freshLocationSettings(),
    );
  } catch (_) {
    pos = null;
  }

  if (pos != null && !(forceFresh && _isStale(pos))) {
    return LatLng(pos.latitude, pos.longitude);
  }

  // Native-only fallback: last-known if reasonably fresh.
  // Never use last-known on web — that is what pinned the old residence.
  if (!kIsWeb) {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null && !_isStale(last, maxAge: const Duration(minutes: 2))) {
      return LatLng(last.latitude, last.longitude);
    }
    if (pos != null) {
      return LatLng(pos.latitude, pos.longitude);
    }
  }

  throw DeviceLocationException(DeviceLocationCode.turnOn);
}

Future<Position?> _bestFreshFixFromStream() async {
  try {
    final settings = _freshLocationSettings(
      timeLimit: const Duration(seconds: 12),
    );
    final samples = <Position>[];
    await for (final p in Geolocator.getPositionStream(
      locationSettings: settings,
    ).timeout(const Duration(seconds: 12))) {
      samples.add(p);
      // Good enough GPS / Wi‑Fi fix — stop early.
      if (samples.isNotEmpty && p.accuracy > 0 && p.accuracy <= 80) {
        break;
      }
      if (samples.length >= 3) break;
    }
    if (samples.isEmpty) return null;
    samples.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    final best = samples.first;
    if (_isStale(best) && best.accuracy > 250) return null;
    return best;
  } catch (_) {
    return null;
  }
}

bool _isStale(
  Position pos, {
  Duration maxAge = const Duration(seconds: 45),
}) {
  final age = DateTime.now().difference(pos.timestamp);
  if (age > maxAge) return true;
  // Very coarse accuracy often means IP / cell guess, not device GPS.
  if (pos.accuracy > 500) return true;
  return false;
}

RidePlace nearestPlace(LatLng point, List<RidePlace> places) {
  if (places.isEmpty) {
    throw DeviceLocationException(DeviceLocationCode.noPickupPlaces);
  }
  const distance = Distance();
  RidePlace best = places.first;
  var bestMeters = distance(point, best.point);
  for (final place in places.skip(1)) {
    final meters = distance(point, place.point);
    if (meters < bestMeters) {
      best = place;
      bestMeters = meters;
    }
  }
  return best;
}
