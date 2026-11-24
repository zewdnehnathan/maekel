import 'dart:async';

import '../../../core/network/api_client.dart';
import '../models/events_models.dart';
import 'events_repository.dart';

class ApiEventsRepository implements EventsRepository {
  ApiEventsRepository(this._client) {
    unawaited(refreshCatalog());
  }

  final ApiClient _client;
  final _controller = StreamController<void>.broadcast();

  List<EventCategory> _categories = const [];
  List<String> _subcities = const [
    'Bole',
    'Kirkos',
    'Yeka',
    'Lideta',
    'Nifas Silk',
    'Addis Ketema',
    'Arada',
    'Gulele',
  ];
  final Map<String, MaekelEvent> _events = {};
  List<MaekelEvent> _catalog = const [];
  List<MaekelEvent> _myEvents = const [];
  List<EventTicket> _myTickets = const [];
  EventFilters _lastFilters = const EventFilters();

  @override
  Stream<void> get changes => _controller.stream;

  void _notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  @override
  void dispose() {
    _controller.close();
  }

  @override
  List<EventCategory> getCategories() => _categories;

  @override
  List<String> getSubcities() => _subcities;

  @override
  List<MaekelEvent> getCatalog() => _catalog;

  @override
  List<MaekelEvent> getMyEvents() => _myEvents;

  @override
  List<EventTicket> getMyTickets() => _myTickets;

  @override
  MaekelEvent? getEvent(String id) => _events[id];

  @override
  Future<void> refreshCatalog({EventFilters? filters}) async {
    final f = filters ?? _lastFilters;
    _lastFilters = f;
    try {
      final catsRaw = await _client.get('/v1/events/categories');
      _categories = ((catsRaw['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (j) => EventCategory(
              id: j['id'] as String,
              name: j['name'] as String,
              iconName: (j['iconName'] as String?) ?? 'event',
            ),
          )
          .toList();
    } catch (_) {}

    try {
      final subRaw = await _client.get('/v1/events/subcities');
      final items = ((subRaw['items'] as List?) ?? const [])
          .map((e) => '$e')
          .toList();
      if (items.isNotEmpty) _subcities = items;
    } catch (_) {}

    final query = <String, String>{};
    if (f.query.trim().isNotEmpty) query['query'] = f.query.trim();
    if (f.categoryId != null) query['categoryId'] = f.categoryId!;
    if (f.subcity != null) query['subcity'] = f.subcity!;

    final raw = await _client.get('/v1/events/events', query: query);
    final items = ((raw['items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_parseEvent)
        .toList();
    _catalog = items;
    for (final e in items) {
      _events[e.id] = e;
    }
    _notify();
  }

  @override
  Future<void> refreshAuthed() async {
    try {
      final mine = await _client.get('/v1/events/my-events', auth: true);
      _myEvents = ((mine['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_parseEvent)
          .toList();
      for (final e in _myEvents) {
        _events[e.id] = e;
      }
    } catch (_) {
      _myEvents = const [];
    }

    try {
      final tickets = await _client.get('/v1/events/my-tickets', auth: true);
      _myTickets = ((tickets['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_parseTicket)
          .toList();
    } catch (_) {
      _myTickets = const [];
    }
    _notify();
  }

  @override
  void clearAuthed() {
    _myEvents = const [];
    _myTickets = const [];
    _notify();
  }

  @override
  Future<MaekelEvent> createEvent({
    required String categoryId,
    required String title,
    required String description,
    required String venueName,
    required String venueAddress,
    required String subcity,
    required DateTime startsAt,
    DateTime? endsAt,
    required int capacity,
    required int priceEtb,
    required EventPaymentMode paymentMode,
    List<String> imageUrls = const [],
  }) async {
    final raw = await _client.post(
      '/v1/events/events',
      auth: true,
      body: {
        'categoryId': categoryId,
        'title': title,
        'description': description,
        'venueName': venueName,
        'venueAddress': venueAddress,
        'subcity': subcity,
        'startsAt': startsAt.toUtc().toIso8601String(),
        if (endsAt != null) 'endsAt': endsAt.toUtc().toIso8601String(),
        'capacity': capacity,
        'priceEtb': priceEtb,
        'paymentMode': paymentModeApi(paymentMode),
        if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
        if (imageUrls.isNotEmpty) 'coverUrl': imageUrls.first,
      },
    ) as Map<String, dynamic>;
    final event = _parseEvent(raw);
    _events[event.id] = event;
    await refreshAuthed();
    return event;
  }

  @override
  Future<MaekelEvent> updateEvent(
    String id, {
    String? categoryId,
    String? title,
    String? description,
    String? venueName,
    String? venueAddress,
    String? subcity,
    DateTime? startsAt,
    DateTime? endsAt,
    int? capacity,
    int? priceEtb,
    EventPaymentMode? paymentMode,
    List<String>? imageUrls,
  }) async {
    final raw = await _client.patch(
      '/v1/events/events/$id',
      auth: true,
      body: {
        if (categoryId != null) 'categoryId': categoryId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (venueName != null) 'venueName': venueName,
        if (venueAddress != null) 'venueAddress': venueAddress,
        if (subcity != null) 'subcity': subcity,
        if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
        if (endsAt != null) 'endsAt': endsAt.toUtc().toIso8601String(),
        if (capacity != null) 'capacity': capacity,
        if (priceEtb != null) 'priceEtb': priceEtb,
        if (paymentMode != null) 'paymentMode': paymentModeApi(paymentMode),
        if (imageUrls != null) 'imageUrls': imageUrls,
        if (imageUrls != null && imageUrls.isNotEmpty)
          'coverUrl': imageUrls.first,
        if (imageUrls != null && imageUrls.isEmpty) 'coverUrl': null,
      },
    ) as Map<String, dynamic>;
    final event = _parseEvent(raw);
    _events[event.id] = event;
    await refreshAuthed();
    await refreshCatalog();
    return event;
  }

  @override
  Future<String> uploadPhoto({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final raw = await _client.postMultipart(
      '/v1/events/media',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      auth: true,
    ) as Map<String, dynamic>;
    return raw['url'] as String;
  }

  @override
  Future<MaekelEvent> updateEventStatus(
    String id, {
    required EventStatus status,
    String? reason,
  }) async {
    final raw = await _client.patch(
      '/v1/events/events/$id/status',
      auth: true,
      body: {
        'status': eventStatusApi(status),
        if (reason != null) 'reason': reason,
      },
    ) as Map<String, dynamic>;
    final event = _parseEvent(raw);
    _events[event.id] = event;
    await refreshAuthed();
    await refreshCatalog();
    return event;
  }

  @override
  Future<EventTicket> rsvp(String eventId, {int qty = 1}) async {
    final raw = await _client.post(
      '/v1/events/events/$eventId/rsvp',
      auth: true,
      body: {'qty': qty},
    ) as Map<String, dynamic>;
    final ticket = _parseTicket(raw);
    await refreshAuthed();
    await refreshCatalog();
    return ticket;
  }

  @override
  Future<void> cancelRsvp(String eventId) async {
    await _client.post(
      '/v1/events/events/$eventId/cancel-rsvp',
      auth: true,
    );
    await refreshAuthed();
    await refreshCatalog();
  }

  @override
  Future<List<EventAttendee>> getAttendees(String eventId) async {
    final raw = await _client.get(
      '/v1/events/events/$eventId/attendees',
      auth: true,
    ) as Map<String, dynamic>;
    final code = raw['checkInCode'] as String?;
    final event = _events[eventId];
    if (event != null && code != null) {
      _events[eventId] = MaekelEvent(
        id: event.id,
        organizerId: event.organizerId,
        organizerName: event.organizerName,
        organizerPhone: event.organizerPhone,
        categoryId: event.categoryId,
        categoryName: event.categoryName,
        title: event.title,
        description: event.description,
        venueName: event.venueName,
        venueAddress: event.venueAddress,
        subcity: event.subcity,
        startsAt: event.startsAt,
        endsAt: event.endsAt,
        capacity: event.capacity,
        ticketsSold: (raw['ticketsSold'] as num?)?.toInt() ?? event.ticketsSold,
        priceEtb: event.priceEtb,
        paymentMode: event.paymentMode,
        status: event.status,
        coverUrl: event.coverUrl,
        imageUrls: event.imageUrls,
        checkInCode: code,
        rejectionReason: event.rejectionReason,
        createdAt: event.createdAt,
        updatedAt: event.updatedAt,
      );
      _notify();
    }
    return ((raw['items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (j) => EventAttendee(
            id: j['id'] as String,
            eventId: j['eventId'] as String,
            userId: j['userId'] as String,
            qty: (j['qty'] as num).toInt(),
            status: parseTicketStatus(j['status'] as String? ?? 'reserved'),
            ticketCode: j['ticketCode'] as String,
            createdAt: parseDt(j['createdAt']) ?? DateTime.now(),
          ),
        )
        .toList();
  }

  @override
  Future<String?> getCheckInCode(String eventId) async {
    final attendees = await getAttendees(eventId);
    // ignore: unused_local_variable
    final _ = attendees;
    return _events[eventId]?.checkInCode;
  }

  @override
  Future<void> checkIn(
    String eventId, {
    String? ticketCode,
    String? ticketId,
  }) async {
    await _client.post(
      '/v1/events/events/$eventId/check-in',
      auth: true,
      body: {
        if (ticketCode != null) 'ticketCode': ticketCode,
        if (ticketId != null) 'ticketId': ticketId,
      },
    );
  }

  @override
  Future<EventsOpsQueue> getOpsQueue() async {
    final raw = await _client.get('/v1/events/ops/queue', auth: true)
        as Map<String, dynamic>;
    final pending = ((raw['pending'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_parseEvent)
        .toList();
    final live = ((raw['live'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_parseEvent)
        .toList();
    for (final e in [...pending, ...live]) {
      _events[e.id] = e;
    }
    _notify();
    return EventsOpsQueue(pending: pending, live: live);
  }

  @override
  Future<void> suspendOrganizer(
    String organizerId, {
    bool suspended = true,
  }) async {
    await _client.post(
      '/v1/events/ops/organizers/$organizerId/suspend',
      auth: true,
      body: {'suspended': suspended},
    );
  }

  Future<MaekelEvent> fetchEvent(String id) async {
    final raw = await _client.get('/v1/events/events/$id', auth: true)
        as Map<String, dynamic>;
    final event = _parseEvent(raw);
    _events[id] = event;
    _notify();
    return event;
  }

  MaekelEvent _parseEvent(Map<String, dynamic> j) {
    return MaekelEvent(
      id: j['id'] as String,
      organizerId: j['organizerId'] as String,
      organizerName: (j['organizerName'] as String?) ?? '',
      organizerPhone: (j['organizerPhone'] as String?) ?? '',
      categoryId: j['categoryId'] as String,
      categoryName: (j['categoryName'] as String?) ?? '',
      title: j['title'] as String,
      description: (j['description'] as String?) ?? '',
      venueName: j['venueName'] as String,
      venueAddress: (j['venueAddress'] as String?) ?? '',
      subcity: j['subcity'] as String,
      startsAt: parseDt(j['startsAt']) ?? DateTime.now(),
      endsAt: parseDt(j['endsAt']),
      capacity: (j['capacity'] as num).toInt(),
      ticketsSold: (j['ticketsSold'] as num?)?.toInt() ?? 0,
      priceEtb: (j['priceEtb'] as num?)?.toInt() ?? 0,
      paymentMode: parsePaymentMode(j['paymentMode'] as String? ?? 'free'),
      status: parseEventStatus(j['status'] as String? ?? 'pending'),
      coverUrl: j['coverUrl'] as String?,
      imageUrls: ((j['imageUrls'] as List?) ?? const [])
          .map((e) => '$e')
          .where((e) => e.isNotEmpty)
          .toList(),
      checkInCode: j['checkInCode'] as String?,
      rejectionReason: j['rejectionReason'] as String?,
      createdAt: parseDt(j['createdAt']),
      updatedAt: parseDt(j['updatedAt']),
    );
  }

  EventTicket _parseTicket(Map<String, dynamic> j) {
    return EventTicket(
      id: j['id'] as String,
      eventId: j['eventId'] as String,
      userId: j['userId'] as String,
      qty: (j['qty'] as num?)?.toInt() ?? 1,
      status: parseTicketStatus(j['status'] as String? ?? 'reserved'),
      ticketCode: j['ticketCode'] as String,
      createdAt: parseDt(j['createdAt']) ?? DateTime.now(),
      eventTitle: j['eventTitle'] as String?,
      venueName: j['venueName'] as String?,
      subcity: j['subcity'] as String?,
      startsAt: parseDt(j['startsAt']),
      eventStatus: j['eventStatus'] != null
          ? parseEventStatus(j['eventStatus'] as String)
          : null,
      priceEtb: (j['priceEtb'] as num?)?.toInt(),
      paymentMode: j['paymentMode'] != null
          ? parsePaymentMode(j['paymentMode'] as String)
          : null,
    );
  }
}
