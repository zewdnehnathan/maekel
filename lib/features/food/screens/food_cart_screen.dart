import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../components/food_shell.dart';
import '../providers/food_providers.dart';

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

    return FoodShell(
      title: 'Cart',
      child: cart.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
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
                          '${line.unitPrice} ${AppConstants.currencyCode} each',
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
                        _row(context, 'Subtotal', '${cart.subtotalEtb} ETB'),
                        _row(context, 'Delivery fee', '$fee ETB'),
                        const SizedBox(height: 6),
                        _row(
                          context,
                          'Total',
                          '$total ETB',
                          bold: true,
                        ),
                        if (merchant != null &&
                            cart.subtotalEtb < merchant.minOrderEtb) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Min order ${merchant.minOrderEtb} ETB',
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
                          child: const Text('CHECKOUT · COD'),
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
