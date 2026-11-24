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

Future<LatLng> getDeviceLatLng() async {
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

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 12),
    ),
  );
  return LatLng(pos.latitude, pos.longitude);
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