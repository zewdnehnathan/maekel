import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';

class FoodMerchantConsoleScreen extends ConsumerStatefulWidget {
  const FoodMerchantConsoleScreen({super.key});

  @override
  ConsumerState<FoodMerchantConsoleScreen> createState() =>
      _FoodMerchantConsoleScreenState();
}

class _FoodMerchantConsoleScreenState
    extends ConsumerState<FoodMerchantConsoleScreen> {
  FoodMerchant? _merchant;
  List<FoodMerchant> _claimable = const [];
  List<FoodOrder> _orders = const [];
  List<MenuItem> _menu = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(foodRepositoryProvider);
      final mine = await repo.getMyMerchant();
      List<FoodMerchant> claimable = const [];
      List<FoodOrder> orders = const [];
      List<MenuItem> menu = const [];
      if (mine == null) {
        claimable = await repo.getClaimableMerchants();
      } else {
        orders = await repo.getMerchantOrders();
        menu = await repo.getMerchantMenu();
      }
      if (!mounted) return;
      setState(() {
        _merchant = mine;
        _claimable = claimable;
        _orders = orders;
        _menu = menu;
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

  Future<void> _editMenuItem({MenuItem? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final price = TextEditingController(
      text: existing == null ? '' : '${existing.priceEtb}',
    );
    final desc = TextEditingController(text: existing?.description ?? '');
    var available = existing?.available ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: MaekelColors.panel,
              title: Text(existing == null ? 'Add dish' : 'Edit dish'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      style: const TextStyle(color: MaekelColors.ink),
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: MaekelColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Price (ETB)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: desc,
                      style: const TextStyle(color: MaekelColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 2,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available'),
                      value: available,
                      activeThumbColor: MaekelColors.food,
                      onChanged: (v) => setLocal(() => available = v),
                    ),
                  ],
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
                  child: Text(existing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    final nameVal = name.text.trim();
    final priceVal = int.tryParse(price.text.trim());
    final descVal = desc.text.trim();
    name.dispose();
    price.dispose();
    desc.dispose();

    if (saved != true || nameVal.isEmpty || priceVal == null || priceVal <= 0) {
      return;
    }

    await _run(() async {
      final repo = ref.read(foodRepositoryProvider);
      if (existing == null) {
        await repo.createMenuItem(
          name: nameVal,
          priceEtb: priceVal,
          description: descVal,
          available: available,
        );
      } else {
        await repo.updateMenuItem(
          existing.id,
          name: nameVal,
          priceEtb: priceVal,
          description: descVal,
          available: available,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FoodShell(
      title: 'Merchant',
      showBottomNav: false,
      actions: [
        if (_merchant != null)
          IconButton(
            tooltip: 'Add dish',
            onPressed: _busy ? null : () => _editMenuItem(),
            icon: const Icon(Icons.add_rounded),
            color: MaekelColors.food,
          ),
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
                    if (_merchant == null) ...[
                      Text(
                        'CLAIM A STORE',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      GlassPanel(
                        accent: MaekelColors.food,
                        child: Text(
                          'Link an unclaimed merchant to this account to manage menu and orders.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_claimable.isEmpty)
                        const Text('No claimable merchants.'),
                      for (final m in _claimable) ...[
                        GlassPanel(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                m.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${m.kind.name} · ${m.subcity}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
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
                                                .claimMerchant(m.id);
                                          },
                                        ),
                                child: const Text('Claim this store'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ] else ...[
                      GlassPanel(
                        accent: MaekelColors.food,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _merchant!.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_merchant!.subcity} · ${_merchant!.hoursLabel}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _merchant!.isOpen
                                    ? 'Store open'
                                    : 'Store paused',
                              ),
                              value: _merchant!.isOpen,
                              activeThumbColor: MaekelColors.food,
                              onChanged: _busy
                                  ? null
                                  : (v) => _run(
                                        () async {
                                          await ref
                                              .read(foodRepositoryProvider)
                                              .setMerchantOpen(v);
                                        },
                                      ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'MENU (${_menu.length})',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _busy ? null : () => _editMenuItem(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add dish'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_menu.isEmpty)
                        const GlassPanel(
                          child: Text(
                            'No dishes yet. Add name + price so customers can order.',
                          ),
                        ),
                      for (final item in _menu) ...[
                        const SizedBox(height: 10),
                        GlassPanel(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  Text(
                                    '${item.priceEtb} ETB',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: MaekelColors.food),
                                  ),
                                ],
                              ),
                              if (item.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                item.available ? 'Available' : 'Unavailable',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: item.available
                                          ? MaekelColors.food
                                          : MaekelColors.muted,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _editMenuItem(existing: item),
                                    child: const Text('Edit'),
                                  ),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(
                                              () async {
                                                await ref
                                                    .read(
                                                      foodRepositoryProvider,
                                                    )
                                                    .updateMenuItem(
                                                      item.id,
                                                      available:
                                                          !item.available,
                                                    );
                                              },
                                            ),
                                    child: Text(
                                      item.available
                                          ? 'Mark unavailable'
                                          : 'Mark available',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(
                                              () async {
                                                await ref
                                                    .read(
                                                      foodRepositoryProvider,
                                                    )
                                                    .deleteMenuItem(item.id);
                                              },
                                            ),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: MaekelColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Text(
                        'ORDER QUEUE (${_orders.length})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_orders.isEmpty)
                        const GlassPanel(
                          child: Text('No open kitchen orders.'),
                        ),
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
                                '${order.address.subcity} · ${order.grandTotalEtb} ETB COD',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                order.lines
                                    .map((l) => '${l.quantity}× ${l.item.name}')
                                    .join(', '),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (order.status == OrderStatus.placed)
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
                                                      .read(
                                                        foodRepositoryProvider,
                                                      )
                                                      .merchantAccept(order.id);
                                                },
                                              ),
                                      child: const Text('Accept'),
                                    ),
                                  if (order.status == OrderStatus.placed ||
                                      order.status == OrderStatus.confirmed)
                                    TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _run(
                                                () async {
                                                  await ref
                                                      .read(
                                                        foodRepositoryProvider,
                                                      )
                                                      .merchantReject(order.id);
                                                },
                                              ),
                                      child: const Text('Reject'),
                                    ),
                                  if (order.status == OrderStatus.confirmed)
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
                                                      .read(
                                                        foodRepositoryProvider,
                                                      )
                                                      .merchantPreparing(
                                                        order.id,
                                                      );
                                                },
                                              ),
                                      child: const Text('Preparing'),
                                    ),
                                  if (order.status == OrderStatus.preparing)
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
                                                      .read(
                                                        foodRepositoryProvider,
                                                      )
                                                      .merchantReady(order.id);
                                                },
                                              ),
                                      child: const Text('Ready'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
    );
  }
}
