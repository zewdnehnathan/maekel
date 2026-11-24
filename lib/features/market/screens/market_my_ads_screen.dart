import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';
import '../components/market_shell.dart';
import '../models/market_models.dart';
import '../providers/market_providers.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? l10n.marketPhoneVisible : l10n.marketPhoneHidden,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(myAdsProvider);
    final unread = _notes.where((n) => n.isUnread).length;
    final isModerator =
        ref.watch(authProvider).session?.isMarketModerator ?? false;

    final l10n = AppLocalizations.of(context)!;

    return MarketShell(
      title: l10n.marketNavMyAds,
      actions: [
        if (isModerator)
          IconButton(
            onPressed: () => context.push(AppRoutes.marketOps),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            color: MaekelColors.amber,
            tooltip: AppLocalizations.of(context)!.marketOpsQueueTooltip,
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
              title: Text(AppLocalizations.of(context)!.marketShowPhone),
              subtitle: Text(
                _seller == null
                    ? l10n.marketCallCtaBuyers
                    : l10n.marketYourNumber(_seller!.phoneE164),
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
              unread > 0
                  ? l10n.marketUpdatesUnread(unread).toUpperCase()
                  : l10n.marketUpdates.toUpperCase(),
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
                    l10n.marketNoAdsYet,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.marketPostSomething,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push(AppRoutes.marketSell),
                    child: Text(AppLocalizations.of(context)!.marketSellNow),
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
                          ad.status.localized(AppLocalizations.of(context)!).toUpperCase(),
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
                      '${ad.priceEtb} ${AppConstants.currencyCode} · ${localizedPlace(AppLocalizations.of(context)!, ad.subcity)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (ad.rejectReason != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.marketRejectReason(ad.rejectReason!),
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
                          child: Text(AppLocalizations.of(context)!.open),
                        ),
                        if (ad.status != AdStatus.sold)
                          TextButton(
                            onPressed: () => context.push(
                              '${AppRoutes.marketSell}?edit=${ad.id}',
                            ),
                            child: Text(AppLocalizations.of(context)!.edit),
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
                            child: Text(AppLocalizations.of(context)!.marketMarkSold),
                          ),
                        TextButton(
                          onPressed: () {
                            ref.read(marketRepositoryProvider).deleteAd(ad.id);
                          },
                          child: Text(
                            l10n.delete,
                            style: const TextStyle(color: MaekelColors.danger),
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
