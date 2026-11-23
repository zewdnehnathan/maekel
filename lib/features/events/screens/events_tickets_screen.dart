import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../components/events_shell.dart';
import '../providers/events_providers.dart';

class EventsTicketsScreen extends ConsumerStatefulWidget {
  const EventsTicketsScreen({super.key});

  @override
  ConsumerState<EventsTicketsScreen> createState() =>
      _EventsTicketsScreenState();
}

class _EventsTicketsScreenState extends ConsumerState<EventsTicketsScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(eventsRepositoryProvider).refreshAuthed());
    });
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        unawaited(ref.read(eventsRepositoryProvider).refreshAuthed());
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(myEventTicketsProvider);

    return EventsShell(
      title: 'Tickets',
      child: RefreshIndicator(
        onRefresh: () => ref.read(eventsRepositoryProvider).refreshAuthed(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            if (tickets.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  'No tickets yet. RSVP from Browse.',
                  style: TextStyle(color: MaekelColors.muted),
                ),
              )
            else
              ...tickets.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () =>
                        context.push('${AppRoutes.events}/${t.eventId}'),
                    borderRadius: BorderRadius.circular(16),
                    child: GlassPanel(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.eventTitle ?? 'Event',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.ticketCode,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: MaekelColors.events),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              [
                                if (t.venueName != null) t.venueName!,
                                if (t.subcity != null) t.subcity!,
                                'qty ${t.qty}',
                                t.status.name,
                              ].join(' · '),
                              style: const TextStyle(color: MaekelColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
