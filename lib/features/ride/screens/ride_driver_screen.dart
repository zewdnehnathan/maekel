import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/location/device_location.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/ride_shell.dart';
import '../models/ride_models.dart';
import '../providers/ride_providers.dart';
import '../services/api_ride_repository.dart';

class RideDriverScreen extends ConsumerStatefulWidget {
  const RideDriverScreen({super.key});

  @override
  ConsumerState<RideDriverScreen> createState() => _RideDriverScreenState();
}

class _RideDriverScreenState extends ConsumerState<RideDriverScreen> {
  DriverEarningsToday? _earnings;
  bool _loadingEarnings = false;
  Timer? _tick;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEarnings();
      _syncLocationPublishing();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  void _syncLocationPublishing() {
    final session = ref.read(rideDriverSessionProvider);
    _locationTimer?.cancel();
    if (session == null || !session.isOnline) return;
    unawaited(_publishLocation());
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_publishLocation());
    });
  }

  Future<void> _publishLocation() async {
    final repo = ref.read(rideRepositoryProvider);
    if (repo is! ApiRideRepository) return;
    try {
      final point = await getDeviceLatLng();
      await repo.postDriverLocation(lat: point.latitude, lng: point.longitude);
    } catch (_) {
      // Location optional on emulators without GPS.
    }
  }

  Future<void> _loadEarnings() async {
    final session = ref.read(rideDriverSessionProvider);
    if (session == null) return;
    setState(() => _loadingEarnings = true);
    try {
      final earnings = await ref
          .read(rideRepositoryProvider)
          .getDriverEarningsToday(session.driverId);
      if (mounted) setState(() => _earnings = earnings);
    } catch (_) {
      // Keep prior earnings if refresh fails.
    } finally {
      if (mounted) setState(() => _loadingEarnings = false);
    }
  }

  Future<void> _report(RideTrip trip, String reason) async {
    try {
      await ref.read(rideRepositoryProvider).reportTripProblem(
            tripId: trip.id,
            reason: reason,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reported: ${reason.replaceAll('_', ' ')}')),
      );
      await _loadEarnings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  String _offerCountdown(RideTrip trip) {
    final expires = trip.offerExpiresAt;
    if (expires == null) return 'Accept soon';
    final secs = expires.difference(DateTime.now()).inSeconds;
    if (secs <= 0) return 'Expired';
    return '${secs}s left';
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(rideUserIdProvider);
    final session = ref.watch(rideDriverSessionProvider);
    final active = ref.watch(rideDriverActiveTripProvider);
    final repo = ref.watch(rideRepositoryProvider);

    if (userId == null || session == null) {
      return const RideShell(
        title: 'Drive',
        child: Center(child: Text('Sign in required')),
      );
    }

    final offers = repo.getOpenOffersForDriver(session.driverId);

    return RideShell(
      title: 'Drive',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GlassPanel(
            accent: MaekelColors.ride,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver mode',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  session.isApproved
                      ? 'Go online to receive trip offers.'
                      : 'Awaiting ops approval — cannot go online yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(session.isOnline ? 'Online' : 'Offline'),
                  value: session.isOnline,
                  activeThumbColor: MaekelColors.ride,
                  onChanged: session.isApproved
                      ? (v) async {
                          try {
                            await ref
                                .read(rideRepositoryProvider)
                                .setDriverOnline(userId, v);
                            _syncLocationPublishing();
                            await _loadEarnings();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        }
                      : null,
                ),
                if (!session.isApproved)
                  Text(
                    'Pending Ride ops approval before you can go online.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MaekelColors.amber,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text("TODAY'S EARNINGS", style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_earnings?.totalEtb ?? 0} ETB',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: MaekelColors.signal,
                      ),
                ),
                Text(
                  _loadingEarnings
                      ? 'Refreshing…'
                      : '${_earnings?.trips.length ?? 0} completed trip(s) today',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_earnings != null && _earnings!.trips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final trip in _earnings!.trips.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${repo.getPlace(trip.pickupId)?.name ?? trip.pickupId}'
                        ' → ${repo.getPlace(trip.dropoffId)?.name ?? trip.dropoffId}'
                        ' · ${trip.fareEtb} ETB',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (active != null) ...[
            Text('ACTIVE JOB', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(active.status.label),
                  Text(
                    '${repo.getPlace(active.pickupId)?.name ?? active.pickupId}'
                    ' → ${repo.getPlace(active.dropoffId)?.name ?? active.dropoffId}',
                  ),
                  Text('Fare due: ${active.fareEtb} ETB cash'),
                  const SizedBox(height: 12),
                  if (active.status == TripStatus.inProgress)
                    FilledButton(
                      onPressed: () async {
                        await ref
                            .read(rideRepositoryProvider)
                            .confirmCash(active.id);
                        await _loadEarnings();
                      },
                      child: const Text('COMPLETE + CONFIRM CASH'),
                    )
                  else if (active.status != TripStatus.completed)
                    FilledButton(
                      onPressed: () {
                        ref
                            .read(rideRepositoryProvider)
                            .driverAdvance(active.id);
                      },
                      child: Text(
                        switch (active.status) {
                          TripStatus.assigned => 'START ARRIVING',
                          TripStatus.arriving => 'MARK ARRIVED',
                          TripStatus.arrived => 'START TRIP',
                          _ => 'ADVANCE',
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    'REPORT A PROBLEM',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _report(active, 'no_show'),
                        child: const Text('Passenger no-show'),
                      ),
                      OutlinedButton(
                        onPressed: () => _report(active, 'wrong_pin'),
                        child: const Text('Wrong pin'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Text('OFFERS', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            if (!session.isOnline)
              const Text('Go online to see matching requests.')
            else if (offers.isEmpty)
              const Text(
                'No open offers right now. When a passenger requests nearby, the offer appears here with a time limit.',
              )
            else
              ...offers.map((trip) {
                final pickup = repo.getPlace(trip.pickupId);
                final dropoff = repo.getPlace(trip.dropoffId);
                final countdown = _offerCountdown(trip);
                final expired = countdown == 'Expired';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pickup?.name} → ${dropoff?.name}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${trip.fareEtb} ETB · ${trip.status.label} · $countdown',
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: expired
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(rideRepositoryProvider)
                                        .acceptOffer(
                                          trip.id,
                                          session.driverId,
                                        );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                },
                          child: const Text('ACCEPT'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}
