import '../models/events_models.dart';

abstract class EventsRepository {
  Stream<void> get changes;
  void dispose();

  List<EventCategory> getCategories();
  List<String> getSubcities();
  List<MaekelEvent> getCatalog();
  List<MaekelEvent> getMyEvents();
  List<EventTicket> getMyTickets();
  MaekelEvent? getEvent(String id);

  Future<void> refreshCatalog({EventFilters? filters});
  Future<void> refreshAuthed();
  void clearAuthed();

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
  });

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
  });

  Future<MaekelEvent> updateEventStatus(
    String id, {
    required EventStatus status,
    String? reason,
  });

  Future<EventTicket> rsvp(String eventId, {int qty = 1});
  Future<void> cancelRsvp(String eventId);

  Future<List<EventAttendee>> getAttendees(String eventId);
  Future<String?> getCheckInCode(String eventId);
  Future<void> checkIn(String eventId, {String? ticketCode, String? ticketId});

  Future<EventsOpsQueue> getOpsQueue();
  Future<void> suspendOrganizer(String organizerId, {bool suspended = true});
}
