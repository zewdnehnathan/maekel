import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/ride_shell.dart';
import '../models/ride_models.dart';
import '../providers/ride_providers.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(rideHistoryProvider);
    final repo = ref.watch(rideRepositoryProvider);

    return RideShell(
      title: AppLocalizations.of(context)!.rideTripsTitle,
      child: trips.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.rideNoTripsYet))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final trip = trips[index];
                final pickup = repo.getPlace(trip.pickupId);
                final dropoff = repo.getPlace(trip.dropoffId);
                final driver = trip.driverId == null
                    ? null
                    : repo.getDriver(trip.driverId!);
                final when = trip.completedAt ?? trip.createdAt;
                final whenLabel =
                    '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}'
                    ' ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
                final l10n = AppLocalizations.of(context)!;
                final vehicleLabel = localizedVehicleClass(l10n, trip.vehicleClass);
                final pickupLabel = localizedPlace(
                  l10n,
                  pickup?.name ?? '?',
                );
                final dropoffLabel = localizedPlace(
                  l10n,
                  dropoff?.name ?? '?',
                );
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
                                '$pickupLabel → $dropoffLabel',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              trip.status.localized(AppLocalizations.of(context)!),
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.rideCashVehicle(trip.fareEtb, vehicleLabel),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          driver == null
                              ? whenLabel
                              : '$whenLabel · ${driver.name} · ${driver.plate}',
                          style: Theme.of(context).textTheme.bodySmall,
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
