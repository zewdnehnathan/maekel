import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
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
  final _label = TextEditingController(text: 'Home');
  final _details = TextEditingController(text: 'Near Edna Mall, gate 2');
  String _subcity = 'Bole';
  String? _selectedPlaceId;
  List<SavedPlace> _places = const [];
  bool _submitting = false;
  bool _savingPlace = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaces());
    final pin = ref.read(foodCoverageSubcityProvider);
    if (pin != null) _subcity = pin;
  }

  Future<void> _loadPlaces() async {
    try {
      final places =
          await ref.read(foodRepositoryProvider).refreshPlaces();
      if (!mounted) return;
      setState(() => _places = places);
    } catch (_) {}
  }

  @override
  void dispose() {
    _notes.dispose();
    _label.dispose();
    _details.dispose();
    super.dispose();
  }

  void _applyPlace(SavedPlace place) {
    setState(() {
      _selectedPlaceId = place.id;
      _label.text = place.label;
      _subcity = place.subcity;
      _details.text = place.details;
    });
  }

  Future<void> _saveCurrentPlace() async {
    setState(() => _savingPlace = true);
    try {
      final place = await ref.read(foodRepositoryProvider).savePlace(
            label: _label.text.trim().isEmpty ? 'Saved' : _label.text.trim(),
            subcity: _subcity,
            details: _details.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _places = [place, ..._places.where((p) => p.id != place.id)];
        _selectedPlaceId = place.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved')),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPlace = false);
    }
  }

  Future<void> _place() async {
    final userId = ref.read(foodUserIdProvider);
    final cart = ref.read(foodCartProvider);
    final merchant = cart.merchantId == null
        ? null
        : ref.read(foodMerchantProvider(cart.merchantId!));
    if (userId == null || merchant == null) return;

    if (!merchant.covers(_subcity)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${merchant.name} does not deliver to $_subcity. Change pin or merchant.',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final order = await ref.read(foodRepositoryProvider).placeOrder(
            customerId: userId,
            address: DeliveryAddress(
              label: _label.text.trim().isEmpty ? 'Home' : _label.text.trim(),
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
          Text(
            'SAVED PLACES',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          if (_places.isEmpty)
            Text(
              'No saved places yet — fill address below and tap Save.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _places)
                  ChoiceChip(
                    label: Text('${p.label} · ${p.subcity}'),
                    selected: _selectedPlaceId == p.id,
                    onSelected: (_) => _applyPlace(p),
                    selectedColor: MaekelColors.food.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: _selectedPlaceId == p.id
                          ? MaekelColors.food
                          : MaekelColors.ink,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _label,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          const SizedBox(height: 12),
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
              DropdownMenuItem(value: 'Kazanchis', child: Text('Kazanchis')),
              DropdownMenuItem(value: 'Arada', child: Text('Arada')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _subcity = v;
                  _selectedPlaceId = null;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _details,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: const InputDecoration(labelText: 'Address details'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _savingPlace ? null : _saveCurrentPlace,
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: Text(_savingPlace ? 'Saving…' : 'Save this address'),
            ),
          ),
          const SizedBox(height: 8),
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
