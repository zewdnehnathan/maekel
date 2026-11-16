import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/market_shell.dart';
import '../models/market_models.dart';
import '../providers/market_providers.dart';

class MarketAdDetailScreen extends ConsumerWidget {
  const MarketAdDetailScreen({super.key, required this.adId});

  final String adId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ad = ref.watch(marketAdProvider(adId));
    final userId = ref.watch(marketUserIdProvider);
    final favorites = ref.watch(favoriteIdsProvider);

    if (ad == null) {
      return const MarketShell(
        title: 'Ad',
        showBottomNav: false,
        child: Center(child: Text('Ad not found')),
      );
    }

    final seller = ref.watch(marketSellerProvider(ad.sellerId));
    final isMine = userId != null && ad.sellerId == userId;
    final isFavorite = favorites.contains(ad.id);

    return MarketShell(
      title: 'Listing',
      showBottomNav: false,
      actions: [
        IconButton(
          onPressed: userId == null
              ? null
              : () => ref
                  .read(marketRepositoryProvider)
                  .toggleFavorite(userId, ad.id),
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? MaekelColors.coral : MaekelColors.signal,
          ),
        ),
        IconButton(
          onPressed: userId == null
              ? null
              : () => _report(context, ref, userId, ad.id),
          icon: const Icon(Icons.flag_outlined, color: MaekelColors.amber),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 11,
              child: Image.network(
                ad.photoUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: MaekelColors.panelLift,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_format(ad.priceEtb)} ${AppConstants.currencyCode}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: MaekelColors.signal,
                  fontSize: 32,
                ),
          ),
          const SizedBox(height: 6),
          Text(ad.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${ad.subcity}, ${ad.locationLabel} · ${ad.condition.label}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          GlassPanel(
            accent: MaekelColors.amber,
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Text(
              'Safety: Meet in public. Inspect before paying. Never send deposits to strangers.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MaekelColors.amber,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text('DETAILS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(ad.description, style: Theme.of(context).textTheme.bodyLarge),
          if (ad.attributes.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...ad.attributes.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        e.key,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text('SELLER', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          GlassPanel(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: MaekelColors.signal.withValues(alpha: 0.2),
                  child: Text(
                    _initial(seller?.name),
                    style: const TextStyle(color: MaekelColors.signal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller?.name ?? 'Seller',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        seller?.locationLabel ?? ad.locationLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!isMine) ...[
            FilledButton.icon(
              onPressed: userId == null
                  ? null
                  : () async {
                      try {
                        final thread = await ref
                            .read(marketRepositoryProvider)
                            .openOrCreateThread(adId: ad.id, buyerId: userId);
                        if (context.mounted) {
                          context.push(
                            '${AppRoutes.marketMessages}/${thread.id}',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.chat_rounded),
              label: const Text('CHAT WITH SELLER'),
            ),
            const SizedBox(height: 10),
            if (seller != null && seller.showPhone)
              OutlinedButton.icon(
                onPressed: () => _call(seller.phoneE164),
                icon: const Icon(Icons.call_rounded),
                label: Text('CALL ${seller.phoneE164}'),
              )
            else if (seller != null)
              Text(
                'Seller hid their phone. Use chat.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ] else
            Text(
              'This is your listing.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  String _initial(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  String _format(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _report(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String adId,
  ) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MaekelColors.panel,
          title: const Text('Report listing'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: const InputDecoration(
              hintText: 'Spam, scam, prohibited item…',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await ref.read(marketRepositoryProvider).reportAd(
            adId: adId,
            reporterId: userId,
            reason: controller.text,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report sent to ops.')),
        );
      }
    }
  }
}
