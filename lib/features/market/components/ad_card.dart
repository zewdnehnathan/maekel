import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../models/market_models.dart';

class AdCard extends StatelessWidget {
  const AdCard({
    super.key,
    required this.ad,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  final MarketAd ad;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: MaekelColors.panel.withValues(alpha: 0.85),
            border: Border.all(color: MaekelColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Image.network(
                        ad.photoUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: MaekelColors.panelLift,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: MaekelColors.muted,
                          ),
                        ),
                      ),
                    ),
                    if (onFavoriteTap != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor:
                                MaekelColors.voidBlack.withValues(alpha: 0.55),
                          ),
                          onPressed: onFavoriteTap,
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? MaekelColors.coral
                                : MaekelColors.ink,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatPrice(ad.priceEtb)} ${AppConstants.currencyCode}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: MaekelColors.signal,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ad.subcity} · ${ad.condition.label}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}
