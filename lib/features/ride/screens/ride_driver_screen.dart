import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/ride_shell.dart';
import '../models/ride_models.dart';
import '../providers/ride_providers.dart';

class RideDriverScreen extends ConsumerWidget {
  const RideDriverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      ? 'Docs approved (mock). Go online to receive jobs.'
                      : 'Awaiting ops approval',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(session.isOnline ? 'Online' : 'Offline'),
                  value: session.isOnline,
                  activeThumbColor: MaekelColors.ride,
                  onChanged: session.isApproved
                      ? (v) {
                          ref
                              .read(rideRepositoryProvider)
                              .setDriverOnline(userId, v);
                        }
                      : null,
                ),
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
                  Text('Fare due: ${active.fareEtb} ETB cash'),
                  const SizedBox(height: 12),
                  if (active.status == TripStatus.inProgress)
                    FilledButton(
                      onPressed: () {
                        ref.read(rideRepositoryProvider).confirmCash(active.id);
                      },
                      child: const Text('COMPLETE + CONFIRM CASH'),
                    )
                  else if (active.status != TripStatus.completed)
                    FilledButton(
                      onPressed: () {
                        ref.read(rideRepositoryProvider).driverAdvance(active.id);
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
                ],
              ),
            ),
          ] else ...[
            Text('OFFERS', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            if (!session.isOnline)
              const Text('Go online to see matching requests.')
            else if (offers.isEmpty)
              const Text('No open offers right now. Request a ride as passenger to demo.')
            else
              ...offers.map((trip) {
                final pickup = repo.getPlace(trip.pickupId);
                final dropoff = repo.getPlace(trip.dropoffId);
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
                        Text('${trip.fareEtb} ETB · ${trip.status.label}'),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () {
                            ref.read(rideRepositoryProvider).acceptOffer(
                                  trip.id,
                                  session.driverId,
                                );
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
