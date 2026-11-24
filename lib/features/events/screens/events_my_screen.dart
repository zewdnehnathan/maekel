import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/events_shell.dart';
import '../models/events_models.dart';
import '../providers/events_providers.dart';
import '../../../core/locale/place_l10n.dart';
import '../../../l10n/app_localizations.dart';

class EventsMyScreen extends ConsumerStatefulWidget {
  const EventsMyScreen({super.key});

  @override
  ConsumerState<EventsMyScreen> createState() => _EventsMyScreenState();
}

class _EventsMyScreenState extends ConsumerState<EventsMyScreen> {
  Timer? _poll;
  bool _busy = false;
  String? _error;
  String? _expandedId;
  List<EventAttendee> _attendees = const [];
  final _checkIn = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load(silent: false));
    });
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_busy && mounted) unawaited(_load(silent: true));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _checkIn.dispose();
    super.dispose();
  }

  Future<void> _load({required bool silent}) async {
    if (!silent) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    try {
      await ref.read(eventsRepositoryProvider).refreshAuthed();
      if (_expandedId != null) {
        _attendees = await ref
            .read(eventsRepositoryProvider)
            .getAttendees(_expandedId!);
      }
      if (!mounted) return;
      if (!silent) setState(() => _busy = false);
      if (silent) setState(() {});
    } on ApiException catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = '$e';
        _busy = false;
      });
    }
  }

  Future<void> _openAttendees(MaekelEvent event) async {
    setState(() {
      _expandedId = event.id;
      _busy = true;
    });
    try {
      _attendees =
          await ref.read(eventsRepositoryProvider).getAttendees(event.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doCheckIn(String eventId) async {
    final code = _checkIn.text.trim();
    if (code.isEmpty) return;
    try {
      await ref.read(eventsRepositoryProvider).checkIn(
            eventId,
            ticketCode: code,
          );
      _checkIn.clear();
      _attendees =
          await ref.read(eventsRepositoryProvider).getAttendees(eventId);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.eventsCheckedIn)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _cancelEvent(MaekelEvent event) async {
    try {
      await ref.read(eventsRepositoryProvider).updateEventStatus(
            event.id,
            status: EventStatus.cancelled,
          );
      await _load(silent: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(myEventsProvider);

    return EventsShell(
      title: AppLocalizations.of(context)!.eventsNavHost,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.eventsCreate),
          icon: const Icon(Icons.add),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => _load(silent: false),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: MaekelColors.danger)),
            if (_busy && mine.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (mine.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  AppLocalizations.of(context)!.eventsNotHosted,
                  style: const TextStyle(color: MaekelColors.muted),
                ),
              )
            else
              ...mine.map((e) {
                final open = _expandedId == e.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassPanel(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (e.displayImageUrls.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  e.displayImageUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const ColoredBox(
                                    color: MaekelColors.panelLift,
                                    child: Center(
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            e.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${e.status.localized(AppLocalizations.of(context)!)} · ${e.ticketsSold}/${e.capacity} · ${localizedPlace(AppLocalizations.of(context)!, e.subcity)}',
                            style: const TextStyle(color: MaekelColors.muted),
                          ),
                          if (e.rejectionReason != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              e.rejectionReason!,
                              style: const TextStyle(color: MaekelColors.danger),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => context.push(
                                  '${AppRoutes.eventsCreate}?edit=${e.id}',
                                ),
                                child: Text(AppLocalizations.of(context)!.edit),
                              ),
                              TextButton(
                                onPressed: () => _openAttendees(e),
                                child: Text(AppLocalizations.of(context)!.eventsAttendees),
                              ),
                              if (e.status == EventStatus.approved ||
                                  e.status == EventStatus.pending)
                                TextButton(
                                  onPressed: () => _cancelEvent(e),
                                  child: Text(AppLocalizations.of(context)!.cancel),
                                ),
                            ],
                          ),
                          if (open) ...[
                            const SizedBox(height: 8),
                            if (e.checkInCode != null)
                              Text(
                                AppLocalizations.of(context)!
                                    .eventsDoorCode(e.checkInCode ?? ''),
                                style: TextStyle(
                                  color: MaekelColors.events,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _checkIn,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.eventsTicketCode,
                                hintText: AppLocalizations.of(context)!
                                    .eventsTicketHint,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: () => _doCheckIn(e.id),
                              child: Text(AppLocalizations.of(context)!.eventsCheckIn),
                            ),
                            const SizedBox(height: 12),
                            ..._attendees.map(
                              (a) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(a.ticketCode),
                                subtitle: Text(
                                  AppLocalizations.of(context)!.eventsTicketQtyStatus(
                                    a.qty,
                                    a.status.localized(
                                      AppLocalizations.of(context)!,
                                    ),
                                  ),
                                ),
                                trailing: a.status == TicketStatus.reserved
                                    ? IconButton(
                                        icon: const Icon(Icons.done),
                                        onPressed: () async {
                                          await ref
                                              .read(eventsRepositoryProvider)
                                              .checkIn(
                                                e.id,
                                                ticketId: a.id,
                                              );
                                          await _openAttendees(e);
                                        },
                                      )
                                    : const Icon(
                                        Icons.check_circle,
                                        color: MaekelColors.signal,
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
