import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';

class FoodOpsScreen extends ConsumerStatefulWidget {
  const FoodOpsScreen({super.key});

  @override
  ConsumerState<FoodOpsScreen> createState() => _FoodOpsScreenState();
}

class _FoodOpsScreenState extends ConsumerState<FoodOpsScreen> {
  List<FoodOrder> _orders = const [];
  List<FoodMerchant> _merchants = const [];
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
      final board = await ref.read(foodRepositoryProvider).getOpsBoard();
      if (!mounted) return;
      setState(() {
        _orders = board.orders;
        _merchants = board.merchants;
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
        title: Text('Assign owner · ${merchant.name}'),
        content: TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: MaekelColors.ink),
          decoration: const InputDecoration(
            labelText: 'Restaurant staff phone (9 digits)',
            prefixText: '+251 ',
            helperText: 'Only this user can edit the menu.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: MaekelColors.food,
              foregroundColor: MaekelColors.ink,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Assign'),
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
    return FoodShell(
      title: 'Food ops',
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
                      'ORDER BOARD (${_orders.length})',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_orders.isEmpty)
                      const GlassPanel(child: Text('No recent orders.')),
                    for (final order in _orders) ...[
                      const SizedBox(height: 10),
                      GlassPanel(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${order.id.substring(0, 8)} · ${order.status.label}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${order.merchantId} → ${order.address.subcity} · ${order.grandTotalEtb} ETB',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (order.riderId != null)
                              Text(
                                'Rider: ${order.riderId}',
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
                                    child: const Text('Support cancel'),
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
                                    child: const Text('Clear rider'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'ONBOARD MERCHANT',
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
                            decoration:
                                const InputDecoration(labelText: 'Name'),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<MerchantKind>(
                            // ignore: deprecated_member_use
                            value: _kind,
                            dropdownColor: MaekelColors.panel,
                            decoration:
                                const InputDecoration(labelText: 'Kind'),
                            items: const [
                              DropdownMenuItem(
                                value: MerchantKind.restaurant,
                                child: Text('Restaurant'),
                              ),
                              DropdownMenuItem(
                                value: MerchantKind.grocery,
                                child: Text('Grocery'),
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
                            decoration:
                                const InputDecoration(labelText: 'Subcity'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _coverage,
                            style: const TextStyle(color: MaekelColors.ink),
                            decoration: const InputDecoration(
                              labelText: 'Coverage (comma-separated)',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _ownerPhone,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: MaekelColors.ink),
                            decoration: const InputDecoration(
                              labelText: 'Owner phone (restaurant staff)',
                              prefixText: '+251 ',
                              helperText:
                                  'Required for menu access — only this user edits dishes.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: MaekelColors.food,
                              foregroundColor: MaekelColors.ink,
                            ),
                            onPressed: _busy ? null : _onboard,
                            child: const Text('Create merchant'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'MERCHANTS (${_merchants.length})',
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
                              '${m.name} · ${m.subcity} · '
                              '${m.isOpen ? 'open' : 'paused'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              m.ownerUserId == null
                                  ? 'Owner: unassigned'
                                  : 'Owner: ${m.ownerUserId}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Covers ${m.coverageSubcities.join(', ')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed:
                                    _busy ? null : () => _assignOwner(m),
                                child: Text(
                                  m.ownerUserId == null
                                      ? 'Assign owner phone'
                                      : 'Reassign owner',
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
