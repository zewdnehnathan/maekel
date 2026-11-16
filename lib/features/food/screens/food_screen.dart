import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';

class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchants = ref.watch(foodMerchantsProvider);
    final kind = ref.watch(foodKindFilterProvider);
    final cart = ref.watch(foodCartProvider);

    return FoodShell(
      title: 'Food',
      actions: [
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
            'Deliver in Addis',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Restaurants & groceries · COD · OTP handover',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) =>
                ref.read(foodQueryProvider.notifier).state = v,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: const InputDecoration(
              hintText: 'Search merchants or dishes…',
              prefixIcon: Icon(Icons.search_rounded, color: MaekelColors.food),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _KindChip(
                label: 'All',
                selected: kind == null,
                onTap: () =>
                    ref.read(foodKindFilterProvider.notifier).state = null,
              ),
              _KindChip(
                label: 'Restaurants',
                selected: kind == MerchantKind.restaurant,
                onTap: () => ref.read(foodKindFilterProvider.notifier).state =
                    MerchantKind.restaurant,
              ),
              _KindChip(
                label: 'Groceries',
                selected: kind == MerchantKind.grocery,
                onTap: () => ref.read(foodKindFilterProvider.notifier).state =
                    MerchantKind.grocery,
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...merchants.map((m) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: m.isOpen
                    ? () => context.push('${AppRoutes.food}/merchant/${m.id}')
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
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${m.kind.label} · ${m.subcity} · ★ ${m.rating}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.isOpen
                                    ? '${m.etaMinutes} min · ${m.deliveryFeeEtb} ${AppConstants.currencyCode} fee'
                                    : 'Closed · ${m.hoursLabel}',
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
