import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

class FoodRiderScreen extends ConsumerStatefulWidget {
  const FoodRiderScreen({super.key});

  @override
  ConsumerState<FoodRiderScreen> createState() => _FoodRiderScreenState();
}

class _FoodRiderScreenState extends ConsumerState<FoodRiderScreen> {
  List<FoodOrder> _available = const [];
  List<FoodOrder> _active = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_busy && mounted) unawaited(_load(silent: true));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final jobs = await ref.read(foodRepositoryProvider).getRiderJobs();
      if (!mounted) return;
      setState(() {
        _available = jobs.available;
        _active = jobs.active;
        _loading = false;
        if (!silent) _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete(FoodOrder order) async {
    final controller = TextEditingController();
    final otp = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MaekelColors.panel,
        title: Text(AppLocalizations.of(context)!.foodDeliveryOtp),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: MaekelColors.ink),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.foodAskOtp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: MaekelColors.food,
              foregroundColor: MaekelColors.ink,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.foodConfirmCod),
          ),
        ],
      ),
    );
    controller.dispose();
    if (otp == null || otp.isEmpty) return;
    await _run(() async {
      await ref.read(foodRepositoryProvider).riderComplete(
            order.id,
            otp: otp,
          );
    });
  }

  Widget _jobCard(FoodOrder order, {required bool mine}) {
    final l10n = AppLocalizations.of(context)!;
    final merchant = ref.watch(foodMerchantProvider(order.merchantId));
    final pickupName = merchant?.name ?? l10n.foodRestaurant;
    final pickupAreaRaw = merchant?.subcity ?? order.address.subcity;
    final pickupArea = localizedPlace(l10n, pickupAreaRaw);
    final pickupHours = merchant?.hoursLabel;

    return GlassPanel(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${order.id.substring(0, 8)} · ${order.status.localized(l10n)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.foodPickup.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: MaekelColors.food,
                ),
          ),
          Text(
            pickupName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            pickupHours == null
                ? pickupArea
                : '$pickupArea · $pickupHours',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.foodDropoff.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: MaekelColors.amber,
                ),
          ),
          Text(
            '${order.address.label} · ${localizedPlace(l10n, order.address.subcity)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            order.address.details,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.foodCollectCod(order.grandTotalEtb),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: MaekelColors.food,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!mine)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: MaekelColors.food,
                    foregroundColor: MaekelColors.ink,
                  ),
                  onPressed: _busy
                      ? null
                      : () => _run(
                            () async {
                              await ref
                                  .read(foodRepositoryProvider)
                                  .riderClaim(order.id);
                            },
                          ),
                  child: Text(AppLocalizations.of(context)!.foodClaimJob),
                ),
              if (mine && order.status == OrderStatus.ready)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: MaekelColors.food,
                    foregroundColor: MaekelColors.ink,
                  ),
                  onPressed: _busy
                      ? null
                      : () => _run(
                            () async {
                              await ref
                                  .read(foodRepositoryProvider)
                                  .riderPickup(order.id);
                            },
                          ),
                  child: Text(AppLocalizations.of(context)!.foodPickedUp),
                ),
              if (mine && order.status == OrderStatus.pickedUp)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: MaekelColors.food,
                    foregroundColor: MaekelColors.ink,
                  ),
                  onPressed: _busy
                      ? null
                      : () => _run(
                            () async {
                              await ref
                                  .read(foodRepositoryProvider)
                                  .riderOnTheWay(order.id);
                            },
                          ),
                  child: Text(AppLocalizations.of(context)!.foodOnTheWay),
                ),
              if (mine &&
                  (order.status == OrderStatus.onTheWay ||
                      order.status == OrderStatus.pickedUp))
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: MaekelColors.amber,
                    foregroundColor: MaekelColors.ink,
                  ),
                  onPressed: _busy ? null : () => _complete(order),
                  child: Text(AppLocalizations.of(context)!.foodCompleteCod),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FoodShell(
      title: l10n.foodRider,
      showBottomNav: false,
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
          color: MaekelColors.food,
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: MaekelColors.danger),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    Text(
                      l10n.foodMyJobs(_active.length).toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_active.isEmpty)
                      GlassPanel(child: Text(l10n.foodNoActiveDelivery)),
                    for (final o in _active) ...[
                      const SizedBox(height: 10),
                      _jobCard(o, mine: true),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      l10n.foodAvailable(_available.length).toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_available.isEmpty)
                      GlassPanel(
                        child: Text(l10n.foodNoReadyOrders),
                      ),
                    for (final o in _available) ...[
                      const SizedBox(height: 10),
                      _jobCard(o, mine: false),
                    ],
                  ],
                ),
    );
  }
}
