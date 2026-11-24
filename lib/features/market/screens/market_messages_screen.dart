import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/market_shell.dart';
import '../providers/market_providers.dart';
import '../../../l10n/app_localizations.dart';

class MarketMessagesScreen extends ConsumerWidget {
  const MarketMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(marketThreadsProvider);
    final repo = ref.watch(marketRepositoryProvider);
    final l10n = AppLocalizations.of(context)!;

    return MarketShell(
      title: l10n.marketMessages,
      child: threads.isEmpty
          ? Center(
              child: Text(AppLocalizations.of(context)!.marketNoChats),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: threads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final thread = threads[index];
                final ad = repo.getAd(thread.adId);
                final messages = repo.getMessages(thread.id);
                final last = messages.isEmpty ? null : messages.last;

                return InkWell(
                  onTap: () => context.push(
                    '${AppRoutes.marketMessages}/${thread.id}',
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: GlassPanel(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: MaekelColors.panelLift,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ad == null
                              ? const Icon(Icons.chat_bubble_outline)
                              : Image.network(
                                  ad.photoUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.chat_bubble_outline),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad?.title ?? l10n.marketListing,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                last?.body ?? l10n.marketStartChatting,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: MaekelColors.muted,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
