import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';

class FoodCheckoutScreen extends ConsumerStatefulWidget {
  const FoodCheckoutScreen({super.key});

  @override
  ConsumerState<FoodCheckoutScreen> createState() => _FoodCheckoutScreenState();
}

class _FoodCheckoutScreenState extends ConsumerState<FoodCheckoutScreen> {
  final _notes = TextEditingController();
  String _subcity = 'Bole';
  final _details = TextEditingController(text: 'Near Edna Mall, gate 2');
  bool _submitting = false;

  @override
  void dispose() {
    _notes.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    final userId = ref.read(foodUserIdProvider);
    final cart = ref.read(foodCartProvider);
    final merchant = cart.merchantId == null
        ? null
        : ref.read(foodMerchantProvider(cart.merchantId!));
    if (userId == null || merchant == null) return;

    setState(() => _submitting = true);
    try {
      final order = await ref.read(foodRepositoryProvider).placeOrder(
            customerId: userId,
            address: DeliveryAddress(
              label: 'Home',
              subcity: _subcity,
              details: _details.text.trim(),
            ),
            notes: _notes.text,
          );
      if (!mounted) return;
      context.go('${AppRoutes.foodOrders}/${order.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(foodCartProvider);
    final merchant = cart.merchantId == null
        ? null
        : ref.watch(foodMerchantProvider(cart.merchantId!));
    final fee = merchant?.deliveryFeeEtb ?? 0;

    return FoodShell(
      title: 'Checkout',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GlassPanel(
            accent: MaekelColors.food,
            child: Text(
              'Pay cash on delivery. Delivery fee shown before you confirm — no surprises.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _subcity,
            dropdownColor: MaekelColors.panel,
            decoration: const InputDecoration(labelText: 'Subcity'),
            items: const [
              DropdownMenuItem(value: 'Bole', child: Text('Bole')),
              DropdownMenuItem(value: 'Kirkos', child: Text('Kirkos')),
              DropdownMenuItem(value: 'Yeka', child: Text('Yeka')),
              DropdownMenuItem(value: 'CMC', child: Text('CMC')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _subcity = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _details,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: const InputDecoration(labelText: 'Address details'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: const InputDecoration(
              labelText: 'Notes for rider / kitchen',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment: Cash on delivery (COD)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Subtotal ${cart.subtotalEtb} ETB + delivery $fee ETB = ${cart.subtotalEtb + fee} ETB',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MaekelColors.food,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: MaekelColors.food,
              foregroundColor: MaekelColors.ink,
            ),
            onPressed: _submitting ? null : _place,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text('PLACE ORDER · ${cart.subtotalEtb + fee} ETB'),
          ),
        ],
      ),
    );
  }
}
