import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';
import '../services/api_food_repository.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

class FoodOrderDetailScreen extends ConsumerStatefulWidget {
  const FoodOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<FoodOrderDetailScreen> createState() =>
      _FoodOrderDetailScreenState();
}

class _FoodOrderDetailScreenState extends ConsumerState<FoodOrderDetailScreen> {
  Future<void> _refresh() async {
    final repo = ref.read(foodRepositoryProvider);
    if (repo is ApiFoodRepository) {
      await repo.refreshAuthed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(foodOrderProvider(widget.orderId));
    final repo = ref.watch(foodRepositoryProvider);

    final l10n = AppLocalizations.of(context)!;

    if (order == null) {
      return FoodShell(
        title: l10n.foodOrderTitle,
        showBottomNav: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.4,
                child: Center(child: Text(l10n.foodOrderNotFound)),
              ),
            ],
          ),
        ),
      );
    }

    final merchant = repo.getMerchant(order.merchantId);

    return FoodShell(
      title: '${l10n.foodOrderTitle} ${order.id}',
      showBottomNav: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GlassPanel(
            accent: MaekelColors.food,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status.localized(l10n).toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: MaekelColors.food,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  merchant?.name ?? l10n.foodMerchantTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${localizedPlace(AppLocalizations.of(context)!, order.address.subcity)} · ${order.address.details}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.foodTotalCod(order.grandTotalEtb),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: MaekelColors.food,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.foodItems.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          ...order.lines.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                l10n.foodOrderLine(l.quantity, l.item.name, l.lineTotal),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            accent: MaekelColors.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.foodDeliveryOtp,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  order.deliveryOtp,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        letterSpacing: 6,
                        color: MaekelColors.amber,
                        fontSize: 36,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.foodDeliveryOtpHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (order.canCancel)
            OutlinedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(foodRepositoryProvider)
                      .cancelOrder(order.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              child: Text(l10n.foodCancelOrder),
            )
          else if (order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled)
            GlassPanel(
              accent: MaekelColors.danger,
              child: Text(
                l10n.foodCannotCancel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (ref.watch(authProvider).session?.isFoodOps == true) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: order.status == OrderStatus.delivered ||
                      order.status == OrderStatus.cancelled
                  ? null
                  : () =>
                      ref.read(foodRepositoryProvider).advanceOrder(order.id),
              child: Text(
                order.status == OrderStatus.onTheWay
                    ? AppLocalizations.of(context)!.foodOpsMarkDelivered
                    : AppLocalizations.of(context)!.foodOpsForceAdvance,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}
