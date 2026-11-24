import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key});

  static const _pins = [
    'Bole',
    'CMC',
    'Kirkos',
    'Yeka',
    'Kazanchis',
    'Arada',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchants = ref.watch(foodMerchantsProvider);
    final kind = ref.watch(foodKindFilterProvider);
    final cart = ref.watch(foodCartProvider);
    final pin = ref.watch(foodCoverageSubcityProvider);
    final session = ref.watch(authProvider).session;

    final l10n = AppLocalizations.of(context)!;

    return FoodShell(
      title: l10n.foodTitle,
      actions: [
        if (session?.isFoodMerchant == true)
          IconButton(
            tooltip: AppLocalizations.of(context)!.foodMerchantConsole,
            onPressed: () => context.push(AppRoutes.foodMerchantConsole),
            icon: const Icon(Icons.storefront_outlined),
            color: MaekelColors.food,
          ),
        if (session?.isFoodRider == true)
          IconButton(
            tooltip: AppLocalizations.of(context)!.foodRider,
            onPressed: () => context.push(AppRoutes.foodRider),
            icon: const Icon(Icons.delivery_dining_outlined),
            color: MaekelColors.food,
          ),
        if (session?.isFoodOps == true)
          IconButton(
            tooltip: AppLocalizations.of(context)!.foodOps,
            onPressed: () => context.push(AppRoutes.foodOps),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            color: MaekelColors.food,
          ),
        if (!cart.isEmpty)
          IconButton(
            onPressed: () => context.push(AppRoutes.foodCart),
            icon: Badge(
              label: Text('${cart.lines.fold<int>(0, (s, l) => s + l.quantity)}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            color: MaekelColors.food,
          ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            l10n.foodSubtitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.foodBlurb,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.foodDeliveryPin.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _pins)
                _KindChip(
                  label: localizedPlace(l10n, p),
                  selected: pin == p,
                  onTap: () =>
                      ref.read(foodCoverageSubcityProvider.notifier).state = p,
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) =>
                ref.read(foodQueryProvider.notifier).state = v,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.foodSearchHint,
              prefixIcon: Icon(Icons.search_rounded, color: MaekelColors.food),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _KindChip(
                label: AppLocalizations.of(context)!.all,
                selected: kind == null,
                onTap: () =>
                    ref.read(foodKindFilterProvider.notifier).state = null,
              ),
              _KindChip(
                label: AppLocalizations.of(context)!.foodRestaurants,
                selected: kind == MerchantKind.restaurant,
                onTap: () => ref.read(foodKindFilterProvider.notifier).state =
                    MerchantKind.restaurant,
              ),
              _KindChip(
                label: AppLocalizations.of(context)!.foodGroceries,
                selected: kind == MerchantKind.grocery,
                onTap: () => ref.read(foodKindFilterProvider.notifier).state =
                    MerchantKind.grocery,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (merchants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 40,
                    color: MaekelColors.muted.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.foodNoMerchants(
                      localizedPlace(l10n, pin ?? ''),
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.foodTryOtherPin,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            ...merchants.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: m.isOpen
                      ? () =>
                          context.push('${AppRoutes.food}/merchant/${m.id}')
                      : null,
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: MaekelColors.panel.withValues(alpha: 0.88),
                      border: Border.all(
                        color: m.isOpen
                            ? MaekelColors.glassBorder
                            : MaekelColors.muted.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(18),
                          ),
                          child: Image.network(
                            m.coverUrl,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 96,
                              height: 96,
                              color: MaekelColors.panelLift,
                              child: const Icon(Icons.storefront),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${m.kind.localized(AppLocalizations.of(context)!)} · ${localizedPlace(l10n, m.subcity)} · ★ ${m.rating}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.isOpen
                                      ? l10n.foodEtaFee(
                                          m.etaMinutes,
                                          m.deliveryFeeEtb,
                                        )
                                      : l10n.foodClosedHours(m.hoursLabel),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: m.isOpen
                                            ? MaekelColors.food
                                            : MaekelColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? MaekelColors.food.withValues(alpha: 0.16)
              : MaekelColors.panel,
          border: Border.all(
            color: selected
                ? MaekelColors.food.withValues(alpha: 0.5)
                : MaekelColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? MaekelColors.food : MaekelColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
