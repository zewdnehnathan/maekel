import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/location/device_location.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/ride_map.dart';
import '../components/ride_shell.dart';
import '../models/ride_models.dart';
import '../providers/ride_providers.dart';

class RideScreen extends ConsumerStatefulWidget {
  const RideScreen({super.key});

  @override
  ConsumerState<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends ConsumerState<RideScreen> {
  LatLng? _pickupPoint;
  LatLng? _dropoffPoint;
  String? _pickupId;
  String? _dropoffId;
  FareQuote? _quote;
  bool _quoting = false;
  bool _requesting = false;
  bool _pickingPickup = false;
  bool _locating = false;
  bool _usingGpsPickup = true;
  LatLng? _myLocation;
  String? _locationNote;
  bool _didAutoLocate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapLocation());
  }

  Future<void> _bootstrapLocation() async {
    final places = ref.read(ridePlacesProvider);
    if (places.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || _didAutoLocate) return;
      final again = ref.read(ridePlacesProvider);
      if (again.isEmpty) return;
      await _useMyLocation(again);
      return;
    }
    await _useMyLocation(places);
  }

  Future<void> _useMyLocation(List<RidePlace> places) async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationNote = null;
    });
    try {
      final point = await getDeviceLatLng();
      if (!mounted) return;
      final nearest = nearestPlace(point, places);
      setState(() {
        _myLocation = point;
        _pickupPoint = point;
        _pickupId = nearest.id;
        _usingGpsPickup = true;
        _pickingPickup = false;
        _quote = null;
        _didAutoLocate = true;
        _locationNote = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _usingGpsPickup = false;
        _pickingPickup = true;
        _locationNote = e.toString();
        _didAutoLocate = true;
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onMapTap(LatLng point, List<RidePlace> places) {
    setState(() {
      if (_pickingPickup || _pickupPoint == null) {
        _pickupPoint = point;
        _pickupId = places.isEmpty ? null : nearestPlace(point, places).id;
        _usingGpsPickup = false;
        _pickingPickup = false;
        _locationNote = places.isEmpty
            ? 'Map pin set — waiting for places from API'
            : null;
        if (_dropoffId != null && _dropoffId == _pickupId) {
          _dropoffPoint = null;
          _dropoffId = null;
        }
      } else {
        _dropoffPoint = point;
        if (places.isEmpty) {
          _dropoffId = null;
          _locationNote = 'Map pin set — waiting for places from API';
        } else {
          _dropoffId = nearestPlace(point, places).id;
          _locationNote = null;
          // Prefer a different hub ID when pin is far from pickup but same nearest.
          if (_dropoffId == _pickupId &&
              _pickupPoint != null &&
              const Distance().as(LengthUnit.Meter, _pickupPoint!, point) > 80) {
            final others = places.where((p) => p.id != _pickupId).toList();
            if (others.isNotEmpty) {
              _dropoffId = nearestPlace(point, others).id;
            }
          }
        }
      }
      _quote = null;
    });
  }

  String _fmt(LatLng p) =>
      '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(ridePlacesProvider);
    final active = ref.watch(rideActiveTripProvider);

    ref.listen(ridePlacesProvider, (prev, next) {
      if (!_didAutoLocate && next.isNotEmpty) {
        _useMyLocation(next);
      }
    });

    return RideShell(
      title: 'Ride',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Go across Addis',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            active != null
                ? 'Finish or open the active trip to pick a new dropoff'
                : _pickingPickup
                    ? 'Single-click or long-press the map to set pickup'
                    : 'Single-click or long-press the map to set dropoff',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: active != null
                      ? MaekelColors.muted
                      : _pickingPickup
                          ? MaekelColors.signal
                          : MaekelColors.amber,
                ),
          ),
          if (active != null) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () => context.go('${AppRoutes.rideTrips}/${active.id}'),
              borderRadius: BorderRadius.circular(16),
              child: GlassPanel(
                accent: MaekelColors.amber,
                child: Row(
                  children: [
                    const Icon(
                      Icons.navigation_rounded,
                      color: MaekelColors.amber,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Active trip · ${active.status.label}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          RideMap(
            pickupPoint: _pickupPoint,
            dropoffPoint: _dropoffPoint,
            myLocation: _myLocation,
            onMapTap: active == null ? (p) => _onMapTap(p, places) : null,
            height: 280,
          ),
          const SizedBox(height: 10),
          if (_locating)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_locationNote != null) ...[
            Text(
              _locationNote!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MaekelColors.amber,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Set pickup'),
                selected: _pickingPickup,
                onSelected: (_) => setState(() => _pickingPickup = true),
              ),
              ChoiceChip(
                label: const Text('Set dropoff'),
                selected: !_pickingPickup,
                onSelected: (_) => setState(() => _pickingPickup = false),
              ),
              ActionChip(
                avatar: const Icon(Icons.my_location_rounded, size: 16),
                label: const Text('Use my location'),
                onPressed: places.isEmpty || active != null
                    ? null
                    : () => _useMyLocation(places),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassPanel(
            accent: MaekelColors.ride,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CoordRow(
                  label: _usingGpsPickup ? 'PICKUP · YOU' : 'PICKUP',
                  value: _pickupPoint == null
                      ? 'Waiting for location…'
                      : _fmt(_pickupPoint!),
                  accent: MaekelColors.signal,
                ),
                const SizedBox(height: 14),
                _CoordRow(
                  label: 'DROPOFF',
                  value: _dropoffPoint == null
                      ? 'Tap the map once to set'
                      : _fmt(_dropoffPoint!),
                  accent: MaekelColors.amber,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _quoting ||
                          _pickupId == null ||
                          _dropoffId == null ||
                          active != null
                      ? null
                      : _getQuote,
                  child: _quoting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('GET UPFRONT QUOTE'),
                ),
              ],
            ),
          ),
          if (_quote != null) ...[
            const SizedBox(height: 16),
            GlassPanel(
              accent: MaekelColors.amber,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ECONOMY',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_quote!.totalEtb} ETB',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: MaekelColors.signal,
                          fontSize: 40,
                        ),
                  ),
                  Text(
                    'Binding quote · ETA ${_quote!.etaMinutes} min to pickup',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _requesting || active != null ? null : _request,
                    child: _requesting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('REQUEST RIDE'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _getQuote() async {
    setState(() => _quoting = true);
    try {
      final quote = await ref.read(rideRepositoryProvider).getQuote(
            pickupId: _pickupId!,
            dropoffId: _dropoffId!,
          );
      if (mounted) setState(() => _quote = quote);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  Future<void> _request() async {
    final userId = ref.read(rideUserIdProvider);
    final quote = _quote;
    if (userId == null || quote == null) return;
    setState(() => _requesting = true);
    try {
      final trip = await ref.read(rideRepositoryProvider).requestTrip(
            passengerId: userId,
            quote: quote,
          );
      if (mounted) context.go('${AppRoutes.rideTrips}/${trip.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }
}

class _CoordRow extends StatelessWidget {
  const _CoordRow({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: accent,
                fontSize: 11,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: 0.4,
              ),
        ),
      ],
    );
  }
}
