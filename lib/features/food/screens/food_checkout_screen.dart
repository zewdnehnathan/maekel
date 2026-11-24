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
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

class FoodCheckoutScreen extends ConsumerStatefulWidget {
  const FoodCheckoutScreen({super.key});

  @override
  ConsumerState<FoodCheckoutScreen> createState() => _FoodCheckoutScreenState();
}

class _FoodCheckoutScreenState extends ConsumerState<FoodCheckoutScreen> {
  static const _subcityOptions = [
    'Bole',
    'Kirkos',
    'Yeka',
    'CMC',
    'Kazanchis',
    'Arada',
  ];

  final _notes = TextEditingController();
  late final TextEditingController _label;
  late final TextEditingController _details;
  String _subcity = 'Bole';
  String? _selectedPlaceId;
  List<SavedPlace> _places = const [];
  bool _submitting = false;
  bool _savingPlace = false;

  @override
  void initState() {
    super.initState();
    final l10n = AppLocalizations.of(context)!;
    _label = TextEditingController(text: l10n.foodHomeLabel);
    _details = TextEditingController();
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
      final saveL10n = AppLocalizations.of(context)!;
      final place = await ref.read(foodRepositoryProvider).savePlace(
            label: _label.text.trim().isEmpty
                ? saveL10n.foodSavedLabel
                : _label.text.trim(),
            subcity: _subcity,
            details: _details.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _places = [place, ..._places.where((p) => p.id != place.id)];
        _selectedPlaceId = place.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.foodAddressSaved)),
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
      final snackL10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            snackL10n.foodNoDeliverPin(localizedPlace(snackL10n, _subcity)),
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
              label: _label.text.trim().isEmpty
                  ? AppLocalizations.of(context)!.foodHomeLabel
                  : _label.text.trim(),
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

    final l10n = AppLocalizations.of(context)!;

    return FoodShell(
      title: l10n.foodCheckout,
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GlassPanel(
            accent: MaekelColors.food,
            child: Text(
              l10n.foodCodBlurb,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.foodSavedPlaces.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          if (_places.isEmpty)
            Text(
              l10n.foodNoSavedPlaces,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _places)
                  ChoiceChip(
                    label: Text(
                      '${p.label} · ${localizedPlace(l10n, p.subcity)}',
                    ),
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
            decoration: InputDecoration(labelText: l10n.foodLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _subcity,
            dropdownColor: MaekelColors.panel,
            decoration: InputDecoration(labelText: l10n.foodSubcity),
            items: [
              for (final s in _subcityOptions)
                DropdownMenuItem(
                  value: s,
                  child: Text(localizedPlace(l10n, s)),
                ),
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
            decoration: InputDecoration(labelText: l10n.foodAddressDetails),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _savingPlace ? null : _saveCurrentPlace,
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: Text(
                _savingPlace ? l10n.foodSaving : l10n.foodSaveAddress,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            style: const TextStyle(color: MaekelColors.ink),
            decoration: InputDecoration(
              labelText: l10n.foodNotesRider,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.foodPaymentCod,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.foodCheckoutSummary(
              cart.subtotalEtb,
              fee,
              cart.subtotalEtb + fee,
            ),
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
                : Text(l10n.foodPlaceOrderEtb(cart.subtotalEtb + fee)),
          ),
        ],
      ),
    );
  }
}
