import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/market_shell.dart';
import '../models/market_models.dart';
import '../providers/market_providers.dart';

class MarketSellScreen extends ConsumerStatefulWidget {
  const MarketSellScreen({super.key});

  @override
  ConsumerState<MarketSellScreen> createState() => _MarketSellScreenState();
}

class _MarketSellScreenState extends ConsumerState<MarketSellScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _categoryId;
  String? _subcity;
  AdCondition _condition = AdCondition.used;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null || _subcity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a category and area.')),
      );
      return;
    }
    final userId = ref.read(marketUserIdProvider);
    if (userId == null) return;

    setState(() => _submitting = true);
    try {
      final ad = await ref.read(marketRepositoryProvider).createAd(
            sellerId: userId,
            categoryId: _categoryId!,
            title: _title.text,
            description: _description.text,
            priceEtb: int.parse(_price.text.replaceAll(',', '')),
            condition: _condition,
            subcity: _subcity!,
            photoUrls: const [],
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submitted for moderation. Auto-approves in ~4s.'),
        ),
      );
      context.go(AppRoutes.marketMyAds);
      // Keep analyzer happy that ad was created.
      assert(ad.id.isNotEmpty);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(marketCategoriesProvider);
    final subcities = ref.watch(marketSubcitiesProvider);

    return MarketShell(
      title: 'Sell',
      showBottomNav: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            GlassPanel(
              accent: MaekelColors.signal,
              child: Text(
                'Photos use a placeholder for now. Moderation required before the ad goes live.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _categoryId,
              dropdownColor: MaekelColors.panel,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              style: const TextStyle(color: MaekelColors.ink),
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  (v == null || v.trim().length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              style: const TextStyle(color: MaekelColors.ink),
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => (v == null || v.trim().length < 20)
                  ? 'Min 20 characters'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              style: const TextStyle(color: MaekelColors.ink),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (ETB)',
                prefixText: 'ETB ',
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').replaceAll(',', ''));
                if (n == null || n <= 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AdCondition>(
              // ignore: deprecated_member_use
              value: _condition,
              dropdownColor: MaekelColors.panel,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: [
                for (final c in AdCondition.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _condition = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _subcity,
              dropdownColor: MaekelColors.panel,
              decoration: const InputDecoration(labelText: 'Subcity'),
              items: [
                for (final s in subcities)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _subcity = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Text('SUBMIT FOR REVIEW'),
            ),
          ],
        ),
      ),
    );
  }
}
