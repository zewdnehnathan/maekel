import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';
import '../components/market_shell.dart';
import '../models/market_models.dart';
import '../providers/market_providers.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

class MarketOpsScreen extends ConsumerStatefulWidget {
  const MarketOpsScreen({super.key});

  @override
  ConsumerState<MarketOpsScreen> createState() => _MarketOpsScreenState();
}

class _MarketOpsScreenState extends ConsumerState<MarketOpsScreen> {
  MarketOpsQueue? _queue;
  MarketConfig? _config;
  bool _loading = true;
  String? _error;

  static const _iconChoices = <String>[
    'phone',
    'devices',
    'car',
    'home',
    'chair',
    'checkroom',
    'sports',
    'work',
    'pets',
    'category',
  ];

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
      final repo = ref.read(marketRepositoryProvider);
      final queue = await repo.getOpsQueue();
      final config = await repo.getConfig();
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _config = config;
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

  Future<void> _approve(MarketAd ad) async {
    try {
      await ref.read(marketRepositoryProvider).updateAdStatus(
            ad.id,
            status: AdStatus.approved,
          );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _reject(MarketAd ad) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MaekelColors.panel,
          title: Text(AppLocalizations.of(context)!.marketOpsRejectAd),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.marketRejectReasonHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.reject),
            ),
          ],
        );
      },
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      try {
        await ref.read(marketRepositoryProvider).updateAdStatus(
              ad.id,
              status: AdStatus.rejected,
              rejectReason: controller.text.trim(),
            );
        await _load();
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _resolveReport(
    MarketReportItem report, {
    required String action,
  }) async {
    try {
      await ref.read(marketRepositoryProvider).resolveReport(
            reportId: report.id,
            action: action,
            note: action == 'dismiss'
                ? AppLocalizations.of(context)!.marketDismissed
                : null,
          );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    var iconName = _iconChoices.contains('category')
        ? 'category'
        : _iconChoices.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: MaekelColors.panel,
              title: Text(AppLocalizations.of(context)!.marketOpsAddCategory),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: MaekelColors.ink),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.marketDisplayName,
                        hintText:
                            AppLocalizations.of(context)!.marketDisplayNameHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: idController,
                      style: const TextStyle(color: MaekelColors.ink),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.marketIdOptional,
                        hintText: AppLocalizations.of(context)!.marketIdAutoHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: iconName,
                      dropdownColor: MaekelColors.panel,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.marketIconKey,
                      ),
                      items: [
                        for (final icon in _iconChoices)
                          DropdownMenuItem(value: icon, child: Text(icon)),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => iconName = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.add),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    final name = nameController.text.trim();
    if (name.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.marketNameMinChars),
        ),
      );
      return;
    }

    try {
      final created = await ref.read(marketRepositoryProvider).createCategory(
            id: idController.text.trim().isEmpty
                ? null
                : idController.text.trim(),
            name: name,
            iconName: iconName,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.marketAddedName(created.name),
          ),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _editCategory(MarketCategory category) async {
    final nameController = TextEditingController(text: category.name);
    var iconName = category.iconName;
    if (!_iconChoices.contains(iconName)) {
      iconName = _iconChoices.first;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: MaekelColors.panel,
              title: Text(
                AppLocalizations.of(context)!.marketEditCategory(category.id),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: MaekelColors.ink),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.marketDisplayName,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: iconName,
                    dropdownColor: MaekelColors.panel,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.marketIconKey,
                    ),
                    items: [
                      for (final icon in _iconChoices)
                        DropdownMenuItem(value: icon, child: Text(icon)),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => iconName = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    final name = nameController.text.trim();
    if (name.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.marketNameMinChars),
        ),
      );
      return;
    }

    try {
      await ref.read(marketRepositoryProvider).updateCategory(
            category.id,
            name: name,
            iconName: iconName,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.marketUpdatedName(name)),
        ),
      );
      setState(() {});
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _editMaxActiveAds() async {
    final current = _config?.maxActiveFreeAds ?? 5;
    final controller = TextEditingController(text: '$current');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MaekelColors.panel,
          title: Text(AppLocalizations.of(context)!.marketOpsMaxFreeAds),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.marketLimitLabel,
              helperText: AppLocalizations.of(context)!.marketLimitHelper,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final value = int.tryParse(controller.text.trim());
    if (value == null || value < 1 || value > 50) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.marketEnterMaxAds),
        ),
      );
      return;
    }
    try {
      final updated = await ref
          .read(marketRepositoryProvider)
          .updateMarketConfig(maxActiveFreeAds: value);
      if (!mounted) return;
      setState(() => _config = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.marketMaxActiveSet(value),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue;
    final categories = ref.watch(marketCategoriesProvider);
    final isPlatformAdmin =
        ref.watch(authProvider).session?.isPlatformAdmin ?? false;

    final l10n = AppLocalizations.of(context)!;

    return MarketShell(
      title: l10n.marketOpsTitle,
      showBottomNav: false,
      actions: [
        if (isPlatformAdmin)
          IconButton(
            onPressed: () => context.push(AppRoutes.adminStaff),
            icon: const Icon(Icons.group_outlined),
            color: MaekelColors.amber,
            tooltip: AppLocalizations.of(context)!.adminTitle,
          ),
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
          color: MaekelColors.signal,
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      Text(
                        AppLocalizations.of(context)!
                            .marketOpsPending(queue?.pendingAds.length ?? 0)
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (queue == null || queue.pendingAds.isEmpty)
                        GlassPanel(
                          child: Text(AppLocalizations.of(context)!.marketOpsQueueEmpty),
                        )
                      else
                        for (final ad in queue.pendingAds) ...[
                          GlassPanel(
                            accent: MaekelColors.amber,
                            borderRadius: 18,
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () async {
                                    await ref
                                        .read(marketRepositoryProvider)
                                        .fetchAd(ad.id);
                                    if (!context.mounted) return;
                                    context.push(
                                      '${AppRoutes.market}/ads/${ad.id}',
                                    );
                                  },
                                  child: Text(
                                    ad.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: MaekelColors.signal),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ad.priceEtb} ${AppConstants.currencyCode} · ${localizedPlace(AppLocalizations.of(context)!, ad.subcity)}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ad.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        await ref
                                            .read(marketRepositoryProvider)
                                            .fetchAd(ad.id);
                                        if (!context.mounted) return;
                                        context.push(
                                          '${AppRoutes.market}/ads/${ad.id}',
                                        );
                                      },
                                      child: Text(
                                        AppLocalizations.of(context)!.open,
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () => _approve(ad),
                                      child: Text(AppLocalizations.of(context)!.approve),
                                    ),
                                    TextButton(
                                      onPressed: () => _reject(ad),
                                      child: Text(
                                        l10n.reject,
                                        style: const TextStyle(
                                          color: MaekelColors.danger,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await ref
                                            .read(marketRepositoryProvider)
                                            .suspendSeller(
                                              sellerId: ad.sellerId,
                                              suspended: true,
                                              note: l10n.marketSuspendedFromOps,
                                            );
                                        await _load();
                                      },
                                      child: Text(AppLocalizations.of(context)!.marketOpsSuspendSeller),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 18),
                      Text(
                        AppLocalizations.of(context)!
                            .marketOpsReports(queue?.reports.length ?? 0)
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (queue == null || queue.reports.isEmpty)
                        GlassPanel(
                          child: Text(AppLocalizations.of(context)!.marketOpsNoReports),
                        )
                      else
                        for (final report in queue.reports) ...[
                          GlassPanel(
                            accent: MaekelColors.coral,
                            borderRadius: 18,
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.adTitle,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  report.reason,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () => context.push(
                                        '${AppRoutes.market}/ads/${report.adId}',
                                      ),
                                      child: Text(AppLocalizations.of(context)!.marketOpsOpenAd),
                                    ),
                                    TextButton(
                                      onPressed: () => _resolveReport(
                                        report,
                                        action: 'dismiss',
                                      ),
                                      child: Text(AppLocalizations.of(context)!.dismiss),
                                    ),
                                    TextButton(
                                      onPressed: () => _resolveReport(
                                        report,
                                        action: 'unpublish',
                                      ),
                                      child: Text(AppLocalizations.of(context)!.marketOpsUnpublish),
                                    ),
                                    TextButton(
                                      onPressed: () => _resolveReport(
                                        report,
                                        action: 'suspend',
                                      ),
                                      child: Text(
                                        l10n.suspend,
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
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 18),
                      Text(
                        AppLocalizations.of(context)!
                            .marketOpsSuspendedSellers(
                              queue?.suspendedSellers.length ?? 0,
                            )
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (queue == null || queue.suspendedSellers.isEmpty)
                        GlassPanel(
                          child: Text(
                            AppLocalizations.of(context)!.marketOpsNoSuspended,
                          ),
                        )
                      else
                        for (final seller in queue.suspendedSellers) ...[
                          GlassPanel(
                            accent: MaekelColors.danger,
                            borderRadius: 16,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        seller.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        seller.phoneE164,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(marketRepositoryProvider)
                                          .suspendSeller(
                                            sellerId: seller.id,
                                            suspended: false,
                                          );
                                      await _load();
                                    } on ApiException catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(e.message)),
                                      );
                                    }
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .marketOpsReinstateSeller,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 18),
                      Text(
                        AppLocalizations.of(context)!
                            .marketOpsCategories(categories.length)
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onPressed: _addCategory,
                          child: Text(
                            AppLocalizations.of(context)!.marketOpsAddCategory,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (categories.isEmpty)
                        GlassPanel(
                          child: Text(l10n.marketOpsNoCategories),
                        )
                      else
                        for (final category in categories) ...[
                          GlassPanel(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: MaekelColors.signal
                                      .withValues(alpha: 0.15),
                                  child: Icon(
                                    _iconFor(category.iconName),
                                    color: MaekelColors.signal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        l10n.marketCategoryMeta(
                                          category.id,
                                          category.iconName,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _editCategory(category),
                                  child: Text(AppLocalizations.of(context)!.edit),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 8),
                      Text(
                        l10n.marketOpsLimits.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      GlassPanel(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.marketOpsMaxFreeAds,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    l10n.marketCurrentPerSeller(
                                      _config?.maxActiveFreeAds ?? '—',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _editMaxActiveAds,
                              child: Text(AppLocalizations.of(context)!.edit),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'phone':
        return Icons.phone_android_rounded;
      case 'devices':
        return Icons.devices_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'chair':
        return Icons.chair_rounded;
      case 'checkroom':
        return Icons.checkroom_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'work':
        return Icons.work_outline_rounded;
      case 'pets':
        return Icons.pets_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
