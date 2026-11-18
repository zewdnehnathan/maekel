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

  final _name = TextEditingController();
  final _subcity = TextEditingController(text: 'Bole');
  final _coverage = TextEditingController(text: 'Bole, CMC');
  MerchantKind _kind = MerchantKind.restaurant;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    _subcity.dispose();
    _coverage.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final board = await ref.read(foodRepositoryProvider).getOpsBoard();
      if (!mounted) return;
      setState(() {
        _orders = board.orders;
        _merchants = board.merchants;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
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
    await _run(() async {
      await ref.read(foodRepositoryProvider).opsOnboardMerchant(
            name: name,
            kind: _kind,
            subcity: subcity,
            coverageSubcities: coverage,
          );
      _name.clear();
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
                        child: Text(
                          '${m.name} · ${m.subcity} · '
                          '${m.isOpen ? 'open' : 'paused'} · '
                          'owner ${m.ownerUserId ?? 'unclaimed'} · '
                          'covers ${m.coverageSubcities.join(', ')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
