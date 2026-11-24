import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';
import '../../../l10n/app_localizations.dart';

class FoodOrdersScreen extends ConsumerWidget {
  const FoodOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(foodOrdersProvider);
    final repo = ref.watch(foodRepositoryProvider);

    final l10n = AppLocalizations.of(context)!;

    return FoodShell(
      title: l10n.foodOrdersTitle,
      child: orders.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.foodNoOrders))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = orders[index];
                final merchant = repo.getMerchant(order.merchantId);
                return InkWell(
                  onTap: () =>
                      context.push('${AppRoutes.foodOrders}/${order.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: GlassPanel(
                    borderRadius: 16,
                    accent: MaekelColors.food,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                merchant?.name ?? l10n.foodMerchantTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              order.status.localized(AppLocalizations.of(context)!).toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontSize: 10,
                                    color: MaekelColors.food,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.foodOrderSummary(
                            order.grandTotalEtb,
                            order.lines.length,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
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
