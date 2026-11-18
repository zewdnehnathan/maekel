import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';
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
      List<FoodOrder> orders = const [];
      List<MenuItem> menu = const [];
      if (mine != null) {
        orders = await repo.getMerchantOrders();
        menu = await repo.getMerchantMenu();
      }
      if (!mounted) return;
      setState(() {
        _merchant = mine;
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
    String? remotePhotoUrl = existing?.photoUrl;
    List<int>? pendingBytes;
    String? pendingFilename;
    String? pendingContentType;
    final picker = ImagePicker();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> pick(ImageSource source) async {
              final file = await picker.pickImage(
                source: source,
                maxWidth: 1600,
                imageQuality: 85,
              );
              if (file == null) return;
              final bytes = await file.readAsBytes();
              setLocal(() {
                pendingBytes = bytes;
                pendingFilename =
                    file.name.isEmpty ? 'dish.jpg' : file.name;
                pendingContentType = _guessContentType(file.name);
                remotePhotoUrl = null;
              });
            }

            return AlertDialog(
              backgroundColor: MaekelColors.panel,
              title: Text(existing == null ? 'Add dish' : 'Edit dish'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 140,
                        child: pendingBytes != null
                            ? Image.memory(
                                Uint8List.fromList(pendingBytes!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : remotePhotoUrl != null &&
                                    remotePhotoUrl!.isNotEmpty
                                ? Image.network(
                                    remotePhotoUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: MaekelColors.panelLift,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.restaurant),
                                    ),
                                  )
                                : Container(
                                    color: MaekelColors.panelLift,
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Add a photo',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Gallery'),
                        ),
                        TextButton.icon(
                          onPressed: () => pick(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined, size: 18),
                          label: const Text('Camera'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
    final bytes = pendingBytes;
    final filename = pendingFilename;
    final contentType = pendingContentType;
    final keepRemote = remotePhotoUrl;
    name.dispose();
    price.dispose();
    desc.dispose();

    if (saved != true || nameVal.isEmpty || priceVal == null || priceVal <= 0) {
      return;
    }

    await _run(() async {
      final repo = ref.read(foodRepositoryProvider);
      String? photoUrl = keepRemote;
      if (bytes != null && filename != null) {
        photoUrl = await repo.uploadDishPhoto(
          bytes: bytes,
          filename: filename,
          contentType: contentType ?? 'image/jpeg',
        );
      }
      if (existing == null) {
        await repo.createMenuItem(
          name: nameVal,
          priceEtb: priceVal,
          description: descVal,
          photoUrl: photoUrl,
          available: available,
        );
      } else {
        await repo.updateMenuItem(
          existing.id,
          name: nameVal,
          priceEtb: priceVal,
          description: descVal,
          photoUrl: photoUrl,
          available: available,
        );
      }
    });
  }

  String _guessContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).session;

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
                        'NO RESTAURANT LINKED',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      GlassPanel(
                        accent: MaekelColors.food,
                        child: Text(
                          session?.isFoodOps == true
                              ? 'Food ops does not edit restaurant menus here. Open Food ops to create a merchant and Assign owner phone to the restaurant staff. Only that owner can add dishes.'
                              : 'Ask Food ops to assign your phone as the owner of one restaurant. You can only edit that restaurant’s menu — never another store’s.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (session?.isFoodOps == true) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: MaekelColors.food,
                            foregroundColor: MaekelColors.ink,
                          ),
                          onPressed: () => context.go(AppRoutes.foodOps),
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          label: const Text('Open Food ops'),
                        ),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      item.photoUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 64,
                                        height: 64,
                                        color: MaekelColors.panelLift,
                                        child: const Icon(Icons.restaurant),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text(
                                          '${item.priceEtb} ETB',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: MaekelColors.food,
                                              ),
                                        ),
                                      ],
                                    ),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
