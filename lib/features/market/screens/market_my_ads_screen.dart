import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/market_shell.dart';
import '../models/market_models.dart';
import '../providers/market_providers.dart';

class MarketMyAdsScreen extends ConsumerStatefulWidget {
  const MarketMyAdsScreen({super.key});

  @override
  ConsumerState<MarketMyAdsScreen> createState() => _MarketMyAdsScreenState();
}

class _MarketMyAdsScreenState extends ConsumerState<MarketMyAdsScreen> {
  MarketSeller? _seller;
  List<SellerNotification> _notes = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSellerBits());
  }

  Future<void> _loadSellerBits() async {
    try {
      final repo = ref.read(marketRepositoryProvider);
      final seller = await repo.getMySeller();
      final notes = await repo.getNotifications();
      if (!mounted) return;
      setState(() {
        _seller = seller;
        _notes = notes;
      });
    } catch (_) {}
  }

  Future<void> _togglePhone(bool value) async {
    final seller = await ref.read(marketRepositoryProvider).updateMySeller(
          showPhone: value,
        );
    if (!mounted) return;
    setState(() => _seller = seller);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Phone visible on your ads (rate-limited).'
              : 'Phone hidden — buyers use chat only.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(myAdsProvider);
    final unread = _notes.where((n) => n.isUnread).length;

    return MarketShell(
      title: 'My ads',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.marketOps),
          icon: const Icon(Icons.admin_panel_settings_outlined),
          color: MaekelColors.amber,
          tooltip: 'Ops queue',
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.marketSell),
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: MaekelColors.signal,
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GlassPanel(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show phone on ads'),
              subtitle: Text(
                _seller == null
                    ? 'Call CTA for buyers (daily limit applies)'
                    : 'Number: ${_seller!.phoneE164}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: _seller?.showPhone ?? true,
              onChanged: _seller == null ? null : _togglePhone,
              activeThumbColor: MaekelColors.signal,
            ),
          ),
          if (_notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              unread > 0 ? 'UPDATES ($unread new)' : 'UPDATES',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            for (final note in _notes.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassPanel(
                  accent: note.isUnread
                      ? MaekelColors.signal
                      : MaekelColors.muted,
                  borderRadius: 14,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note.body,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          if (ads.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Text(
                    'No ads yet',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Post something to sell in Addis.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push(AppRoutes.marketSell),
                    child: const Text('SELL NOW'),
                  ),
                ],
              ),
            )
          else
            for (final ad in ads) ...[
              GlassPanel(
                borderRadius: 18,
                padding: const EdgeInsets.all(14),
                accent: switch (ad.status) {
                  AdStatus.approved => MaekelColors.signal,
                  AdStatus.pending => MaekelColors.amber,
                  AdStatus.rejected => MaekelColors.danger,
                  AdStatus.sold => MaekelColors.muted,
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ad.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          ad.status.label.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 10,
                                    color: switch (ad.status) {
                                      AdStatus.approved => MaekelColors.signal,
                                      AdStatus.pending => MaekelColors.amber,
                                      AdStatus.rejected => MaekelColors.danger,
                                      AdStatus.sold => MaekelColors.muted,
                                    },
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ad.priceEtb} ${AppConstants.currencyCode} · ${ad.subcity}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (ad.rejectReason != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Reason: ${ad.rejectReason}',
                        style: const TextStyle(color: MaekelColors.danger),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => context
                              .push('${AppRoutes.market}/ads/${ad.id}'),
                          child: const Text('Open'),
                        ),
                        if (ad.status != AdStatus.sold)
                          TextButton(
                            onPressed: () => context.push(
                              '${AppRoutes.marketSell}?edit=${ad.id}',
                            ),
                            child: const Text('Edit'),
                          ),
                        if (ad.status == AdStatus.approved)
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(marketRepositoryProvider)
                                  .updateAdStatus(
                                    ad.id,
                                    status: AdStatus.sold,
                                  );
                            },
                            child: const Text('Mark sold'),
                          ),
                        TextButton(
                          onPressed: () {
                            ref.read(marketRepositoryProvider).deleteAd(ad.id);
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: MaekelColors.danger),
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
    );
  }
}
