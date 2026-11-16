import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';

class FoodOrderDetailScreen extends ConsumerStatefulWidget {
  const FoodOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<FoodOrderDetailScreen> createState() =>
      _FoodOrderDetailScreenState();
}

class _FoodOrderDetailScreenState extends ConsumerState<FoodOrderDetailScreen> {
  final _otp = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(foodOrderProvider(widget.orderId));
    final repo = ref.watch(foodRepositoryProvider);

    if (order == null) {
      return const FoodShell(
        title: 'Order',
        showBottomNav: false,
        child: Center(child: Text('Order not found')),
      );
    }

    final merchant = repo.getMerchant(order.merchantId);

    return FoodShell(
      title: 'Order ${order.id}',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GlassPanel(
            accent: MaekelColors.food,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status.label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: MaekelColors.food,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  merchant?.name ?? 'Merchant',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${order.address.subcity} · ${order.address.details}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total ${order.grandTotalEtb} ETB · COD',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: MaekelColors.food,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('ITEMS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ...order.lines.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${l.quantity}× ${l.item.name} — ${l.lineTotal} ETB',
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
                  'Delivery OTP',
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
                  'Show this code to the rider. Delivered only after OTP.',
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
              child: const Text('CANCEL ORDER'),
            ),
          if (order.status == OrderStatus.onTheWay ||
              order.status == OrderStatus.pickedUp) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otp,
              style: const TextStyle(color: MaekelColors.ink, letterSpacing: 4),
              decoration: const InputDecoration(
                labelText: 'Rider enters customer OTP',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: MaekelColors.food,
                foregroundColor: MaekelColors.ink,
              ),
              onPressed: () async {
                try {
                  await ref.read(foodRepositoryProvider).completeWithOtp(
                        orderId: order.id,
                        otp: _otp.text,
                      );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              child: const Text('CONFIRM DELIVERY (OTP)'),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: order.status == OrderStatus.delivered ||
                    order.status == OrderStatus.cancelled
                ? null
                : () => ref.read(foodRepositoryProvider).advanceOrder(order.id),
            child: const Text('Demo: advance status'),
          ),
        ],
      ),
    );
  }
}
