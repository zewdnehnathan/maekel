import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';
import '../components/events_shell.dart';
import '../models/events_models.dart';
import '../providers/events_providers.dart';
import '../services/api_events_repository.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _busy = false;
  String? _error;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  Future<void> _ensureLoaded() async {
    final existing = ref.read(eventsRepositoryProvider).getEvent(widget.eventId);
    if (existing != null) return;
    final repo = ref.read(eventsRepositoryProvider);
    if (repo is ApiEventsRepository) {
      try {
        await repo.fetchEvent(widget.eventId);
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = '$e');
      }
    }
  }

  Future<void> _rsvp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ticket = await ref.read(eventsRepositoryProvider).rsvp(
            widget.eventId,
            qty: _qty,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RSVP confirmed · ${ticket.ticketCode}')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      await ref.read(eventsRepositoryProvider).cancelRsvp(widget.eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RSVP cancelled')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventProvider(widget.eventId));
    final session = ref.watch(authProvider).session;
    final myTickets = ref.watch(myEventTicketsProvider);
    final mine = myTickets.where((t) => t.eventId == widget.eventId).toList();
    final isOwner = session != null && event?.organizerId == session.userId;

    return EventsShell(
      title: 'Event',
      showBottomNav: false,
      child: event == null
          ? Center(
              child: _error != null
                  ? Text(_error!, style: const TextStyle(color: MaekelColors.danger))
                  : const CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${event.categoryName} · ${event.subcity}',
                  style: const TextStyle(color: MaekelColors.muted),
                ),
                const SizedBox(height: 16),
                GlassPanel(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row(Icons.schedule, _formatWhen(event.startsAt)),
                        const SizedBox(height: 8),
                        _row(Icons.place_outlined, event.venueName),
                        if (event.venueAddress.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.venueAddress,
                            style: const TextStyle(color: MaekelColors.muted),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _row(Icons.payments_outlined, event.priceLabel),
                        const SizedBox(height: 8),
                        _row(
                          Icons.event_seat_outlined,
                          event.isSoldOut
                              ? 'Sold out'
                              : '${event.seatsLeft} of ${event.capacity} left',
                        ),
                        const SizedBox(height: 8),
                        _row(
                          Icons.person_outline,
                          event.organizerName.isEmpty
                              ? 'Organizer'
                              : event.organizerName,
                        ),
                      ],
                    ),
                  ),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: MaekelColors.danger)),
                ],
                const SizedBox(height: 20),
                if (mine.isNotEmpty) ...[
                  GlassPanel(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your ticket',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mine.first.ticketCode,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: MaekelColors.events),
                          ),
                          Text('Qty ${mine.first.qty} · ${mine.first.status.name}'),
                          if (mine.first.status == TicketStatus.reserved) ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _busy ? null : _cancel,
                              child: const Text('Cancel RSVP'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else if (!isOwner && event.status == EventStatus.approved) ...[
                  Row(
                    children: [
                      const Text('Qty'),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _qty <= 1
                            ? null
                            : () => setState(() => _qty--),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_qty'),
                      IconButton(
                        onPressed: _qty >= 10
                            ? null
                            : () => setState(() => _qty++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _busy || event.isSoldOut ? null : _rsvp,
                    child: Text(
                      event.isSoldOut
                          ? 'Sold out'
                          : event.isFree
                              ? 'RSVP free'
                              : 'RSVP · pay at door',
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: MaekelColors.events),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

String _formatWhen(DateTime dt) {
  final local = dt.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
