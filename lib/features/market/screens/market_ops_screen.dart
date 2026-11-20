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
          title: const Text('Reject ad'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: const InputDecoration(
              hintText: 'Reason shown to seller…',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
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
            note: action == 'dismiss' ? 'Dismissed' : null,
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
              title: const Text('Add category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: MaekelColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        hintText: 'e.g. Babies & Kids',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: idController,
                      style: const TextStyle(color: MaekelColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Id (optional)',
                        hintText: 'auto from name if empty',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: iconName,
                      dropdownColor: MaekelColors.panel,
                      decoration: const InputDecoration(labelText: 'Icon key'),
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
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Add'),
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
        const SnackBar(content: Text('Name must be at least 2 characters.')),
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
        SnackBar(content: Text('Added “${created.name}”.')),
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
              title: Text('Edit ${category.id}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: MaekelColors.ink),
                    decoration: const InputDecoration(labelText: 'Display name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: iconName,
                    dropdownColor: MaekelColors.panel,
                    decoration: const InputDecoration(labelText: 'Icon key'),
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
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
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
        const SnackBar(content: Text('Name must be at least 2 characters.')),
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
        SnackBar(content: Text('Updated “$name”.')),
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
          title: const Text('Max active free ads'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: const InputDecoration(
              labelText: 'Limit (1–50)',
              helperText: 'Per seller: approved + pending count',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
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
        const SnackBar(content: Text('Enter a number between 1 and 50.')),
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
        SnackBar(content: Text('Max active ads set to $value.')),
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

    return MarketShell(
      title: 'Ops',
      showBottomNav: false,
      actions: [
        if (isPlatformAdmin)
          IconButton(
            onPressed: () => context.push(AppRoutes.adminStaff),
            icon: const Icon(Icons.group_outlined),
            color: MaekelColors.amber,
            tooltip: 'Staff & admins',
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
                        'PENDING ADS (${queue?.pendingAds.length ?? 0})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (queue == null || queue.pendingAds.isEmpty)
                        const GlassPanel(
                          child: Text('Queue empty — nothing to moderate.'),
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
                                Text(
                                  ad.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ad.priceEtb} ${AppConstants.currencyCode} · ${ad.subcity}',
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
                                      onPressed: () => context.push(
                                        '${AppRoutes.market}/ads/${ad.id}',
                                      ),
                                      child: const Text('Open'),
                                    ),
                                    FilledButton(
                                      onPressed: () => _approve(ad),
                                      child: const Text('Approve'),
                                    ),
                                    TextButton(
                                      onPressed: () => _reject(ad),
                                      child: const Text(
                                        'Reject',
                                        style: TextStyle(
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
                                              note:
                                                  'Suspended from ops queue',
                                            );
                                        await _load();
                                      },
                                      child: const Text('Suspend seller'),
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
                        'OPEN REPORTS (${queue?.reports.length ?? 0})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (queue == null || queue.reports.isEmpty)
                        const GlassPanel(
                          child: Text('No open reports.'),
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
                                      child: const Text('Open ad'),
                                    ),
                                    TextButton(
                                      onPressed: () => _resolveReport(
                                        report,
                                        action: 'dismiss',
                                      ),
                                      child: const Text('Dismiss'),
                                    ),
                                    TextButton(
                                      onPressed: () => _resolveReport(
                                        report,
                                        action: 'unpublish',
                                      ),
                                      child: const Text('Unpublish'),
                                    ),
                                    TextButton(
                                      onPressed: () => _resolveReport(
                                        report,
                                        action: 'suspend',
                                      ),
                                      child: const Text(
                                        'Suspend',
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
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'CATEGORY CONFIG (${categories.length})',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: _addCategory,
                            child: const Text('Add category'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (categories.isEmpty)
                        const GlassPanel(
                          child: Text(
                            'No categories yet. Add the first one to unlock Sell.',
                          ),
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
                                        'id: ${category.id} · icon: ${category.iconName}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _editCategory(category),
                                  child: const Text('Edit'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 8),
                      Text(
                        'LIMITS',
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
                                    'Max active free ads',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    'Current: ${_config?.maxActiveFreeAds ?? '—'} per seller',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _editMaxActiveAds,
                              child: const Text('Edit'),
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
