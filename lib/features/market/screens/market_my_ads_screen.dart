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

class MarketMyAdsScreen extends ConsumerWidget {
  const MarketMyAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(myAdsProvider);

    return MarketShell(
      title: 'My ads',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.marketSell),
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: MaekelColors.signal,
        ),
      ],
      child: ads.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: ads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ad = ads[index];
                return GlassPanel(
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
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                            onPressed: () =>
                                context.push('${AppRoutes.market}/ads/${ad.id}'),
                            child: const Text('Open'),
                          ),
                          if (ad.status == AdStatus.approved)
                            TextButton(
                              onPressed: () {
                                ref.read(marketRepositoryProvider).updateAdStatus(
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
                );
              },
            ),
    );
  }
}
