import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _doorId = TextEditingController();

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
    _doorId.dispose();
    super.dispose();
  }

  String _doorPrefsKey(String eventId) => 'events.doorId.$eventId';

  Future<void> _loadDoorId(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_doorPrefsKey(eventId)) ?? '';
    if (!mounted) return;
    _doorId.text = saved;
  }

  Future<void> _persistDoorId(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_doorPrefsKey(eventId), _doorId.text.trim());
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
      await _loadDoorId(event.id);
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

  Future<void> _doCheckIn(String eventId, {String? ticketId}) async {
    final door = _doorId.text.trim();
    if (door.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.eventsDoorIdRequired),
        ),
      );
      return;
    }
    final code = _checkIn.text.trim();
    if (ticketId == null && code.isEmpty) return;
    try {
      await _persistDoorId(eventId);
      await ref.read(eventsRepositoryProvider).checkIn(
            eventId,
            ticketCode: ticketId == null ? code : null,
            ticketId: ticketId,
            doorId: door,
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

  Future<void> _completeEvent(MaekelEvent event) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MaekelColors.panel,
          title: Text(l10n.eventsComplete),
          content: Text(l10n.eventsCompleteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.eventsComplete),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      await ref.read(eventsRepositoryProvider).updateEventStatus(
            event.id,
            status: EventStatus.ended,
          );
      if (_expandedId == event.id) {
        setState(() => _expandedId = null);
      }
      await _load(silent: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventsCompleted)),
      );
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
    final l10n = AppLocalizations.of(context)!;

    return EventsShell(
      title: l10n.eventsNavHost,
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
                  l10n.eventsNotHosted,
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
                            '${e.status.localized(l10n)} · ${e.ticketsSold}/${e.capacity} · ${localizedPlace(l10n, e.subcity)}',
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
                                child: Text(l10n.edit),
                              ),
                              TextButton(
                                onPressed: () => _openAttendees(e),
                                child: Text(l10n.eventsAttendees),
                              ),
                              if (e.status == EventStatus.approved)
                                TextButton(
                                  onPressed: () => _completeEvent(e),
                                  child: Text(l10n.eventsComplete),
                                ),
                              if (e.status == EventStatus.approved ||
                                  e.status == EventStatus.pending)
                                TextButton(
                                  onPressed: () => _cancelEvent(e),
                                  child: Text(l10n.cancel),
                                ),
                            ],
                          ),
                          if (open) ...[
                            const SizedBox(height: 8),
                            if (e.checkInCode != null)
                              Text(
                                l10n.eventsDoorCode(e.checkInCode ?? ''),
                                style: const TextStyle(
                                  color: MaekelColors.events,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.eventsDoorIdHelp,
                              style: const TextStyle(
                                color: MaekelColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _doorId,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: l10n.eventsDoorIdLabel,
                                hintText: l10n.eventsDoorIdHint,
                              ),
                              onChanged: (_) => unawaited(_persistDoorId(e.id)),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _checkIn,
                              decoration: InputDecoration(
                                labelText: l10n.eventsTicketCode,
                                hintText: l10n.eventsTicketHint,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: () => _doCheckIn(e.id),
                              child: Text(l10n.eventsCheckIn),
                            ),
                            const SizedBox(height: 12),
                            ..._attendees.map(
                              (a) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(a.ticketCode),
                                subtitle: Text(
                                  [
                                    l10n.eventsTicketQtyStatus(
                                      a.qty,
                                      a.status.localized(l10n),
                                    ),
                                    if (a.doorId != null &&
                                        a.doorId!.trim().isNotEmpty)
                                      l10n.eventsCheckedInAtDoor(a.doorId!),
                                  ].join(' · '),
                                ),
                                trailing: a.status == TicketStatus.reserved
                                    ? IconButton(
                                        icon: const Icon(Icons.done),
                                        onPressed: () => _doCheckIn(
                                          e.id,
                                          ticketId: a.id,
                                        ),
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
