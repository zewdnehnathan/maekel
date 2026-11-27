import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';

class FoodDeliveryConsoleScreen extends ConsumerStatefulWidget {
  const FoodDeliveryConsoleScreen({super.key});

  @override
  ConsumerState<FoodDeliveryConsoleScreen> createState() =>
      _FoodDeliveryConsoleScreenState();
}

class _FoodDeliveryConsoleScreenState
    extends ConsumerState<FoodDeliveryConsoleScreen> {
  DeliveryOrg? _org;
  List<DeliveryMember> _members = const [];
  List<FoodOrder> _active = const [];
  List<FoodOrder> _reportable = const [];
  final _phone = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Timer? _poll;

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
    _phone.dispose();
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
      final org = await repo.getDeliveryOrg();
      final members = await repo.getDeliveryMembers();
      final active = await repo.getDeliveryActiveOrders();
      final reportable = await repo.getDeliveryReportableOrders();
      if (!mounted) return;
      setState(() {
        _org = org;
        _members = members;
        _active = active;
        _reportable = reportable;
        _loading = false;
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

  Future<void> _addMember() async {
    final local = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (local.length < 9) return;
    setState(() => _busy = true);
    try {
      await ref.read(foodRepositoryProvider).addDeliveryMember(local);
      _phone.clear();
      await _load(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Rider added. They must log out and OTP again for food_rider.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FoodShell(
      title: 'Delivery fleet',
      showBottomNav: false,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    GlassPanel(
                      accent: MaekelColors.food,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _org?.name ?? 'Fleet',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (_org?.ownerPhone != null)
                            Text(
                              _org!.ownerPhone!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'DELIVERY PERSONNEL',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Rider phone (9 digits)',
                              prefixText: '+251 ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _busy ? null : _addMember,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final m in _members)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(m.phone),
                        subtitle: Text(m.riderUserId),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _busy
                              ? null
                              : () async {
                                  await ref
                                      .read(foodRepositoryProvider)
                                      .removeDeliveryMember(m.riderUserId);
                                  await _load(silent: true);
                                },
                        ),
                      ),
                    const SizedBox(height: 18),
                    Text(
                      'ACTIVE DELIVERIES',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_active.isEmpty)
                      Text(
                        'No active jobs for your fleet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: MaekelColors.muted,
                            ),
                      )
                    else
                      for (final o in _active)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassPanel(
                            accent: MaekelColors.food,
                            child: Text(
                              '${o.id} · ${o.status.name} · ${o.grandTotalEtb} ETB',
                            ),
                          ),
                        ),
                    const SizedBox(height: 18),
                    Text(
                      'REPORT CUSTOMER NO-SHOW',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'If the customer disappears at drop-off, report them for Food ops review.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MaekelColors.muted,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (_reportable.isEmpty)
                      Text(
                        'No reportable deliveries right now.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: MaekelColors.muted,
                            ),
                      )
                    else
                      for (final o in _reportable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassPanel(
                            accent: MaekelColors.danger,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${o.id.substring(0, 8)} · ${o.status.name} · ${o.grandTotalEtb} ETB',
                                  ),
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _reportNoShow(o.id),
                                  child: const Text('Report'),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
    );
  }

  Future<void> _reportNoShow(String orderId) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MaekelColors.panel,
        title: const Text('Report customer no-show'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'What happened?',
            hintText: 'Customer not at pin / refused package…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, noteController.text.trim()),
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
    if (note == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(foodRepositoryProvider).reportCustomer(
            orderId: orderId,
            note: note.isEmpty ? null : note,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report sent to Food ops')),
        );
      }
      await _load(silent: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
