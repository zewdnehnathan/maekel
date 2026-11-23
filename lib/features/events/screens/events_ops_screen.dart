import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/events_shell.dart';
import '../models/events_models.dart';
import '../providers/events_providers.dart';

class EventsOpsScreen extends ConsumerStatefulWidget {
  const EventsOpsScreen({super.key});

  @override
  ConsumerState<EventsOpsScreen> createState() => _EventsOpsScreenState();
}

class _EventsOpsScreenState extends ConsumerState<EventsOpsScreen> {
  Timer? _poll;
  EventsOpsQueue? _queue;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load(silent: false));
    });
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_busy && mounted) unawaited(_load(silent: true));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
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
      final queue = await ref.read(eventsRepositoryProvider).getOpsQueue();
      if (!mounted) return;
      setState(() {
        _queue = queue;
        if (!silent) _busy = false;
      });
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

  Future<void> _setStatus(
    MaekelEvent event,
    EventStatus status, {
    String? reason,
  }) async {
    try {
      await ref.read(eventsRepositoryProvider).updateEventStatus(
            event.id,
            status: status,
            reason: reason,
          );
      await _load(silent: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _reject(MaekelEvent event) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MaekelColors.panel,
          title: const Text('Reject event'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await _setStatus(
      event,
      EventStatus.rejected,
      reason: controller.text.trim().isEmpty
          ? 'Does not meet guidelines'
          : controller.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue;

    return EventsShell(
      title: 'Events ops',
      showBottomNav: false,
      child: RefreshIndicator(
        onRefresh: () => _load(silent: false),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: MaekelColors.danger)),
            if (_busy && queue == null)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (queue != null) ...[
              Text(
                'Pending (${queue.pending.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (queue.pending.isEmpty)
                const Text(
                  'Queue clear.',
                  style: TextStyle(color: MaekelColors.muted),
                )
              else
                ...queue.pending.map(
                  (e) => _OpsCard(
                    event: e,
                    onApprove: () => _setStatus(e, EventStatus.approved),
                    onReject: () => _reject(e),
                    onCancel: () => _setStatus(e, EventStatus.cancelled),
                    onSuspend: () async {
                      await ref
                          .read(eventsRepositoryProvider)
                          .suspendOrganizer(e.organizerId);
                      await _load(silent: false);
                    },
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Live (${queue.live.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...queue.live.map(
                (e) => _OpsCard(
                  event: e,
                  onApprove: null,
                  onReject: null,
                  onCancel: () => _setStatus(e, EventStatus.cancelled),
                  onSuspend: () async {
                    await ref
                        .read(eventsRepositoryProvider)
                        .suspendOrganizer(e.organizerId);
                    await _load(silent: false);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpsCard extends StatelessWidget {
  const _OpsCard({
    required this.event,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
    required this.onSuspend,
  });

  final MaekelEvent event;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback onCancel;
  final VoidCallback onSuspend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${event.subcity} · ${event.venueName} · ${event.organizerPhone}',
                style: const TextStyle(color: MaekelColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                '${event.startsAt.toLocal()} · ${event.ticketsSold}/${event.capacity}',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  if (onApprove != null)
                    FilledButton(
                      onPressed: onApprove,
                      child: const Text('Approve'),
                    ),
                  if (onReject != null)
                    OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Reject'),
                    ),
                  TextButton(onPressed: onCancel, child: const Text('Force cancel')),
                  TextButton(
                    onPressed: onSuspend,
                    child: const Text('Suspend organizer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
