import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/ride_map.dart';
import '../components/ride_shell.dart';
import '../models/ride_models.dart';
import '../providers/ride_providers.dart';

class RideTripScreen extends ConsumerStatefulWidget {
  const RideTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<RideTripScreen> createState() => _RideTripScreenState();
}

class _RideTripScreenState extends ConsumerState<RideTripScreen> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(rideTripProvider(widget.tripId));
    final repo = ref.watch(rideRepositoryProvider);

    if (trip == null) {
      return const RideShell(
        title: 'Trip',
        showBottomNav: false,
        child: Center(child: Text('Trip not found')),
      );
    }

    final pickup = repo.getPlace(trip.pickupId);
    final dropoff = repo.getPlace(trip.dropoffId);
    final driver =
        trip.driverId == null ? null : repo.getDriver(trip.driverId!);
    final driverPoint = estimateDriverPoint(
      status: trip.status,
      pickup: pickup,
      dropoff: dropoff,
      driver: driver,
    );

    return RideShell(
      title: 'Trip',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          RideMap(
            pickupPoint: pickup?.point,
            dropoffPoint: dropoff?.point,
            driverPoint: driverPoint,
            height: 300,
          ),
          const SizedBox(height: 14),
          GlassPanel(
            accent: MaekelColors.ride,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.status.label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${trip.fareEtb} ETB · ${trip.vehicleClass}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 32,
                        color: MaekelColors.signal,
                      ),
                ),
                const SizedBox(height: 8),
                Text('From: ${pickup?.name ?? trip.pickupId}'),
                Text('To: ${dropoff?.name ?? trip.dropoffId}'),
                const SizedBox(height: 8),
                Text(
                  'Pay cash at complete — fare locked at request.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (driver != null) ...[
            const SizedBox(height: 14),
            GlassPanel(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: MaekelColors.ride.withValues(alpha: 0.2),
                    child: Text(
                      driver.photoHint,
                      style: const TextStyle(color: MaekelColors.ride),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${driver.carModel} · ${driver.plate} · ★ ${driver.rating}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (trip.canCancel)
            OutlinedButton(
              onPressed: () async {
                try {
                  await ref.read(rideRepositoryProvider).cancelTrip(trip.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              child: const Text('CANCEL TRIP'),
            ),
          if (trip.status == TripStatus.completed &&
              trip.passengerRating == null) ...[
            const SizedBox(height: 16),
            Text(
              'Rate your driver',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _rating.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_rating',
              activeColor: MaekelColors.amber,
              onChanged: (v) => setState(() => _rating = v.round()),
            ),
            FilledButton(
              onPressed: () {
                ref.read(rideRepositoryProvider).rateTrip(trip.id, _rating);
              },
              child: const Text('SUBMIT RATING'),
            ),
          ],
          if (trip.passengerRating != null) ...[
            const SizedBox(height: 12),
            Text('You rated ${trip.passengerRating}★'),
          ],
        ],
      ),
    );
  }
}
