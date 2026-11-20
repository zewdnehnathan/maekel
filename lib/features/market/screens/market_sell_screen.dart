import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../components/market_safety_banner.dart';
import '../components/market_shell.dart';
import '../models/market_models.dart';
import '../providers/market_providers.dart';

class MarketSellScreen extends ConsumerStatefulWidget {
  const MarketSellScreen({super.key, this.editAdId});

  final String? editAdId;

  @override
  ConsumerState<MarketSellScreen> createState() => _MarketSellScreenState();
}

class _MarketSellScreenState extends ConsumerState<MarketSellScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _brand = TextEditingController();
  final _spec = TextEditingController();
  final _extraKey = TextEditingController();
  final _extraValue = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  String? _categoryId;
  String? _subcity;
  AdCondition _condition = AdCondition.used;
  bool _submitting = false;
  bool _uploading = false;
  final List<_LocalPhoto> _photos = [];

  bool get _isEdit => widget.editAdId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEdit());
    }
  }

  void _loadEdit() {
    final ad = ref.read(marketRepositoryProvider).getAd(widget.editAdId!);
    if (ad == null) return;
    _title.text = ad.title;
    _description.text = ad.description;
    _price.text = '${ad.priceEtb}';
    final specKey = _specLabelFor(ad.categoryId);
    _brand.text = ad.attributes['Brand'] ?? '';
    _spec.text = ad.attributes[specKey] ?? '';
    final extra = ad.attributes.entries
        .where((e) => e.key != 'Brand' && e.key != specKey)
        .toList();
    if (extra.isNotEmpty) {
      _extraKey.text = extra.first.key;
      _extraValue.text = extra.first.value;
    }
    setState(() {
      _categoryId = ad.categoryId;
      _subcity = ad.subcity;
      _condition = ad.condition;
      _photos
        ..clear()
        ..addAll(ad.photoUrls.map((u) => _LocalPhoto.remote(u)));
    });
  }

  String _specLabelFor(String? categoryId) {
    switch (categoryId) {
      case 'phones':
        return 'Storage';
      case 'vehicles':
        return 'Year';
      case 'property':
        return 'Type';
      case 'electronics':
        return 'Size';
      default:
        return 'Spec';
    }
  }

  Map<String, String> _buildAttributes() {
    final attrs = <String, String>{};
    final brand = _brand.text.trim();
    final spec = _spec.text.trim();
    final extraKey = _extraKey.text.trim();
    final extraValue = _extraValue.text.trim();
    if (brand.isNotEmpty) attrs['Brand'] = brand;
    if (spec.isNotEmpty) attrs[_specLabelFor(_categoryId)] = spec;
    if (extraKey.isNotEmpty && extraValue.isNotEmpty) {
      attrs[extraKey] = extraValue;
    }
    return attrs;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _brand.dispose();
    _spec.dispose();
    _extraKey.dispose();
    _extraValue.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_photos.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 8 photos.')),
      );
      return;
    }
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _photos.add(
        _LocalPhoto.local(
          bytes: bytes,
          filename: file.name.isEmpty ? 'photo.jpg' : file.name,
          contentType: _guessContentType(file.name),
        ),
      );
    });
  }

  String _guessContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<List<String>> _uploadAll() async {
    final repo = ref.read(marketRepositoryProvider);
    final urls = <String>[];
    for (final photo in _photos) {
      if (photo.remoteUrl != null) {
        urls.add(photo.remoteUrl!);
        continue;
      }
      final url = await repo.uploadPhoto(
        bytes: photo.bytes!,
        filename: photo.filename!,
        contentType: photo.contentType!,
      );
      urls.add(url);
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null || _subcity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a category and area.')),
      );
      return;
    }
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one photo.')),
      );
      return;
    }
    final userId = ref.read(marketUserIdProvider);
    if (userId == null) return;

    setState(() {
      _submitting = true;
      _uploading = true;
    });
    try {
      final photoUrls = await _uploadAll();
      setState(() => _uploading = false);
      final repo = ref.read(marketRepositoryProvider);
      final attributes = _buildAttributes();
      if (_isEdit) {
        await repo.updateAd(
          widget.editAdId!,
          categoryId: _categoryId!,
          title: _title.text,
          description: _description.text,
          priceEtb: int.parse(_price.text.replaceAll(',', '')),
          condition: _condition,
          subcity: _subcity!,
          photoUrls: photoUrls,
          attributes: attributes,
        );
      } else {
        await repo.createAd(
          sellerId: userId,
          categoryId: _categoryId!,
          title: _title.text,
          description: _description.text,
          priceEtb: int.parse(_price.text.replaceAll(',', '')),
          condition: _condition,
          subcity: _subcity!,
          photoUrls: photoUrls,
          attributes: attributes,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Updated — pending review again.'
                : 'Submitted for moderation. You’ll be notified when reviewed.',
          ),
        ),
      );
      context.go(AppRoutes.marketMyAds);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(marketCategoriesProvider);
    final subcities = ref.watch(marketSubcitiesProvider);

    return MarketShell(
      title: _isEdit ? 'Edit ad' : 'Sell',
      showBottomNav: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const MarketSafetyBanner(message: MarketSafetyCopy.shortTip),
            const SizedBox(height: 16),
            Text('PHOTOS', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 104,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < _photos.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 104,
                              height: 104,
                              child: _photos[i].remoteUrl != null
                                  ? Image.network(
                                      _photos[i].remoteUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const ColoredBox(
                                        color: MaekelColors.panelLift,
                                        child: Icon(Icons.broken_image_outlined),
                                      ),
                                    )
                                  : Image.memory(
                                      _photos[i].bytes!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          if (i == 0)
                            Positioned(
                              left: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: MaekelColors.signal,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'COVER',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: MaekelColors.voidBlack,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  setState(() => _photos.removeAt(i)),
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: MaekelColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_photos.length < 8)
                    OutlinedButton(
                      onPressed: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: MaekelColors.panel,
                          builder: (context) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_library_outlined),
                                    title: const Text('Gallery'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pick(ImageSource.gallery);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_camera_outlined),
                                    title: const Text('Camera'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pick(ImageSource.camera);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(104, 104),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined),
                          SizedBox(height: 6),
                          Text('Add', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                ],
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
              onChanged: (v) => setState(() {
                _categoryId = v;
                // Keep typed spec; label updates with category.
              }),
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
            const SizedBox(height: 16),
            Text(
              'KEY DETAILS',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _brand,
              style: const TextStyle(color: MaekelColors.ink),
              decoration: const InputDecoration(
                labelText: 'Brand',
                hintText: 'e.g. Apple, Toyota',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _spec,
              style: const TextStyle(color: MaekelColors.ink),
              decoration: InputDecoration(
                labelText: _specLabelFor(_categoryId),
                hintText: switch (_categoryId) {
                  'phones' => 'e.g. 128GB',
                  'vehicles' => 'e.g. 2019',
                  'property' => 'e.g. Rent / Sale',
                  'electronics' => 'e.g. 55 inch',
                  _ => 'Main spec',
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _extraKey,
                    style: const TextStyle(color: MaekelColors.ink),
                    decoration: const InputDecoration(
                      labelText: 'Extra detail name',
                      hintText: 'e.g. Color',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _extraValue,
                    style: const TextStyle(color: MaekelColors.ink),
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      hintText: 'e.g. Black',
                    ),
                  ),
                ),
              ],
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
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                        const SizedBox(width: 12),
                        Text(_uploading ? 'Uploading photos…' : 'Submitting…'),
                      ],
                    )
                  : Text(_isEdit ? 'SAVE & RE-SUBMIT' : 'SUBMIT FOR REVIEW'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalPhoto {
  const _LocalPhoto._({
    this.remoteUrl,
    this.bytes,
    this.filename,
    this.contentType,
  });

  factory _LocalPhoto.remote(String url) => _LocalPhoto._(remoteUrl: url);

  factory _LocalPhoto.local({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) {
    return _LocalPhoto._(
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  final String? remoteUrl;
  final Uint8List? bytes;
  final String? filename;
  final String? contentType;
}
