import 'dart:async';
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
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

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
    final modNameControllers = <TextEditingController>[
      for (final m in existing?.modifiers ?? const <MenuModifier>[])
        TextEditingController(text: m.name),
    ];
    final modPriceControllers = <TextEditingController>[
      for (final m in existing?.modifiers ?? const <MenuModifier>[])
        TextEditingController(text: '${m.priceEtb}'),
    ];
    final modIds = <String>[
      for (final m in existing?.modifiers ?? const <MenuModifier>[]) m.id,
    ];

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
              title: Text(
                existing == null
                    ? AppLocalizations.of(context)!.foodAddDish
                    : '${AppLocalizations.of(context)!.edit} ${AppLocalizations.of(context)!.foodAddDish}',
              ),
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
                                      AppLocalizations.of(context)!.photos,
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
                          label: Text(AppLocalizations.of(context)!.gallery),
                        ),
                        TextButton.icon(
                          onPressed: () => pick(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined, size: 18),
                          label: Text(AppLocalizations.of(context)!.camera),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: name,
                      style: const TextStyle(color: MaekelColors.ink),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.eventsFieldTitle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: MaekelColors.ink),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.marketFieldPrice,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: desc,
                      style: const TextStyle(color: MaekelColors.ink),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.eventsFieldDescription,
                      ),
                      maxLines: 2,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        AppLocalizations.of(context)!.foodAvailableLabel,
                      ),
                      value: available,
                      activeThumbColor: MaekelColors.food,
                      onChanged: (v) => setLocal(() => available = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.foodOptions,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setLocal(() {
                              modIds.add('');
                              modNameControllers
                                  .add(TextEditingController());
                              modPriceControllers
                                  .add(TextEditingController(text: '0'));
                            });
                          },
                          child: Text(AppLocalizations.of(context)!.foodAddOption),
                        ),
                      ],
                    ),
                    for (var i = 0; i < modNameControllers.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: modNameControllers[i],
                                style: const TextStyle(color: MaekelColors.ink),
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.foodOptions,
                                  hintText: AppLocalizations.of(context)!
                                      .foodExtraCheeseHint,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: modPriceControllers[i],
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: MaekelColors.ink),
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.currencyEtb,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setLocal(() {
                                  modIds.removeAt(i);
                                  modNameControllers.removeAt(i).dispose();
                                  modPriceControllers.removeAt(i).dispose();
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                  ],
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
                  child: Text(
                    existing == null
                        ? AppLocalizations.of(context)!.add
                        : AppLocalizations.of(context)!.save,
                  ),
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
    final modifiers = <MenuModifier>[];
    for (var i = 0; i < modNameControllers.length; i++) {
      final modName = modNameControllers[i].text.trim();
      if (modName.isEmpty) continue;
      final modPrice =
          int.tryParse(modPriceControllers[i].text.trim()) ?? 0;
      modifiers.add(
        MenuModifier(
          id: i < modIds.length ? modIds[i] : '',
          name: modName,
          priceEtb: modPrice < 0 ? 0 : modPrice,
        ),
      );
    }
    final bytes = pendingBytes;
    final filename = pendingFilename;
    final contentType = pendingContentType;
    final keepRemote = remotePhotoUrl;
    name.dispose();
    price.dispose();
    desc.dispose();
    for (final c in modNameControllers) {
      c.dispose();
    }
    for (final c in modPriceControllers) {
      c.dispose();
    }

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
          modifiers: modifiers,
        );
      } else {
        await repo.updateMenuItem(
          existing.id,
          name: nameVal,
          priceEtb: priceVal,
          description: descVal,
          photoUrl: photoUrl,
          available: available,
          modifiers: modifiers,
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
      title: AppLocalizations.of(context)!.foodMerchantConsole,
      showBottomNav: false,
      actions: [
        if (_merchant != null)
          IconButton(
            tooltip: AppLocalizations.of(context)!.foodAddDish,
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
                        AppLocalizations.of(context)!.foodNoRestaurant.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      GlassPanel(
                        accent: MaekelColors.food,
                        child: Text(
                          session?.isFoodOps == true
                              ? AppLocalizations.of(context)!.foodOpsMenuExplain
                              : AppLocalizations.of(context)!
                                  .foodMerchantAssignExplain,
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
                          label: Text(AppLocalizations.of(context)!.foodOpenOps),
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
                              '${localizedPlace(AppLocalizations.of(context)!, _merchant!.subcity)} · ${_merchant!.hoursLabel}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _merchant!.isOpen
                                    ? AppLocalizations.of(context)!.foodStoreOpen
                                    : AppLocalizations.of(context)!.foodStorePaused,
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
                              '${AppLocalizations.of(context)!.foodMenu.toUpperCase()} (${_menu.length})',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _busy ? null : () => _editMenuItem(),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(AppLocalizations.of(context)!.foodAddDish),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_menu.isEmpty)
                        GlassPanel(
                          child: Text(
                            AppLocalizations.of(context)!.foodNoDishes,
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
                                          AppLocalizations.of(context)!
                                              .foodPriceEtb(item.priceEtb),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: MaekelColors.food,
                                              ),
                                        ),
                                        if (item.modifiers.isNotEmpty)
                                          Text(
                                            AppLocalizations.of(context)!
                                                .foodOptionsCount(
                                              item.modifiers.length,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
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
                                item.available
                                    ? AppLocalizations.of(context)!.foodAvailableLabel
                                    : AppLocalizations.of(context)!.foodUnavailable,
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
                                    child: Text(AppLocalizations.of(context)!.edit),
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
                                          ? AppLocalizations.of(context)!.foodMarkUnavailable
                                          : AppLocalizations.of(context)!.foodMarkAvailable,
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
                                    child: Text(
                                      AppLocalizations.of(context)!.delete,
                                      style: const TextStyle(
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
                        AppLocalizations.of(context)!
                            .foodOrderQueue(_orders.length)
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_orders.isEmpty)
                        GlassPanel(
                          child: Text(AppLocalizations.of(context)!.foodNoKitchenOrders),
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
                                '#${order.id.substring(0, 8)} · ${order.status.localized(AppLocalizations.of(context)!)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${localizedPlace(AppLocalizations.of(context)!, order.address.subcity)} · ${AppLocalizations.of(context)!.foodPriceEtbCod(order.grandTotalEtb)}',
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
                                      child: Text(AppLocalizations.of(context)!.accept),
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
                                      child: Text(AppLocalizations.of(context)!.reject),
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
                                      child: Text(AppLocalizations.of(context)!.preparing),
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
                                      child: Text(AppLocalizations.of(context)!.ready),
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
