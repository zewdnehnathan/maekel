import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/ride_shell.dart';
import '../models/ride_models.dart';
import '../providers/ride_providers.dart';

class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(rideHistoryProvider);
    final repo = ref.watch(rideRepositoryProvider);

    return RideShell(
      title: 'Trips',
      child: trips.isEmpty
          ? const Center(child: Text('No trips yet.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final trip = trips[index];
                final pickup = repo.getPlace(trip.pickupId);
                final dropoff = repo.getPlace(trip.dropoffId);
                return InkWell(
                  onTap: () => context.push('${AppRoutes.rideTrips}/${trip.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: GlassPanel(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${pickup?.name ?? '?'} → ${dropoff?.name ?? '?'}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              trip.status.label,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${trip.fareEtb} ETB cash · ${trip.vehicleClass}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
