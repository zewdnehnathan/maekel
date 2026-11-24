import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../components/food_shell.dart';
import '../providers/food_providers.dart';
import '../../../l10n/app_localizations.dart';

class FoodCartScreen extends ConsumerWidget {
  const FoodCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(foodCartProvider);
    final merchant = cart.merchantId == null
        ? null
        : ref.watch(foodMerchantProvider(cart.merchantId!));
    final fee = merchant?.deliveryFeeEtb ?? 0;
    final total = cart.subtotalEtb + fee;

    final l10n = AppLocalizations.of(context)!;

    return FoodShell(
      title: l10n.foodCartTitle,
      child: cart.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.foodCartEmpty))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final line = cart.lines[index];
                      return ListTile(
                        tileColor: MaekelColors.panel.withValues(alpha: 0.85),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        title: Text(line.item.name),
                        subtitle: Text(
                          l10n.foodUnitPriceEach(line.unitPrice),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                ref.read(foodRepositoryProvider).updateQty(
                                      line.item.id,
                                      line.quantity - 1,
                                    );
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${line.quantity}'),
                            IconButton(
                              onPressed: () {
                                ref.read(foodRepositoryProvider).updateQty(
                                      line.item.id,
                                      line.quantity + 1,
                                    );
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: MaekelColors.deep.withValues(alpha: 0.95),
                    border: const Border(
                      top: BorderSide(color: MaekelColors.glassBorder),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        _row(
                          context,
                          l10n.foodSubtotal,
                          '${cart.subtotalEtb} ${l10n.currencyEtb}',
                        ),
                        _row(
                          context,
                          l10n.foodDeliveryFee,
                          '$fee ${l10n.currencyEtb}',
                        ),
                        const SizedBox(height: 6),
                        _row(
                          context,
                          l10n.foodTotal,
                          '$total ${l10n.currencyEtb}',
                          bold: true,
                        ),
                        if (merchant != null &&
                            cart.subtotalEtb < merchant.minOrderEtb) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.foodMinOrder(merchant.minOrderEtb),
                            style: const TextStyle(color: MaekelColors.amber),
                          ),
                        ],
                        const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: MaekelColors.food,
                            foregroundColor: MaekelColors.ink,
                          ),
                          onPressed: merchant != null &&
                                  cart.subtotalEtb >= merchant.minOrderEtb
                              ? () => context.push(AppRoutes.foodCheckout)
                              : null,
                          child: Text(l10n.foodCheckoutCod),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _row(
    BuildContext context,
    String left,
    String right, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Text(
          left,
          style: bold
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          right,
          style: bold
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MaekelColors.food,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
