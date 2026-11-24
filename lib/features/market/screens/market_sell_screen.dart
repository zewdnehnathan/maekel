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
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

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

  String _specFieldLabel(AppLocalizations l10n, String? categoryId) {
    switch (categoryId) {
      case 'phones':
        return l10n.marketSpecStorage;
      case 'vehicles':
        return l10n.marketSpecYear;
      case 'property':
        return l10n.marketSpecType;
      case 'electronics':
        return l10n.marketSpecSize;
      default:
        return l10n.marketSpecGeneric;
    }
  }

  String _specHint(AppLocalizations l10n, String? categoryId) {
    switch (categoryId) {
      case 'phones':
        return l10n.marketSpecHintPhones;
      case 'vehicles':
        return l10n.marketSpecHintVehicles;
      case 'property':
        return l10n.marketSpecHintProperty;
      case 'electronics':
        return l10n.marketSpecHintElectronics;
      default:
        return l10n.marketSpecHintGeneric;
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
        SnackBar(content: Text(AppLocalizations.of(context)!.marketMaxPhotos)),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.marketPickCategoryArea)),
      );
      return;
    }
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.marketAddPhoto)),
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? l10n.marketUpdatedPending : l10n.marketSubmittedModeration,
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
    final l10n = AppLocalizations.of(context)!;

    return MarketShell(
      title: _isEdit ? l10n.marketEditAd : l10n.marketSellAction,
      showBottomNav: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            MarketSafetyBanner(compact: true),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.photos,
              style: Theme.of(context).textTheme.labelLarge,
            ),
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
                                child: Text(
                                  l10n.marketCover.toUpperCase(),
                                  style: const TextStyle(
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
                                    title: Text(AppLocalizations.of(context)!.gallery),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pick(ImageSource.gallery);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_camera_outlined),
                                    title: Text(AppLocalizations.of(context)!.camera),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined),
                          const SizedBox(height: 6),
                          Text(
                            AppLocalizations.of(context)!.marketAdd,
                            style: const TextStyle(fontSize: 12),
                          ),
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
              decoration: InputDecoration(
                labelText: l10n.marketCategoryTitle,
              ),
              items: [
                for (final c in categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(c.localized(l10n)),
                  ),
              ],
              onChanged: (v) => setState(() {
                _categoryId = v;
                // Keep typed spec; label updates with category.
              }),
              validator: (v) => v == null ? l10n.marketRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              style: const TextStyle(color: MaekelColors.ink),
              decoration: InputDecoration(labelText: l10n.marketFieldTitle),
              validator: (v) => (v == null || v.trim().length < 6)
                  ? l10n.marketMinChars(6)
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              style: const TextStyle(color: MaekelColors.ink),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.marketFieldDescription,
              ),
              validator: (v) => (v == null || v.trim().length < 20)
                  ? l10n.marketMinChars(20)
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              style: const TextStyle(color: MaekelColors.ink),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.marketFieldPrice,
                prefixText: '${l10n.currencyEtb} ',
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').replaceAll(',', ''));
                if (n == null || n <= 0) return l10n.marketValidPrice;
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AdCondition>(
              // ignore: deprecated_member_use
              value: _condition,
              dropdownColor: MaekelColors.panel,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.marketCondition,
              ),
              items: [
                for (final c in AdCondition.values)
                  DropdownMenuItem(value: c, child: Text(c.localized(AppLocalizations.of(context)!))),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _condition = v);
              },
            ),
            const SizedBox(height: 16),
            Text(
              l10n.marketKeyDetails.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _brand,
              style: const TextStyle(color: MaekelColors.ink),
              decoration: InputDecoration(
                labelText: l10n.marketFieldBrand,
                hintText: l10n.marketBrandHint,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _spec,
              style: const TextStyle(color: MaekelColors.ink),
              decoration: InputDecoration(
                labelText: _specFieldLabel(l10n, _categoryId),
                hintText: _specHint(l10n, _categoryId),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _extraKey,
                    style: const TextStyle(color: MaekelColors.ink),
                    decoration: InputDecoration(
                      labelText: l10n.marketExtraDetailName,
                      hintText: l10n.marketExtraDetailHint,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _extraValue,
                    style: const TextStyle(color: MaekelColors.ink),
                    decoration: InputDecoration(
                      labelText: l10n.marketExtraValue,
                      hintText: l10n.marketExtraValueHint,
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
              decoration: InputDecoration(labelText: l10n.marketFieldSubcity),
              items: [
                for (final s in subcities)
                  DropdownMenuItem(
                    value: s,
                    child: Text(localizedPlace(l10n, s)),
                  ),
              ],
              onChanged: (v) => setState(() => _subcity = v),
              validator: (v) => v == null ? l10n.marketRequired : null,
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
                        Text(
                          _uploading
                              ? l10n.marketUploadingPhotos
                              : l10n.marketSubmitting,
                        ),
                      ],
                    )
                  : Text(
                      _isEdit
                          ? l10n.marketSaveResubmit.toUpperCase()
                          : l10n.marketSubmitReview.toUpperCase(),
                    ),
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
