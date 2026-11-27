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

class FoodOpsScreen extends ConsumerStatefulWidget {
  const FoodOpsScreen({super.key});

  @override
  ConsumerState<FoodOpsScreen> createState() => _FoodOpsScreenState();
}

class _FoodOpsScreenState extends ConsumerState<FoodOpsScreen> {
  List<FoodOrder> _orders = const [];
  List<FoodMerchant> _merchants = const [];
  List<FoodApplication> _applications = const [];
  List<CustomerReport> _reports = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Timer? _poll;

  final _name = TextEditingController();
  final _subcity = TextEditingController(text: 'Bole');
  final _coverage = TextEditingController(text: 'Bole, CMC');
  final _ownerPhone = TextEditingController();
  MerchantKind _kind = MerchantKind.restaurant;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_busy && mounted) unawaited(_load(silent: true));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _name.dispose();
    _subcity.dispose();
    _coverage.dispose();
    _ownerPhone.dispose();
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
      final repo = ref.read(foodRepositoryProvider);
      final board = await repo.getOpsBoard();
      final apps = await repo.opsListApplications(status: 'pending');
      final reports = await repo.opsListReports(status: 'pending');
      if (!mounted) return;
      setState(() {
        _orders = board.orders;
        _merchants = board.merchants;
        _applications = apps;
        _reports = reports;
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

  Future<void> _onboard() async {
    final name = _name.text.trim();
    final subcity = _subcity.text.trim();
    if (name.isEmpty || subcity.isEmpty) return;
    final coverage = _coverage.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final ownerLocal = _ownerPhone.text.replaceAll(RegExp(r'\D'), '');
    await _run(() async {
      await ref.read(foodRepositoryProvider).opsOnboardMerchant(
            name: name,
            kind: _kind,
            subcity: subcity,
            coverageSubcities: coverage,
            ownerPhone: ownerLocal.length == 9 ? ownerLocal : null,
          );
      _name.clear();
      _ownerPhone.clear();
    });
  }

  Future<void> _assignOwner(FoodMerchant merchant) async {
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MaekelColors.panel,
        title: Text(
          AppLocalizations.of(context)!.foodAssignOwner(merchant.name),
        ),
        content: TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: MaekelColors.ink),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.adminLocalPhone,
            prefixText: '${AppLocalizations.of(context)!.phonePrefix} ',
            helperText: AppLocalizations.of(context)!.foodStaffPhoneHelper,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: MaekelColors.food,
              foregroundColor: MaekelColors.ink,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.foodAssign),
          ),
        ],
      ),
    );
    final local = phone.text.replaceAll(RegExp(r'\D'), '');
    phone.dispose();
    if (ok != true || local.length != 9) return;
    await _run(() async {
      await ref.read(foodRepositoryProvider).opsAssignOwner(
            merchant.id,
            ownerPhone: local,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FoodShell(
      title: l10n.foodOps,
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
                      'CUSTOMER NO-SHOW REPORTS (${_reports.length})',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_reports.isEmpty)
                      const GlassPanel(
                        child: Text('No pending customer reports.'),
                      ),
                    for (final report in _reports) ...[
                      const SizedBox(height: 10),
                      GlassPanel(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order ${report.orderId.substring(0, 8)} · ${report.reason}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Customer ${report.customerId.substring(0, 8)} · via ${report.reporterKind}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (report.note != null && report.note!.isNotEmpty)
                              Text(
                                report.note!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(() async {
                                            await ref
                                                .read(foodRepositoryProvider)
                                                .opsReviewReport(
                                                  report.id,
                                                  action: 'warn',
                                                );
                                          }),
                                  child: const Text('Warn'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: MaekelColors.danger,
                                  ),
                                  onPressed: _busy
                                      ? null
                                      : () => _run(() async {
                                            await ref
                                                .read(foodRepositoryProvider)
                                                .opsReviewReport(
                                                  report.id,
                                                  action: 'suspend',
                                                );
                                          }),
                                  child: const Text('Suspend'),
                                ),
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(() async {
                                            await ref
                                                .read(foodRepositoryProvider)
                                                .opsReviewReport(
                                                  report.id,
                                                  action: 'ignore',
                                                );
                                          }),
                                  child: const Text('Ignore'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Text(
                      'PENDING APPLICATIONS (${_applications.length})',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_applications.isEmpty)
                      const GlassPanel(
                        child: Text('No pending partner applications.'),
                      ),
                    for (final app in _applications) ...[
                      const SizedBox(height: 10),
                      GlassPanel(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${app.kind == FoodApplicationKind.deliveryOrg ? 'delivery' : 'restaurant'} · ${app.applicantPhone} · ${app.subcity}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                FilledButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(() async {
                                            await ref
                                                .read(foodRepositoryProvider)
                                                .opsApproveApplication(app.id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Approved. Applicant must re-OTP for roles.',
                                                  ),
                                                ),
                                              );
                                            }
                                          }),
                                  child: const Text('Approve'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(() async {
                                            await ref
                                                .read(foodRepositoryProvider)
                                                .opsRejectApplication(app.id);
                                          }),
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Text(
                      l10n.foodOrderBoard(_orders.length).toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_orders.isEmpty)
                      GlassPanel(child: Text(l10n.foodNoRecentOrders)),
                    for (final order in _orders) ...[
                      const SizedBox(height: 10),
                      GlassPanel(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${order.id.substring(0, 8)} · ${order.status.localized(l10n)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${order.merchantId} → ${localizedPlace(l10n, order.address.subcity)} · ${order.grandTotalEtb} ETB',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (order.riderId != null)
                              Text(
                                l10n.foodRiderLabel(order.riderId!),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (order.status != OrderStatus.delivered &&
                                    order.status != OrderStatus.cancelled)
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(
                                              () async {
                                                await ref
                                                    .read(
                                                      foodRepositoryProvider,
                                                    )
                                                    .opsCancel(order.id);
                                              },
                                            ),
                                    child: Text(AppLocalizations.of(context)!.foodSupportCancel),
                                  ),
                                if (order.riderId != null &&
                                    (order.status == OrderStatus.ready ||
                                        order.status == OrderStatus.pickedUp ||
                                        order.status == OrderStatus.onTheWay))
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(
                                              () async {
                                                await ref
                                                    .read(
                                                      foodRepositoryProvider,
                                                    )
                                                    .opsReassign(
                                                      order.id,
                                                      riderId: null,
                                                    );
                                              },
                                            ),
                                    child: Text(AppLocalizations.of(context)!.foodClearRider),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      l10n.foodOnboardMerchant.toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    GlassPanel(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          TextField(
                            controller: _name,
                            style: const TextStyle(color: MaekelColors.ink),
                            decoration: InputDecoration(
                              labelText: l10n.eventsFieldTitle,
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<MerchantKind>(
                            // ignore: deprecated_member_use
                            value: _kind,
                            dropdownColor: MaekelColors.panel,
                            decoration: InputDecoration(labelText: l10n.foodKind),
                            items: [
                              DropdownMenuItem(
                                value: MerchantKind.restaurant,
                                child: Text(l10n.foodRestaurant),
                              ),
                              DropdownMenuItem(
                                value: MerchantKind.grocery,
                                child: Text(l10n.foodGrocery),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _kind = v);
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _subcity,
                            style: const TextStyle(color: MaekelColors.ink),
                            decoration: InputDecoration(
                              labelText: l10n.foodSubcity,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _coverage,
                            style: const TextStyle(color: MaekelColors.ink),
                            decoration: InputDecoration(
                              labelText: l10n.foodCoverageLabel,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _ownerPhone,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: MaekelColors.ink),
                            decoration: InputDecoration(
                              labelText: l10n.foodStaffPhone,
                              prefixText: '${l10n.phonePrefix} ',
                              helperText: l10n.foodStaffPhoneHelper,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: MaekelColors.food,
                              foregroundColor: MaekelColors.ink,
                            ),
                            onPressed: _busy ? null : _onboard,
                            child: Text(l10n.foodCreateMerchant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.foodMerchants(_merchants.length).toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    for (final m in _merchants) ...[
                      const SizedBox(height: 8),
                      GlassPanel(
                        borderRadius: 14,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${m.name} · ${localizedPlace(l10n, m.subcity)} · ${m.isOpen ? l10n.foodStoreOpen : l10n.foodStorePaused}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              l10n.foodOwner(
                                m.ownerPhone?.isNotEmpty == true
                                    ? m.ownerPhone!
                                    : (m.ownerUserId ?? l10n.foodUnassigned),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              l10n.foodCovers(
                                localizedPlaceList(
                                  l10n,
                                  m.coverageSubcities.join(', '),
                                ),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed:
                                    _busy ? null : () => _assignOwner(m),
                                child: Text(
                                  m.ownerUserId == null
                                      ? l10n.foodAssignOwner(m.name)
                                      : l10n.foodReassign,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
