import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/market_safety_banner.dart';
import '../components/market_shell.dart';
import '../models/market_models.dart';
import '../providers/market_providers.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

class MarketAdDetailScreen extends ConsumerStatefulWidget {
  const MarketAdDetailScreen({super.key, required this.adId});

  final String adId;

  @override
  ConsumerState<MarketAdDetailScreen> createState() =>
      _MarketAdDetailScreenState();
}

class _MarketAdDetailScreenState extends ConsumerState<MarketAdDetailScreen> {
  bool _loading = false;
  String? _revealedPhone;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureLoaded());
    });
  }

  Future<void> _ensureLoaded() async {
    final existing = ref.read(marketRepositoryProvider).getAd(widget.adId);
    if (existing != null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final ad =
        await ref.read(marketRepositoryProvider).fetchAd(widget.adId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (ad == null) {
        _loadError = AppLocalizations.of(context)!.marketAdNotFound;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ad = ref.watch(marketAdProvider(widget.adId));
    final userId = ref.watch(marketUserIdProvider);
    final favorites = ref.watch(favoriteIdsProvider);
    final l10n = AppLocalizations.of(context)!;

    if (ad == null) {
      return MarketShell(
        title: l10n.marketListing,
        showBottomNav: false,
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Text(_loadError ?? l10n.marketAdNotFound),
        ),
      );
    }

    final seller = ref.watch(marketSellerProvider(ad.sellerId));
    final isMine = userId != null && ad.sellerId == userId;
    final isFavorite = favorites.contains(ad.id);
    final showPhone = seller?.showPhone == true;
    final phoneOnListing = (_revealedPhone ?? seller?.phoneE164 ?? '').trim();

    return MarketShell(
      title: l10n.marketListing,
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
          SizedBox(
            height: 220,
            child: PageView.builder(
              itemCount: ad.photoUrls.isEmpty ? 1 : ad.photoUrls.length,
              itemBuilder: (context, index) {
                if (ad.photoUrls.isEmpty) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ColoredBox(
                      color: MaekelColors.panelLift,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      ad.photoUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: MaekelColors.panelLift,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                );
              },
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
            '${localizedPlace(l10n, ad.subcity)}, ${ad.locationLabel} · ${ad.condition.localized(l10n)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const MarketSafetyBanner(compact: true),
          const SizedBox(height: 16),
          Text(
            l10n.marketDetails.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
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
          Text(
            l10n.marketSeller.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
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
                        seller?.name ?? l10n.marketSeller,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        seller?.locationLabel ?? ad.locationLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (!isMine && showPhone && phoneOnListing.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.marketSellerPhone(phoneOnListing),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: MaekelColors.signal,
                              ),
                        ),
                      ],
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
                  : () => _startChat(context, ref, userId, ad.id),
              icon: const Icon(Icons.chat_rounded),
              label: Text(l10n.marketChatSeller),
            ),
            const SizedBox(height: 10),
            if (showPhone) ...[
              if (phoneOnListing.isEmpty)
                OutlinedButton.icon(
                  onPressed: userId == null
                      ? null
                      : () => _revealPhone(context, ref, ad.id, call: false),
                  icon: const Icon(Icons.phone_rounded),
                  label: Text(l10n.marketShowPhoneNumber),
                ),
              if (phoneOnListing.isEmpty) const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: userId == null
                    ? null
                    : () => _revealPhone(context, ref, ad.id, call: true),
                icon: const Icon(Icons.call_rounded),
                label: Text(l10n.marketCallSeller),
              ),
            ] else if (seller != null)
              Text(
                l10n.marketSellerHidPhone,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ] else ...[
            Text(
              l10n.marketYourListing,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (ad.status != AdStatus.sold) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () =>
                    context.push('${AppRoutes.marketSell}?edit=${ad.id}'),
                child: Text(l10n.marketEditListing),
              ),
            ],
          ],
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

  Future<void> _startChat(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String adId,
  ) async {
    final ok = await showMarketSafetyGate(context);
    if (!ok || !context.mounted) return;
    try {
      final thread = await ref
          .read(marketRepositoryProvider)
          .openOrCreateThread(adId: adId, buyerId: userId);
      if (context.mounted) {
        context.push('${AppRoutes.marketMessages}/${thread.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _revealPhone(
    BuildContext context,
    WidgetRef ref,
    String adId, {
    required bool call,
  }) async {
    final ok = await showMarketSafetyGate(context);
    if (!ok || !context.mounted) return;
    try {
      final phone =
          await ref.read(marketRepositoryProvider).revealPhone(adId);
      if (!mounted) return;
      setState(() => _revealedPhone = phone);
      if (call) {
        await launchUrl(Uri(scheme: 'tel', path: phone));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
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
          title: Text(AppLocalizations.of(context)!.marketReportListing),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.marketReportHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.submit),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.marketReportSent)),
        );
      }
    }
  }
}
