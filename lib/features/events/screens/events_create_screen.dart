import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../components/events_shell.dart';
import '../models/events_models.dart';
import '../providers/events_providers.dart';

class EventsCreateScreen extends ConsumerStatefulWidget {
  const EventsCreateScreen({super.key, this.editEventId});

  final String? editEventId;

  @override
  ConsumerState<EventsCreateScreen> createState() => _EventsCreateScreenState();
}

class _EventsCreateScreenState extends ConsumerState<EventsCreateScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _venue = TextEditingController();
  final _address = TextEditingController();
  final _capacity = TextEditingController(text: '50');
  final _price = TextEditingController(text: '0');
  final _picker = ImagePicker();
  final List<_LocalPhoto> _photos = [];

  String? _categoryId;
  String? _subcity;
  DateTime _startsAt = DateTime.now().add(const Duration(days: 2));
  EventPaymentMode _payment = EventPaymentMode.free;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  static const _maxPhotos = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(eventsRepositoryProvider).refreshCatalog());
      final id = widget.editEventId;
      if (id == null) return;
      final e = ref.read(eventsRepositoryProvider).getEvent(id);
      if (e == null) return;
      _title.text = e.title;
      _description.text = e.description;
      _venue.text = e.venueName;
      _address.text = e.venueAddress;
      _capacity.text = '${e.capacity}';
      _price.text = '${e.priceEtb}';
      setState(() {
        _categoryId = e.categoryId;
        _subcity = e.subcity;
        _startsAt = e.startsAt;
        _payment = e.paymentMode;
        _photos
          ..clear()
          ..addAll(e.displayImageUrls.map(_LocalPhoto.remote));
      });
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _venue.dispose();
    _address.dispose();
    _capacity.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pick(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventsMaxPhotos)),
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
    final repo = ref.read(eventsRepositoryProvider);
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

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final cats = ref.read(eventsCategoriesProvider);
    final categoryId = _categoryId ?? (cats.isNotEmpty ? cats.first.id : null);
    final subcity = _subcity ??
        (ref.read(eventsSubcitiesProvider).isNotEmpty
            ? ref.read(eventsSubcitiesProvider).first
            : null);
    if (categoryId == null || subcity == null) {
      setState(() => _error = l10n.eventsCategoriesNotLoaded);
      return;
    }
    final capacity = int.tryParse(_capacity.text.trim()) ?? 0;
    final price = int.tryParse(_price.text.trim()) ?? 0;
    if (_title.text.trim().length < 3 || _venue.text.trim().length < 2) {
      setState(() => _error = l10n.eventsTitleVenueRequired);
      return;
    }
    if (capacity < 1) {
      setState(() => _error = l10n.eventsCapacityMin);
      return;
    }

    setState(() {
      _saving = true;
      _uploading = _photos.isNotEmpty;
      _error = null;
    });
    try {
      final imageUrls = await _uploadAll();
      if (mounted) setState(() => _uploading = false);
      final repo = ref.read(eventsRepositoryProvider);
      final payment = price > 0 ? EventPaymentMode.payAtDoor : _payment;
      if (widget.editEventId != null) {
        await repo.updateEvent(
          widget.editEventId!,
          categoryId: categoryId,
          title: _title.text.trim(),
          description: _description.text.trim(),
          venueName: _venue.text.trim(),
          venueAddress: _address.text.trim(),
          subcity: subcity,
          startsAt: _startsAt,
          capacity: capacity,
          priceEtb: price,
          paymentMode: payment,
          imageUrls: imageUrls,
        );
      } else {
        await repo.createEvent(
          categoryId: categoryId,
          title: _title.text.trim(),
          description: _description.text.trim(),
          venueName: _venue.text.trim(),
          venueAddress: _address.text.trim(),
          subcity: subcity,
          startsAt: _startsAt,
          capacity: capacity,
          priceEtb: price,
          paymentMode: payment,
          imageUrls: imageUrls,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventsSubmitted)),
      );
      context.go(AppRoutes.eventsMine);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(eventsCategoriesProvider);
    final subcities = ref.watch(eventsSubcitiesProvider);
    final l10n = AppLocalizations.of(context)!;

    return EventsShell(
      title: widget.editEventId == null
          ? l10n.eventsCreate
          : l10n.eventsEditTitle,
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Text(
            l10n.eventsPhotosOptional,
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
                                    errorBuilder: (_, _, _) =>
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
                                color: MaekelColors.events,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.cover.toUpperCase(),
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
                if (_photos.length < _maxPhotos)
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
                                  title: Text(l10n.gallery),
                                  onTap: () {
                                    Navigator.pop(context);
                                    unawaited(_pick(ImageSource.gallery));
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_camera_outlined),
                                  title: Text(l10n.camera),
                                  onTap: () {
                                    Navigator.pop(context);
                                    unawaited(_pick(ImageSource.camera));
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
                          l10n.marketAdd,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: l10n.eventsFieldTitle),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.eventsFieldDescription),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _categoryId ??
                (categories.isNotEmpty ? categories.first.id : null),
            dropdownColor: MaekelColors.panel,
            decoration: InputDecoration(labelText: l10n.eventsFieldCategory),
            items: [
              for (final c in categories)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _subcity ?? (subcities.isNotEmpty ? subcities.first : null),
            dropdownColor: MaekelColors.panel,
            decoration: InputDecoration(labelText: l10n.eventsFieldSubcity),
            items: [
              for (final s in subcities)
                DropdownMenuItem(
                  value: s,
                  child: Text(localizedPlace(l10n, s)),
                ),
            ],
            onChanged: (v) => setState(() => _subcity = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _venue,
            decoration: InputDecoration(labelText: l10n.eventsFieldVenue),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: InputDecoration(labelText: l10n.eventsFieldAddress),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.eventsStarts),
            subtitle: Text(_startsAt.toLocal().toString()),
            trailing: TextButton(
              onPressed: _pickDateTime,
              child: Text(l10n.eventsPick),
            ),
          ),
          TextField(
            controller: _capacity,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.eventsFieldCapacity),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.eventsFieldPrice),
            onChanged: (v) {
              final n = int.tryParse(v) ?? 0;
              setState(() {
                _payment = n > 0
                    ? EventPaymentMode.payAtDoor
                    : EventPaymentMode.free;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            _payment == EventPaymentMode.payAtDoor
                ? l10n.eventsPayAtDoor
                : l10n.eventsFreeRsvp,
            style: const TextStyle(color: MaekelColors.muted),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: MaekelColors.danger)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
                    widget.editEventId == null
                        ? l10n.eventsSubmitReview
                        : l10n.save,
                  ),
          ),
        ],
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
