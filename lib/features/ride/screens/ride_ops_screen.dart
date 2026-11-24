import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/ride_shell.dart';
import '../models/ride_models.dart';
import '../services/api_ride_repository.dart';
import '../providers/ride_providers.dart';
import '../../../l10n/app_localizations.dart';

class RideOpsScreen extends ConsumerStatefulWidget {
  const RideOpsScreen({super.key});

  @override
  ConsumerState<RideOpsScreen> createState() => _RideOpsScreenState();
}

class _RideOpsScreenState extends ConsumerState<RideOpsScreen> {
  RideFareConfig? _config;
  List<RideDriver> _drivers = const [];
  List<RideTrip> _active = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = ref.read(rideRepositoryProvider);
    if (repo is! ApiRideRepository) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.rideOpsApiOnly;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await repo.getFareConfig();
      final drivers = await repo.getOpsDrivers();
      final active = await repo.getOpsActiveTrips();
      if (!mounted) return;
      setState(() {
        _config = config;
        _drivers = drivers;
        _active = active;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    final config = _config;
    final repo = ref.read(rideRepositoryProvider);
    if (config == null || repo is! ApiRideRepository) return;
    try {
      final saved = await repo.updateFareConfig(config);
      if (!mounted) return;
      setState(() => _config = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.rideFareConfigSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final l10n = AppLocalizations.of(context)!;

    return RideShell(
      title: l10n.rideOpsTitle,
      showBottomNav: false,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (_error != null)
                  GlassPanel(
                    accent: MaekelColors.danger,
                    child: Text(_error!),
                  ),
                Text(
                  AppLocalizations.of(context)!.rideFareConfig.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                if (config != null)
                  GlassPanel(
                    accent: MaekelColors.ride,
                    child: Column(
                      children: [
                        _numField(
                          l10n.rideBaseEtb,
                          config.baseEtb.toDouble(),
                          (v) => setState(
                            () => _config = RideFareConfig(
                              baseEtb: v.round(),
                              perKmEtb: config.perKmEtb,
                              minFareEtb: config.minFareEtb,
                              offerRadiusKm: config.offerRadiusKm,
                              etaBaseMin: config.etaBaseMin,
                              etaMinPerKm: config.etaMinPerKm,
                            ),
                          ),
                        ),
                        _numField(
                          l10n.ridePerKmEtb,
                          config.perKmEtb,
                          (v) => setState(
                            () => _config = RideFareConfig(
                              baseEtb: config.baseEtb,
                              perKmEtb: v,
                              minFareEtb: config.minFareEtb,
                              offerRadiusKm: config.offerRadiusKm,
                              etaBaseMin: config.etaBaseMin,
                              etaMinPerKm: config.etaMinPerKm,
                            ),
                          ),
                        ),
                        _numField(
                          l10n.rideMinFareEtb,
                          config.minFareEtb.toDouble(),
                          (v) => setState(
                            () => _config = RideFareConfig(
                              baseEtb: config.baseEtb,
                              perKmEtb: config.perKmEtb,
                              minFareEtb: v.round(),
                              offerRadiusKm: config.offerRadiusKm,
                              etaBaseMin: config.etaBaseMin,
                              etaMinPerKm: config.etaMinPerKm,
                            ),
                          ),
                        ),
                        _numField(
                          l10n.rideOfferRadiusKm,
                          config.offerRadiusKm,
                          (v) => setState(
                            () => _config = RideFareConfig(
                              baseEtb: config.baseEtb,
                              perKmEtb: config.perKmEtb,
                              minFareEtb: config.minFareEtb,
                              offerRadiusKm: v,
                              etaBaseMin: config.etaBaseMin,
                              etaMinPerKm: config.etaMinPerKm,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _saveConfig,
                          child: Text(AppLocalizations.of(context)!.rideSaveFareParams),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  AppLocalizations.of(context)!
                      .rideDrivers(_drivers.length)
                      .toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                for (final d in _drivers) ...[
                  GlassPanel(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${d.plate} · ${d.isOnline ? l10n.online : l10n.offline} · '
                                '${d.isApproved ? l10n.approved : l10n.pending}',
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final repo = ref.read(rideRepositoryProvider);
                            if (repo is! ApiRideRepository) return;
                            await repo.setDriverApproved(
                              driverId: d.id,
                              approved: !d.isApproved,
                            );
                            await _load();
                          },
                          child: Text(d.isApproved ? l10n.rideSuspend : l10n.rideApprove),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!
                      .rideActiveTrips(_active.length)
                      .toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                if (_active.isEmpty)
                  Text(AppLocalizations.of(context)!.rideNoActiveTrips)
                else
                  for (final trip in _active) ...[
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${trip.status.localized(AppLocalizations.of(context)!)} · ${trip.fareEtb} ETB',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${trip.pickupId} → ${trip.dropoffId}',
                          ),
                          TextButton(
                            onPressed: () async {
                              final repo = ref.read(rideRepositoryProvider);
                              if (repo is! ApiRideRepository) return;
                              await repo.opsCancelTrip(
                                trip.id,
                                note: l10n.rideCancelledByOps,
                              );
                              await _load();
                            },
                            child: Text(AppLocalizations.of(context)!.rideForceCancel),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
    );
  }

  Widget _numField(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: value.toString(),
        style: const TextStyle(color: MaekelColors.ink),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        onChanged: (raw) {
          final v = double.tryParse(raw);
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
