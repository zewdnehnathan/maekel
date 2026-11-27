import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
// Distance is provided by latlong2.

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ride_models.dart';

class RideMap extends StatefulWidget {
  const RideMap({
    super.key,
    this.pickupPoint,
    this.dropoffPoint,
    this.driverPoint,
    this.myLocation,
    this.onMapTap,
    this.height = 260,
    this.interactive = true,
  });

  final LatLng? pickupPoint;
  final LatLng? dropoffPoint;
  final LatLng? driverPoint;
  final LatLng? myLocation;
  final ValueChanged<LatLng>? onMapTap;
  final double height;
  final bool interactive;

  @override
  State<RideMap> createState() => _RideMapState();
}

class _RideMapState extends State<RideMap> {
  static const double _minZoom = 11;
  static const double _maxZoom = 18;

  final MapController _mapController = MapController();
  bool _mapReady = false;

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final next = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, next);
  }

  void _handleSelect(LatLng point) {
    widget.onMapTap?.call(point);
    // Nudge in so the pin is easier to refine on emulator.
    final zoom = _mapController.camera.zoom;
    if (zoom < 15.5) {
      _mapController.move(point, (zoom + 1.2).clamp(_minZoom, _maxZoom));
    } else {
      _mapController.move(point, zoom);
    }
  }

  void _recenterOnFocus({bool force = false}) {
    if (!_mapReady) return;
    final focus = widget.myLocation ?? widget.pickupPoint;
    if (focus == null) return;
    final camera = _mapController.camera;
    final moved = const Distance().as(
          LengthUnit.Meter,
          camera.center,
          focus,
        ) >
        40;
    if (force || moved) {
      _mapController.move(focus, camera.zoom < 14 ? 14.2 : camera.zoom);
    }
  }

  @override
  void didUpdateWidget(covariant RideMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFocus = oldWidget.myLocation ?? oldWidget.pickupPoint;
    final newFocus = widget.myLocation ?? widget.pickupPoint;
    if (newFocus == null) return;
    if (oldFocus == null ||
        oldFocus.latitude != newFocus.latitude ||
        oldFocus.longitude != newFocus.longitude) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recenterOnFocus(force: true);
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickupPoint = widget.pickupPoint;
    final dropoffPoint = widget.dropoffPoint;
    final driverPoint = widget.driverPoint;
    final myLocation = widget.myLocation;
    final onMapTap = widget.onMapTap;
    final interactive = widget.interactive;

    final center = myLocation ??
        pickupPoint ??
        dropoffPoint ??
        kAddisCenter;

    final markers = <Marker>[
      if (pickupPoint != null)
        Marker(
          point: pickupPoint,
          width: 48,
          height: 56,
          child: const _EndpointPin(
            label: 'P',
            color: MaekelColors.signal,
          ),
        ),
      if (dropoffPoint != null)
        Marker(
          point: dropoffPoint,
          width: 48,
          height: 56,
          child: const _EndpointPin(
            label: 'D',
            color: MaekelColors.amber,
          ),
        ),
      if (myLocation != null &&
          (pickupPoint == null ||
              myLocation.latitude != pickupPoint.latitude ||
              myLocation.longitude != pickupPoint.longitude))
        Marker(
          point: myLocation,
          width: 40,
          height: 40,
          child: const _MyLocationDot(),
        ),
      if (driverPoint != null)
        Marker(
          point: driverPoint,
          width: 48,
          height: 48,
          child: const _DriverPin(),
        ),
    ];

    final polyline = <LatLng>[
      if (pickupPoint != null) pickupPoint,
      if (driverPoint != null && pickupPoint != null && dropoffPoint == null) ...[
        driverPoint,
        pickupPoint,
      ],
      if (pickupPoint != null && dropoffPoint != null) ...[
        if (driverPoint != null) driverPoint,
        pickupPoint,
        dropoffPoint,
      ],
    ];

    // Keep pan/zoom, but disable double-tap zoom so taps can set points.
    // Emulator mouse: +/− buttons, mouse wheel, or pinch with Ctrl+drag.
    const selectFlags = InteractiveFlag.drag |
        InteractiveFlag.flingAnimation |
        InteractiveFlag.pinchZoom |
        InteractiveFlag.pinchMove |
        InteractiveFlag.scrollWheelZoom;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: myLocation != null ? 14.2 : 12.4,
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                interactionOptions: InteractionOptions(
                  flags: interactive ? selectFlags : InteractiveFlag.none,
                  enableMultiFingerGestureRace: false,
                ),
                onMapReady: () {
                  _mapReady = true;
                  _recenterOnFocus(force: true);
                },
                onTap: onMapTap == null || !interactive
                    ? null
                    : (tap, point) => _handleSelect(point),
                onLongPress: onMapTap == null || !interactive
                    ? null
                    : (tap, point) => _handleSelect(point),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'et.maekel.maekel',
                ),
                if (polyline.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: polyline,
                        color: MaekelColors.ride.withValues(alpha: 0.85),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
            if (interactive)
              Positioned(
                right: 10,
                top: 10,
                child: Column(
                  children: [
                    _ZoomButton(
                      icon: Icons.add,
                      onPressed: () => _zoomBy(1),
                    ),
                    const SizedBox(height: 6),
                    _ZoomButton(
                      icon: Icons.remove,
                      onPressed: () => _zoomBy(-1),
                    ),
                  ],
                ),
              ),
            if (onMapTap != null && interactive)
              Positioned(
                left: 10,
                bottom: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: MaekelColors.voidBlack.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: MaekelColors.glassBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Text(
                      AppLocalizations.of(context)!.rideMapHint,
                      style: const TextStyle(
                        color: MaekelColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MaekelColors.voidBlack.withValues(alpha: 0.78),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: MaekelColors.glassBorder),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: MaekelColors.ink),
        ),
      ),
    );
  }
}

class _EndpointPin extends StatelessWidget {
  const _EndpointPin({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 36),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: MaekelColors.signal,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: MaekelColors.signal.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _DriverPin extends StatelessWidget {
  const _DriverPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MaekelColors.panel,
        shape: BoxShape.circle,
        border: Border.all(color: MaekelColors.ride, width: 2),
        boxShadow: [
          BoxShadow(
            color: MaekelColors.ride.withValues(alpha: 0.35),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Icon(Icons.local_taxi_rounded, color: MaekelColors.ride),
    );
  }
}

/// Interpolates a mock driver position from nearby → pickup → dropoff by status.
LatLng? estimateDriverPoint({
  required TripStatus status,
  required RidePlace? pickup,
  required RidePlace? dropoff,
  RideDriver? driver,
}) {
  if (pickup == null) return driver?.point;
  final start =
      driver?.point ?? LatLng(pickup.lat + 0.012, pickup.lng - 0.01);

  switch (status) {
    case TripStatus.requested:
    case TripStatus.matching:
      return start;
    case TripStatus.assigned:
      return _lerp(start, pickup.point, 0.35);
    case TripStatus.arriving:
      return _lerp(start, pickup.point, 0.7);
    case TripStatus.arrived:
      return pickup.point;
    case TripStatus.inProgress:
      if (dropoff == null) return pickup.point;
      return _lerp(pickup.point, dropoff.point, 0.45);
    case TripStatus.completed:
      return dropoff?.point ?? pickup.point;
    case TripStatus.cancelled:
    case TripStatus.quoting:
      return null;
  }
}

LatLng _lerp(LatLng a, LatLng b, double t) {
  return LatLng(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t,
  );
}
