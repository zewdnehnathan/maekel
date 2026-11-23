import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
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

  String? _categoryId;
  String? _subcity;
  DateTime _startsAt = DateTime.now().add(const Duration(days: 2));
  EventPaymentMode _payment = EventPaymentMode.free;
  bool _saving = false;
  String? _error;

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

  Future<void> _save() async {
    final cats = ref.read(eventsCategoriesProvider);
    final categoryId = _categoryId ?? (cats.isNotEmpty ? cats.first.id : null);
    final subcity = _subcity ??
        (ref.read(eventsSubcitiesProvider).isNotEmpty
            ? ref.read(eventsSubcitiesProvider).first
            : null);
    if (categoryId == null || subcity == null) {
      setState(() => _error = 'Categories/areas not loaded yet.');
      return;
    }
    final capacity = int.tryParse(_capacity.text.trim()) ?? 0;
    final price = int.tryParse(_price.text.trim()) ?? 0;
    if (_title.text.trim().length < 3 || _venue.text.trim().length < 2) {
      setState(() => _error = 'Title and venue are required.');
      return;
    }
    if (capacity < 1) {
      setState(() => _error = 'Capacity must be at least 1.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
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
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submitted for review — Events ops must approve.'),
        ),
      );
      context.go(AppRoutes.eventsMine);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(eventsCategoriesProvider);
    final subcities = ref.watch(eventsSubcitiesProvider);

    return EventsShell(
      title: widget.editEventId == null ? 'Host event' : 'Edit event',
      showBottomNav: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _categoryId ??
                (categories.isNotEmpty ? categories.first.id : null),
            dropdownColor: MaekelColors.panel,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final c in categories)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _subcity ??
                (subcities.isNotEmpty ? subcities.first : null),
            dropdownColor: MaekelColors.panel,
            decoration: const InputDecoration(labelText: 'Subcity'),
            items: [
              for (final s in subcities)
                DropdownMenuItem(value: s, child: Text(s)),
            ],
            onChanged: (v) => setState(() => _subcity = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _venue,
            decoration: const InputDecoration(labelText: 'Venue name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Address (optional)'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Starts'),
            subtitle: Text(_startsAt.toLocal().toString()),
            trailing: TextButton(
              onPressed: _pickDateTime,
              child: const Text('Pick'),
            ),
          ),
          TextField(
            controller: _capacity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Capacity'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price ETB (0 = free)',
            ),
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
                ? 'Guests pay at the door (COD-style).'
                : 'Free RSVP.',
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
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.editEventId == null ? 'Submit for review' : 'Save'),
          ),
        ],
      ),
    );
  }
}
