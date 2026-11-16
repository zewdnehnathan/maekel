enum AdCondition { brandNew, used, refurbished }

enum AdStatus { pending, approved, rejected, sold }

enum AdSort { newest, priceLow, priceHigh }

class MarketCategory {
  const MarketCategory({
    required this.id,
    required this.name,
    required this.iconName,
  });

  final String id;
  final String name;
  final String iconName;
}

class MarketSeller {
  const MarketSeller({
    required this.id,
    required this.name,
    required this.phoneE164,
    this.showPhone = true,
    this.locationLabel = 'Addis Ababa',
  });

  final String id;
  final String name;
  final String phoneE164;
  final bool showPhone;
  final String locationLabel;
}

class MarketAd {
  const MarketAd({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.priceEtb,
    required this.condition,
    required this.locationLabel,
    required this.subcity,
    required this.photoUrls,
    required this.status,
    required this.createdAt,
    this.rejectReason,
    this.attributes = const {},
  });

  final String id;
  final String sellerId;
  final String categoryId;
  final String title;
  final String description;
  final int priceEtb;
  final AdCondition condition;
  final String locationLabel;
  final String subcity;
  final List<String> photoUrls;
  final AdStatus status;
  final DateTime createdAt;
  final String? rejectReason;
  final Map<String, String> attributes;

  MarketAd copyWith({
    String? title,
    String? description,
    int? priceEtb,
    AdCondition? condition,
    String? locationLabel,
    String? subcity,
    List<String>? photoUrls,
    AdStatus? status,
    String? rejectReason,
    Map<String, String>? attributes,
    bool clearRejectReason = false,
  }) {
    return MarketAd(
      id: id,
      sellerId: sellerId,
      categoryId: categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      priceEtb: priceEtb ?? this.priceEtb,
      condition: condition ?? this.condition,
      locationLabel: locationLabel ?? this.locationLabel,
      subcity: subcity ?? this.subcity,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      createdAt: createdAt,
      rejectReason:
          clearRejectReason ? null : (rejectReason ?? this.rejectReason),
      attributes: attributes ?? this.attributes,
    );
  }
}

class ChatThread {
  const ChatThread({
    required this.id,
    required this.adId,
    required this.buyerId,
    required this.sellerId,
    required this.updatedAt,
  });

  final String id;
  final String adId;
  final String buyerId;
  final String sellerId;
  final DateTime updatedAt;

  ChatThread copyWith({DateTime? updatedAt}) {
    return ChatThread(
      id: id,
      adId: adId,
      buyerId: buyerId,
      sellerId: sellerId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    required this.sentAt,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String body;
  final DateTime sentAt;
}

class AdReport {
  const AdReport({
    required this.id,
    required this.adId,
    required this.reporterId,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String adId;
  final String reporterId;
  final String reason;
  final DateTime createdAt;
}

class MarketFilters {
  const MarketFilters({
    this.query = '',
    this.categoryId,
    this.subcity,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.sort = AdSort.newest,
  });

  final String query;
  final String? categoryId;
  final String? subcity;
  final int? minPrice;
  final int? maxPrice;
  final AdCondition? condition;
  final AdSort sort;

  MarketFilters copyWith({
    String? query,
    String? categoryId,
    String? subcity,
    int? minPrice,
    int? maxPrice,
    AdCondition? condition,
    AdSort? sort,
    bool clearCategory = false,
    bool clearSubcity = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearCondition = false,
  }) {
    return MarketFilters(
      query: query ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      subcity: clearSubcity ? null : (subcity ?? this.subcity),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      condition: clearCondition ? null : (condition ?? this.condition),
      sort: sort ?? this.sort,
    );
  }
}

extension AdConditionLabel on AdCondition {
  String get label {
    switch (this) {
      case AdCondition.brandNew:
        return 'Brand new';
      case AdCondition.used:
        return 'Used';
      case AdCondition.refurbished:
        return 'Refurbished';
    }
  }
}

extension AdStatusLabel on AdStatus {
  String get label {
    switch (this) {
      case AdStatus.pending:
        return 'Pending';
      case AdStatus.approved:
        return 'Active';
      case AdStatus.rejected:
        return 'Declined';
      case AdStatus.sold:
        return 'Sold';
    }
  }
}
