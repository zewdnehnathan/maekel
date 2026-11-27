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
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

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
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .rideReported(reason.replaceAll('_', ' ')),
          ),
        ),
      );
      await _loadEarnings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _reportMisconduct(RideTrip trip) async {
    const reasons = <String, String>{
      'harassment': 'Harassment',
      'rude_behavior': 'Rude behavior',
      'other': 'Other',
    };
    String selected = 'harassment';
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: MaekelColors.panel,
              title: const Text('Report passenger safety / misconduct'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: selected,
                    items: [
                      for (final e in reasons.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (v) {
                      if (v != null) setLocal(() => selected = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Details (optional)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) return;
    try {
      await ref.read(rideRepositoryProvider).reportMisconduct(
            tripId: trip.id,
            reason: selected,
            note: noteController.text.trim().isEmpty
                ? null
                : noteController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report sent to Ride ops')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  String _offerCountdown(RideTrip trip) {
    final l10n = AppLocalizations.of(context)!;
    final expires = trip.offerExpiresAt;
    if (expires == null) return l10n.rideAcceptSoon;
    final secs = expires.difference(DateTime.now()).inSeconds;
    if (secs <= 0) return l10n.rideExpired;
    return l10n.rideSecsLeft(secs);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(rideUserIdProvider);
    final session = ref.watch(rideDriverSessionProvider);
    final active = ref.watch(rideDriverActiveTripProvider);
    final repo = ref.watch(rideRepositoryProvider);

    if (userId == null || session == null) {
      return RideShell(
        title: AppLocalizations.of(context)!.rideDriveTitle,
        child: Center(child: Text(AppLocalizations.of(context)!.signInRequired)),
      );
    }

    final offers = repo.getOpenOffersForDriver(session.driverId);

    final l10n = AppLocalizations.of(context)!;

    return RideShell(
      title: l10n.rideDriveTitle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GlassPanel(
            accent: MaekelColors.ride,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rideDriverMode,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  session.isApproved
                      ? l10n.rideGoOnlineHint
                      : l10n.ridePendingApproval,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(session.isOnline ? l10n.online : l10n.offline),
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
                    l10n.ridePendingApproval,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MaekelColors.amber,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.rideTodaysEarnings.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rideFareEtb(_earnings?.totalEtb ?? 0),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: MaekelColors.signal,
                      ),
                ),
                Text(
                  _loadingEarnings
                      ? l10n.rideRefreshing
                      : l10n.rideCompletedTripsToday(
                          _earnings?.trips.length ?? 0,
                        ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_earnings != null && _earnings!.trips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final trip in _earnings!.trips.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${localizedPlace(l10n, repo.getPlace(trip.pickupId)?.name ?? trip.pickupId)}'
                        ' → ${localizedPlace(l10n, repo.getPlace(trip.dropoffId)?.name ?? trip.dropoffId)}'
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
            Text(
              l10n.rideActiveJob,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(active.status.localized(AppLocalizations.of(context)!)),
                  Text(
                    l10n.rideRouteArrow(
                      localizedPlace(
                        l10n,
                        repo.getPlace(active.pickupId)?.name ?? active.pickupId,
                      ),
                      localizedPlace(
                        l10n,
                        repo.getPlace(active.dropoffId)?.name ??
                            active.dropoffId,
                      ),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .rideFareDueCash(active.fareEtb),
                  ),
                  const SizedBox(height: 12),
                  if (active.status == TripStatus.inProgress)
                    FilledButton(
                      onPressed: () async {
                        await ref
                            .read(rideRepositoryProvider)
                            .confirmCash(active.id);
                        await _loadEarnings();
                      },
                      child: Text(AppLocalizations.of(context)!.rideCompleteCash),
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
                          TripStatus.assigned =>
                            AppLocalizations.of(context)!.rideStartArriving,
                          TripStatus.arriving =>
                            AppLocalizations.of(context)!.rideMarkArrived,
                          TripStatus.arrived =>
                            AppLocalizations.of(context)!.rideStartTrip,
                          _ => AppLocalizations.of(context)!.rideAdvance,
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.rideReportProblem.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _report(active, 'no_show'),
                        child: Text(AppLocalizations.of(context)!.ridePassengerNoShow),
                      ),
                      OutlinedButton(
                        onPressed: () => _report(active, 'wrong_pin'),
                        child: Text(AppLocalizations.of(context)!.rideWrongPin),
                      ),
                      if (active.status == TripStatus.inProgress ||
                          active.status == TripStatus.completed ||
                          active.status == TripStatus.cancelled)
                        OutlinedButton.icon(
                          onPressed: () => _reportMisconduct(active),
                          icon: const Icon(Icons.report_gmailerrorred_outlined),
                          label: const Text('Report safety'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              AppLocalizations.of(context)!.rideOffers,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            if (!session.isOnline)
              Text(AppLocalizations.of(context)!.rideGoOnlineHint)
            else if (offers.isEmpty)
              Text(l10n.rideNoOffers)
            else
              ...offers.map((trip) {
                final pickup = repo.getPlace(trip.pickupId);
                final dropoff = repo.getPlace(trip.dropoffId);
                final countdown = _offerCountdown(trip);
                final expired = countdown == l10n.rideExpired;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${localizedPlace(l10n, pickup?.name ?? trip.pickupId)} → ${localizedPlace(l10n, dropoff?.name ?? trip.dropoffId)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${trip.fareEtb} ETB · ${trip.status.localized(AppLocalizations.of(context)!)} · $countdown',
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
                          child: Text(AppLocalizations.of(context)!.accept),
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
