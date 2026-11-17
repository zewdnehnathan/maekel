import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
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
  bool _loading = true;
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
      final queue = await ref.read(marketRepositoryProvider).getOpsQueue();
      if (!mounted) return;
      setState(() {
        _queue = queue;
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
    await ref.read(marketRepositoryProvider).updateAdStatus(
          ad.id,
          status: AdStatus.approved,
        );
    await _load();
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
      await ref.read(marketRepositoryProvider).updateAdStatus(
            ad.id,
            status: AdStatus.rejected,
            rejectReason: controller.text.trim(),
          );
      await _load();
    }
  }

  Future<void> _resolveReport(
    MarketReportItem report, {
    required String action,
  }) async {
    await ref.read(marketRepositoryProvider).resolveReport(
          reportId: report.id,
          action: action,
          note: action == 'dismiss' ? 'Dismissed' : null,
        );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue;

    return MarketShell(
      title: 'Ops',
      showBottomNav: false,
      actions: [
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
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ad.priceEtb} ${AppConstants.currencyCode} · ${ad.subcity}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ad.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                                              note: 'Suspended from ops queue',
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
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  report.reason,
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                    ],
                  ),
                ),
    );
  }
}
