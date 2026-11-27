import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/food_shell.dart';
import '../models/food_models.dart';
import '../providers/food_providers.dart';

class FoodApplyScreen extends ConsumerStatefulWidget {
  const FoodApplyScreen({super.key});

  @override
  ConsumerState<FoodApplyScreen> createState() => _FoodApplyScreenState();
}

class _FoodApplyScreenState extends ConsumerState<FoodApplyScreen> {
  FoodApplicationKind _kind = FoodApplicationKind.restaurant;
  final _title = TextEditingController();
  final _subcity = TextEditingController(text: 'Bole');
  Uint8List? _licenseBytes;
  String? _licenseName;
  String? _licenseMediaId;
  bool _busy = false;
  String? _message;
  List<FoodApplication> _mine = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMine());
  }

  @override
  void dispose() {
    _title.dispose();
    _subcity.dispose();
    super.dispose();
  }

  Future<void> _loadMine() async {
    try {
      final items = await ref.read(foodRepositoryProvider).myApplications();
      if (mounted) setState(() => _mine = items);
    } catch (_) {}
  }

  Future<void> _pickLicense() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _licenseBytes = bytes;
      _licenseName = file.name;
      _licenseMediaId = null;
    });
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final subcity = _subcity.text.trim();
    if (title.length < 2 || subcity.isEmpty) {
      setState(() => _message = 'Enter a title and subcity');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final repo = ref.read(foodRepositoryProvider);
      var mediaId = _licenseMediaId;
      if (mediaId == null && _licenseBytes != null) {
        mediaId = await repo.uploadApplicationMedia(
          bytes: _licenseBytes!,
          filename: _licenseName ?? 'license.jpg',
        );
        _licenseMediaId = mediaId;
      }
      await repo.submitApplication(
        kind: _kind,
        title: title,
        subcity: subcity,
        licenseMediaId: mediaId,
      );
      if (!mounted) return;
      _title.clear();
      setState(() {
        _licenseBytes = null;
        _licenseName = null;
        _licenseMediaId = null;
        _message =
            'Submitted. Food ops will review. After approval, log out and OTP again to refresh roles.';
      });
      await _loadMine();
    } on ApiException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FoodShell(
      title: 'Partner apply',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Apply for a restaurant grant or delivery fleet. Ops will approve or reject.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MaekelColors.muted,
                ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            accent: MaekelColors.food,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<FoodApplicationKind>(
                  // ignore: deprecated_member_use
                  value: _kind,
                  decoration: const InputDecoration(labelText: 'Application type'),
                  items: const [
                    DropdownMenuItem(
                      value: FoodApplicationKind.restaurant,
                      child: Text('Restaurant merchant'),
                    ),
                    DropdownMenuItem(
                      value: FoodApplicationKind.deliveryOrg,
                      child: Text('Delivery merchant'),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v != null) setState(() => _kind = v);
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: _kind == FoodApplicationKind.restaurant
                        ? 'Restaurant name'
                        : 'Delivery company name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subcity,
                  decoration: const InputDecoration(labelText: 'Subcity'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickLicense,
                  icon: const Icon(Icons.badge_outlined),
                  label: Text(
                    _licenseBytes == null
                        ? 'Upload business license (optional)'
                        : 'License selected',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Submitting…' : 'Submit application'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MaekelColors.food,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (_mine.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'YOUR APPLICATIONS',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            for (final a in _mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassPanel(
                  accent: MaekelColors.food,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${a.kind.name} · ${a.status.name} · ${a.subcity}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (a.reviewNote != null)
                        Text(
                          a.reviewNote!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
