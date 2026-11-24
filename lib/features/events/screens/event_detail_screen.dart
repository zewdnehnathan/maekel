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
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

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
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .eventsRsvpConfirmed(ticket.ticketCode),
          ),
        ),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.eventsRsvpCancelled)),
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

    final l10n = AppLocalizations.of(context)!;

    return EventsShell(
      title: l10n.eventsTitle,
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
                  '${event.categoryName} · ${localizedPlace(AppLocalizations.of(context)!, event.subcity)}',
                  style: const TextStyle(color: MaekelColors.muted),
                ),
                if (event.displayImageUrls.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: PageView.builder(
                      itemCount: event.displayImageUrls.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            event.displayImageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: MaekelColors.panelLift,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (event.displayImageUrls.length > 1) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${event.displayImageUrls.length} ${l10n.eventsPhotos.toLowerCase()}',
                      style: const TextStyle(color: MaekelColors.muted),
                    ),
                  ],
                ],
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
                        _row(
                          Icons.payments_outlined,
                          event.priceLabelLocalized(l10n),
                        ),
                        const SizedBox(height: 8),
                        _row(
                          Icons.event_seat_outlined,
                          event.isSoldOut
                              ? l10n.eventsSoldOut
                              : l10n.eventsSeatsLeft(event.seatsLeft),
                        ),
                        const SizedBox(height: 8),
                        _row(
                          Icons.person_outline,
                          event.organizerName.isEmpty
                              ? l10n.eventsOrganizer
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
                            AppLocalizations.of(context)!.eventsYourTicket,
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
                          Text(
                            AppLocalizations.of(context)!.eventsTicketQtyStatus(
                              mine.first.qty,
                              mine.first.status.localized(
                                AppLocalizations.of(context)!,
                              ),
                            ),
                          ),
                          if (mine.first.status == TicketStatus.reserved) ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _busy ? null : _cancel,
                              child: Text(AppLocalizations.of(context)!.eventsCancelRsvp),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else if (!isOwner && event.status == EventStatus.approved) ...[
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.qty),
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
                          ? l10n.eventsSoldOut
                          : event.isFree
                              ? l10n.eventsRsvpFree
                              : l10n.eventsRsvpPayDoor,
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
