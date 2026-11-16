import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../features/ride/models/ride_models.dart';

class DeviceLocationException implements Exception {
  DeviceLocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

Future<LatLng> getDeviceLatLng() async {
  final serviceOn = await Geolocator.isLocationServiceEnabled();
  if (!serviceOn) {
    throw DeviceLocationException('Turn on location services to use pickup.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw DeviceLocationException('Location permission denied.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw DeviceLocationException(
      'Location permission is blocked. Enable it in system settings.',
    );
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
    throw DeviceLocationException('No pickup places available.');
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
