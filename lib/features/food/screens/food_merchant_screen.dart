import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';

class FoodMerchantScreen extends ConsumerWidget {
  const FoodMerchantScreen({super.key, required this.merchantId});

  final String merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchant = ref.watch(foodMerchantProvider(merchantId));
    final menu = ref.watch(foodMenuProvider(merchantId));
    final cart = ref.watch(foodCartProvider);

    if (merchant == null) {
      return const FoodShell(
        title: 'Merchant',
        showBottomNav: false,
        child: Center(child: Text('Not found')),
      );
    }

    return FoodShell(
      title: merchant.name,
      showBottomNav: false,
      floatingActionButton: cart.merchantId == merchantId && !cart.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.foodCart),
              backgroundColor: MaekelColors.food,
              foregroundColor: MaekelColors.ink,
              label: Text(
                'CART · ${cart.subtotalEtb} ${AppConstants.currencyCode}',
              ),
            )
          : null,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              merchant.coverUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: MaekelColors.panelLift,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${merchant.subcity} · ${merchant.hoursLabel} · min ${merchant.minOrderEtb} ETB',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('MENU', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          ...menu.map((item) {
            final unavailable = !item.available;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Opacity(
                opacity: unavailable ? 0.55 : 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  tileColor: MaekelColors.panel.withValues(alpha: 0.85),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: unavailable
                          ? MaekelColors.danger.withValues(alpha: 0.45)
                          : MaekelColors.glassBorder,
                    ),
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.photoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: MaekelColors.panelLift,
                      ),
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    unavailable
                        ? 'Unavailable\n${item.priceEtb} ${AppConstants.currencyCode}'
                        : '${item.description}\n${item.priceEtb} ${AppConstants.currencyCode}',
                  ),
                  isThreeLine: true,
                  trailing: unavailable
                      ? Text(
                          'Unavailable',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: MaekelColors.danger,
                                  ),
                        )
                      : IconButton.filled(
                          onPressed: () => _addItem(context, ref, item),
                          style: IconButton.styleFrom(
                            backgroundColor: MaekelColors.food,
                            foregroundColor: MaekelColors.ink,
                          ),
                          icon: const Icon(Icons.add_rounded),
                        ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _addItem(
    BuildContext context,
    WidgetRef ref,
    MenuItem item,
  ) async {
    var selected = <String>{};
    if (item.modifiers.isNotEmpty) {
      final result = await showModalBottomSheet<Set<String>>(
        context: context,
        backgroundColor: MaekelColors.panel,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModal) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Customize ${item.name}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...item.modifiers.map((m) {
                        final on = selected.contains(m.id);
                        return CheckboxListTile(
                          value: on,
                          title: Text('${m.name} (+${m.priceEtb} ETB)'),
                          activeColor: MaekelColors.food,
                          onChanged: (v) {
                            setModal(() {
                              if (v == true) {
                                selected = {...selected, m.id};
                              } else {
                                selected = {...selected}..remove(m.id);
                              }
                            });
                          },
                        );
                      }),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, selected),
                        child: const Text('ADD TO CART'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
      if (result == null) return;
      selected = result;
    }

    try {
      await ref.read(foodRepositoryProvider).addToCart(
            item: item,
            quantity: 1,
            modifierIds: selected.toList(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} added')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: MaekelColors.panel,
          title: const Text('Replace cart?'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear & add'),
            ),
          ],
        ),
      );
      if (clear == true) {
        await ref.read(foodRepositoryProvider).clearCart();
        await ref.read(foodRepositoryProvider).addToCart(
              item: item,
              quantity: 1,
              modifierIds: selected.toList(),
            );
      }
    }
  }
}
