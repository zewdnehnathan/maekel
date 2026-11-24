import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/ride_map.dart';
import '../components/ride_shell.dart';
import '../models/ride_models.dart';
import '../providers/ride_providers.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

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
      return RideShell(
        title: AppLocalizations.of(context)!.rideTripTitle,
        showBottomNav: false,
        child: Center(child: Text(AppLocalizations.of(context)!.rideTripNotFound)),
      );
    }

    final pickup = repo.getPlace(trip.pickupId);
    final dropoff = repo.getPlace(trip.dropoffId);
    final driver =
        trip.driverId == null ? null : repo.getDriver(trip.driverId!);
    final liveDriver = driver?.point;
    final driverPoint = liveDriver ??
        estimateDriverPoint(
          status: trip.status,
          pickup: pickup,
          dropoff: dropoff,
          driver: driver,
        );
    final mapPickup = trip.pickupPoint ?? pickup?.point;
    final mapDropoff = trip.dropoffPoint ?? dropoff?.point;
    final l10n = AppLocalizations.of(context)!;
    final vehicleLabel = localizedVehicleClass(l10n, trip.vehicleClass);

    return RideShell(
      title: AppLocalizations.of(context)!.rideTripTitle,
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          RideMap(
            pickupPoint: mapPickup,
            dropoffPoint: mapDropoff,
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
                  trip.status.localized(AppLocalizations.of(context)!).toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.rideVehicleFare(
                    trip.fareEtb,
                    vehicleLabel,
                  ),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 32,
                        color: MaekelColors.signal,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.rideFrom(
                    localizedPlace(
                      l10n,
                      pickup?.name ?? trip.pickupId,
                    ),
                  ),
                ),
                Text(
                  l10n.rideTo(
                    localizedPlace(
                      l10n,
                      dropoff?.name ?? trip.dropoffId,
                    ),
                  ),
                ),
                if (trip.etaMinutes != null &&
                    (trip.status == TripStatus.matching ||
                        trip.status == TripStatus.assigned ||
                        trip.status == TripStatus.arriving ||
                        trip.status == TripStatus.requested)) ...[
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!
                        .rideDriverEta(trip.etaMinutes!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MaekelColors.signal,
                        ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  trip.wasNoDriver
                      ? AppLocalizations.of(context)!.rideNoDriverAvailable
                      : AppLocalizations.of(context)!.ridePayCashLocked,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (trip.wasNoDriver) ...[
            const SizedBox(height: 14),
            GlassPanel(
              accent: MaekelColors.danger,
              child: Text(
                AppLocalizations.of(context)!.rideNoDrivers,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
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
                          AppLocalizations.of(context)!.rideDriverMeta(
                            driver.carModel,
                            driver.plate,
                            driver.rating,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (trip.etaMinutes != null)
                          Text(
                            AppLocalizations.of(context)!
                                .rideArrivingIn(trip.etaMinutes!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () => launchUrl(
                      Uri(scheme: 'tel', path: driver.phoneE164),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: MaekelColors.ride,
                      foregroundColor: MaekelColors.voidBlack,
                    ),
                    icon: const Icon(Icons.call_rounded),
                    tooltip: AppLocalizations.of(context)!.rideCallDriver,
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
              child: Text(AppLocalizations.of(context)!.rideCancelTrip),
            ),
          if (trip.status == TripStatus.completed &&
              trip.passengerRating == null) ...[
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.rideRateDriver,
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
              child: Text(AppLocalizations.of(context)!.rideSubmitRating),
            ),
          ],
          if (trip.passengerRating != null) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!
                  .rideYouRated(trip.passengerRating!),
            ),
          ],
        ],
      ),
    );
  }
}
