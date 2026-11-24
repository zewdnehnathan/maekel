import '../../../l10n/app_localizations.dart';

enum EventStatus {
  draft,
  pending,
  approved,
  rejected,
  cancelled,
  ended,
}

enum EventPaymentMode { free, payAtDoor }

enum TicketStatus { reserved, checkedIn, cancelled }

class EventCategory {
  const EventCategory({
    required this.id,
    required this.name,
    required this.iconName,
  });

  final String id;
  final String name;
  final String iconName;
}

class MaekelEvent {
  const MaekelEvent({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.organizerPhone,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.description,
    required this.venueName,
    required this.venueAddress,
    required this.subcity,
    required this.startsAt,
    this.endsAt,
    required this.capacity,
    required this.ticketsSold,
    required this.priceEtb,
    required this.paymentMode,
    required this.status,
    this.coverUrl,
    this.imageUrls = const [],
    this.checkInCode,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String organizerId;
  final String organizerName;
  final String organizerPhone;
  final String categoryId;
  final String categoryName;
  final String title;
  final String description;
  final String venueName;
  final String venueAddress;
  final String subcity;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int capacity;
  final int ticketsSold;
  final int priceEtb;
  final EventPaymentMode paymentMode;
  final EventStatus status;
  final String? coverUrl;
  final List<String> imageUrls;
  final String? checkInCode;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get seatsLeft => (capacity - ticketsSold).clamp(0, capacity);
  bool get isSoldOut => seatsLeft <= 0;
  bool get isFree => priceEtb <= 0 || paymentMode == EventPaymentMode.free;

  List<String> get displayImageUrls {
    if (imageUrls.isNotEmpty) return imageUrls;
    final cover = coverUrl;
    if (cover != null && cover.isNotEmpty) return [cover];
    return const [];
  }

  String priceLabelLocalized(AppLocalizations l10n) {
    if (isFree && priceEtb <= 0) return l10n.eventsFree;
    if (paymentMode == EventPaymentMode.payAtDoor) {
      return l10n.eventsPricePayDoor(priceEtb);
    }
    return '${l10n.currencyEtb} $priceEtb';
  }
}

class EventTicket {
  const EventTicket({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.qty,
    required this.status,
    required this.ticketCode,
    required this.createdAt,
    this.eventTitle,
    this.venueName,
    this.subcity,
    this.startsAt,
    this.eventStatus,
    this.priceEtb,
    this.paymentMode,
  });

  final String id;
  final String eventId;
  final String userId;
  final int qty;
  final TicketStatus status;
  final String ticketCode;
  final DateTime createdAt;
  final String? eventTitle;
  final String? venueName;
  final String? subcity;
  final DateTime? startsAt;
  final EventStatus? eventStatus;
  final int? priceEtb;
  final EventPaymentMode? paymentMode;
}

class EventAttendee {
  const EventAttendee({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.qty,
    required this.status,
    required this.ticketCode,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String userId;
  final int qty;
  final TicketStatus status;
  final String ticketCode;
  final DateTime createdAt;
}

class EventsOpsQueue {
  const EventsOpsQueue({
    required this.pending,
    required this.live,
  });

  final List<MaekelEvent> pending;
  final List<MaekelEvent> live;
}

class EventFilters {
  const EventFilters({
    this.query = '',
    this.categoryId,
    this.subcity,
  });

  final String query;
  final String? categoryId;
  final String? subcity;

  EventFilters copyWith({
    String? query,
    String? categoryId,
    String? subcity,
    bool clearCategory = false,
    bool clearSubcity = false,
  }) {
    return EventFilters(
      query: query ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      subcity: clearSubcity ? null : (subcity ?? this.subcity),
    );
  }
}

EventStatus parseEventStatus(String raw) {
  switch (raw) {
    case 'draft':
      return EventStatus.draft;
    case 'pending':
      return EventStatus.pending;
    case 'approved':
      return EventStatus.approved;
    case 'rejected':
      return EventStatus.rejected;
    case 'cancelled':
      return EventStatus.cancelled;
    case 'ended':
      return EventStatus.ended;
    default:
      return EventStatus.pending;
  }
}

String eventStatusApi(EventStatus s) {
  switch (s) {
    case EventStatus.draft:
      return 'draft';
    case EventStatus.pending:
      return 'pending';
    case EventStatus.approved:
      return 'approved';
    case EventStatus.rejected:
      return 'rejected';
    case EventStatus.cancelled:
      return 'cancelled';
    case EventStatus.ended:
      return 'ended';
  }
}

EventPaymentMode parsePaymentMode(String raw) {
  return raw == 'pay_at_door'
      ? EventPaymentMode.payAtDoor
      : EventPaymentMode.free;
}

String paymentModeApi(EventPaymentMode m) {
  return m == EventPaymentMode.payAtDoor ? 'pay_at_door' : 'free';
}

TicketStatus parseTicketStatus(String raw) {
  switch (raw) {
    case 'checked_in':
      return TicketStatus.checkedIn;
    case 'cancelled':
      return TicketStatus.cancelled;
    default:
      return TicketStatus.reserved;
  }
}

DateTime? parseDt(Object? raw) {
  if (raw == null) return null;
  return DateTime.tryParse('$raw')?.toLocal();
}

extension EventStatusL10n on EventStatus {
  String localized(AppLocalizations l10n) {
    switch (this) {
      case EventStatus.draft:
        return l10n.eventStatusDraft;
      case EventStatus.pending:
        return l10n.pending;
      case EventStatus.approved:
        return l10n.approved;
      case EventStatus.rejected:
        return l10n.eventStatusRejected;
      case EventStatus.cancelled:
        return l10n.rideStatusCancelled;
      case EventStatus.ended:
        return l10n.eventStatusEnded;
    }
  }
}

extension TicketStatusL10n on TicketStatus {
  String localized(AppLocalizations l10n) {
    switch (this) {
      case TicketStatus.reserved:
        return l10n.ticketStatusReserved;
      case TicketStatus.checkedIn:
        return l10n.ticketStatusCheckedIn;
      case TicketStatus.cancelled:
        return l10n.rideStatusCancelled;
    }
  }
}
