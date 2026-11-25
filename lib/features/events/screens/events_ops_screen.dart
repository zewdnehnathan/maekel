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
          title: Text(AppLocalizations.of(context)!.eventsReject),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.eventsReason,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.reject),
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
          ? AppLocalizations.of(context)!.eventsRejectDefault
          : controller.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue;

    return EventsShell(
      title: AppLocalizations.of(context)!.eventsOps,
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
                AppLocalizations.of(context)!.eventsPending(queue.pending.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (queue.pending.isEmpty)
                Text(
                  AppLocalizations.of(context)!.eventsQueueClear,
                  style: const TextStyle(color: MaekelColors.muted),
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
                AppLocalizations.of(context)!.eventsLive(queue.live.length),
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

  Future<void> _openDetails(BuildContext context) async {
    context.push('${AppRoutes.events}/${event.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _openDetails(context),
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: MaekelColors.signal,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${localizedPlace(l10n, event.subcity)} · ${event.venueName} · ${event.organizerPhone}',
                style: const TextStyle(color: MaekelColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                '${event.startsAt.toLocal()} · ${event.ticketsSold}/${event.capacity}',
              ),
              if (event.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  event.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => _openDetails(context),
                    child: Text(l10n.eventsOpsViewDetails),
                  ),
                  if (onApprove != null)
                    FilledButton(
                      onPressed: onApprove,
                      child: Text(l10n.approve),
                    ),
                  if (onReject != null)
                    OutlinedButton(
                      onPressed: onReject,
                      child: Text(l10n.reject),
                    ),
                  TextButton(
                    onPressed: onCancel,
                    child: Text(l10n.rideForceCancel),
                  ),
                  TextButton(
                    onPressed: onSuspend,
                    child: Text(l10n.eventsSuspendOrganizer),
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
