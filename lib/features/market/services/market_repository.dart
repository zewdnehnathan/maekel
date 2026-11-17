import 'dart:async';

import '../models/market_models.dart';

abstract class MarketRepository {
  List<MarketCategory> getCategories();
  List<String> getSubcities();
  MarketSeller? getSeller(String id);
  MarketAd? getAd(String id);
  List<MarketAd> searchAds(MarketFilters filters);
  List<MarketAd> getAdsForSeller(String sellerId);
  Set<String> getFavoriteIds(String userId);
  Future<void> toggleFavorite(String userId, String adId);
  Future<MarketAd> createAd({
    required String sellerId,
    required String categoryId,
    required String title,
    required String description,
    required int priceEtb,
    required AdCondition condition,
    required String subcity,
    required List<String> photoUrls,
    Map<String, String> attributes,
  });
  Future<MarketAd> updateAd(
    String adId, {
    String? categoryId,
    String? title,
    String? description,
    int? priceEtb,
    AdCondition? condition,
    String? subcity,
    List<String>? photoUrls,
    Map<String, String>? attributes,
  });
  Future<MarketAd> updateAdStatus(
    String adId, {
    required AdStatus status,
    String? rejectReason,
  });
  Future<void> deleteAd(String adId);
  Future<String> uploadPhoto({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  });
  Future<MarketSeller> getMySeller();
  Future<MarketSeller> updateMySeller({
    bool? showPhone,
    String? name,
    String? locationLabel,
  });
  Future<List<SellerNotification>> getNotifications();
  Future<MarketOpsQueue> getOpsQueue();
  Future<void> resolveReport({
    required String reportId,
    required String action,
    String? note,
  });
  Future<void> suspendSeller({
    required String sellerId,
    required bool suspended,
    String? note,
  });
  Future<String> revealPhone(String adId);
  Future<MarketConfig> getConfig();
  List<ChatThread> getThreadsForUser(String userId);
  List<ChatMessage> getMessages(String threadId);
  Future<ChatThread> openOrCreateThread({
    required String adId,
    required String buyerId,
  });
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String senderId,
    required String body,
  });
  Future<AdReport> reportAd({
    required String adId,
    required String reporterId,
    required String reason,
  });
  Stream<void> get changes;
}

class InMemoryMarketRepository implements MarketRepository {
  InMemoryMarketRepository() {
    _seed();
  }

  final _controller = StreamController<void>.broadcast();
  final List<MarketCategory> _categories = [];
  final List<MarketSeller> _sellers = [];
  final List<MarketAd> _ads = [];
  final Map<String, Set<String>> _favorites = {};
  final List<ChatThread> _threads = [];
  final List<ChatMessage> _messages = [];
  final List<AdReport> _reports = [];
  final List<SellerNotification> _notifications = [];
  final List<AdReport> _openReports = [];
  final Map<String, int> _phoneRevealsToday = {};
  MarketConfig _config = const MarketConfig();
  int _seq = 100;

  static const subcities = [
    'Bole',
    'Kirkos',
    'Yeka',
    'Lideta',
    'Nifas Silk',
    'Addis Ketema',
    'Arada',
    'Gulele',
  ];

  void _notify() => _controller.add(null);

  String _id(String prefix) {
    _seq += 1;
    return '$prefix-$_seq';
  }

  void _seed() {
    _categories.addAll(const [
      MarketCategory(id: 'phones', name: 'Phones & Tablets', iconName: 'phone'),
      MarketCategory(id: 'electronics', name: 'Electronics', iconName: 'devices'),
      MarketCategory(id: 'vehicles', name: 'Vehicles', iconName: 'car'),
      MarketCategory(id: 'property', name: 'Property', iconName: 'home'),
      MarketCategory(id: 'furniture', name: 'Home & Furniture', iconName: 'chair'),
      MarketCategory(id: 'fashion', name: 'Fashion', iconName: 'checkroom'),
    ]);

    _sellers.addAll(const [
      MarketSeller(
        id: 'seller-1',
        name: 'Hanna T.',
        phoneE164: '+251911100001',
        locationLabel: 'Bole, Addis Ababa',
      ),
      MarketSeller(
        id: 'seller-2',
        name: 'Yonas M.',
        phoneE164: '+251911100002',
        locationLabel: 'CMC, Addis Ababa',
        showPhone: false,
      ),
      MarketSeller(
        id: 'seller-3',
        name: 'Sara K.',
        phoneE164: '+251911100003',
        locationLabel: 'Piassa, Addis Ababa',
      ),
    ]);

    final now = DateTime.now();
    _ads.addAll([
      MarketAd(
        id: 'ad-1',
        sellerId: 'seller-1',
        categoryId: 'phones',
        title: 'iPhone 13 128GB — clean',
        description:
            'Unlocked iPhone 13, battery 89%. Box + cable. Meetup in Bole Atlas.',
        priceEtb: 48500,
        condition: AdCondition.used,
        locationLabel: 'Addis Ababa',
        subcity: 'Bole',
        photoUrls: const [
          'https://images.unsplash.com/photo-1632661674596-df8befba448d?w=800',
        ],
        status: AdStatus.approved,
        createdAt: now.subtract(const Duration(hours: 5)),
        attributes: const {'Brand': 'Apple', 'Storage': '128GB'},
      ),
      MarketAd(
        id: 'ad-2',
        sellerId: 'seller-2',
        categoryId: 'electronics',
        title: '55" Smart TV 4K',
        description: 'Almost new Samsung smart TV. Wall mount included.',
        priceEtb: 62000,
        condition: AdCondition.refurbished,
        locationLabel: 'Addis Ababa',
        subcity: 'Yeka',
        photoUrls: const [
          'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=800',
        ],
        status: AdStatus.approved,
        createdAt: now.subtract(const Duration(days: 1)),
        attributes: const {'Brand': 'Samsung', 'Size': '55"'},
      ),
      MarketAd(
        id: 'ad-3',
        sellerId: 'seller-3',
        categoryId: 'vehicles',
        title: 'Toyota Vitz 2008',
        description: 'City car, AC working, duty paid. Serious buyers only.',
        priceEtb: 980000,
        condition: AdCondition.used,
        locationLabel: 'Addis Ababa',
        subcity: 'Nifas Silk',
        photoUrls: const [
          'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800',
        ],
        status: AdStatus.approved,
        createdAt: now.subtract(const Duration(days: 2)),
        attributes: const {'Year': '2008', 'Fuel': 'Petrol'},
      ),
      MarketAd(
        id: 'ad-4',
        sellerId: 'seller-1',
        categoryId: 'furniture',
        title: 'Solid wood dining set',
        description: '6 chairs + table. Pickup from Kirkos.',
        priceEtb: 28000,
        condition: AdCondition.used,
        locationLabel: 'Addis Ababa',
        subcity: 'Kirkos',
        photoUrls: const [
          'https://images.unsplash.com/photo-1617806118233-18e1de247200?w=800',
        ],
        status: AdStatus.approved,
        createdAt: now.subtract(const Duration(hours: 30)),
      ),
      MarketAd(
        id: 'ad-5',
        sellerId: 'seller-2',
        categoryId: 'fashion',
        title: 'Leather jacket — medium',
        description: 'Genuine leather, worn twice. Cash on meetup.',
        priceEtb: 4500,
        condition: AdCondition.brandNew,
        locationLabel: 'Addis Ababa',
        subcity: 'Arada',
        photoUrls: const [
          'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800',
        ],
        status: AdStatus.approved,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      MarketAd(
        id: 'ad-6',
        sellerId: 'seller-3',
        categoryId: 'property',
        title: 'Studio for rent — Bole',
        description: 'Furnished studio near Edna Mall. Water + wifi included.',
        priceEtb: 25000,
        condition: AdCondition.used,
        locationLabel: 'Addis Ababa',
        subcity: 'Bole',
        photoUrls: const [
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
        ],
        status: AdStatus.approved,
        createdAt: now.subtract(const Duration(days: 3)),
        attributes: const {'Type': 'Rent', 'Furnishing': 'Furnished'},
      ),
    ]);
  }

  @override
  Stream<void> get changes => _controller.stream;

  @override
  List<MarketCategory> getCategories() => List.unmodifiable(_categories);

  @override
  List<String> getSubcities() => List.unmodifiable(subcities);

  @override
  MarketSeller? getSeller(String id) {
    for (final s in _sellers) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  MarketAd? getAd(String id) {
    for (final ad in _ads) {
      if (ad.id == id) return ad;
    }
    return null;
  }

  @override
  List<MarketAd> searchAds(MarketFilters filters) {
    Iterable<MarketAd> result = _ads.where((a) => a.status == AdStatus.approved);

    if (filters.categoryId != null) {
      result = result.where((a) => a.categoryId == filters.categoryId);
    }
    if (filters.subcity != null && filters.subcity!.isNotEmpty) {
      result = result.where((a) => a.subcity == filters.subcity);
    }
    if (filters.condition != null) {
      result = result.where((a) => a.condition == filters.condition);
    }
    if (filters.minPrice != null) {
      result = result.where((a) => a.priceEtb >= filters.minPrice!);
    }
    if (filters.maxPrice != null) {
      result = result.where((a) => a.priceEtb <= filters.maxPrice!);
    }
    final q = filters.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q) ||
            a.subcity.toLowerCase().contains(q);
      });
    }

    final list = result.toList();
    switch (filters.sort) {
      case AdSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case AdSort.priceLow:
        list.sort((a, b) => a.priceEtb.compareTo(b.priceEtb));
      case AdSort.priceHigh:
        list.sort((a, b) => b.priceEtb.compareTo(a.priceEtb));
    }
    return list;
  }

  @override
  List<MarketAd> getAdsForSeller(String sellerId) {
    final list = _ads.where((a) => a.sellerId == sellerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Set<String> getFavoriteIds(String userId) {
    return Set.unmodifiable(_favorites[userId] ?? {});
  }

  @override
  Future<void> toggleFavorite(String userId, String adId) async {
    final set = _favorites.putIfAbsent(userId, () => <String>{});
    if (!set.add(adId)) {
      set.remove(adId);
    }
    _notify();
  }

  @override
  Future<MarketAd> createAd({
    required String sellerId,
    required String categoryId,
    required String title,
    required String description,
    required int priceEtb,
    required AdCondition condition,
    required String subcity,
    required List<String> photoUrls,
    Map<String, String> attributes = const {},
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (photoUrls.isEmpty) {
      throw ArgumentError('At least one photo is required');
    }
    if (getSeller(sellerId) == null) {
      _sellers.add(
        MarketSeller(
          id: sellerId,
          name: 'You',
          phoneE164: sellerId.replaceFirst('user-', '+'),
          locationLabel: '$subcity, Addis Ababa',
        ),
      );
    }

    final activeCount = _ads
        .where(
          (a) =>
              a.sellerId == sellerId &&
              (a.status == AdStatus.approved || a.status == AdStatus.pending),
        )
        .length;
    if (activeCount >= _config.maxActiveFreeAds) {
      throw StateError(
        'Active ad limit reached (${_config.maxActiveFreeAds}).',
      );
    }

    final ad = MarketAd(
      id: _id('ad'),
      sellerId: sellerId,
      categoryId: categoryId,
      title: title.trim(),
      description: description.trim(),
      priceEtb: priceEtb,
      condition: condition,
      locationLabel: 'Addis Ababa',
      subcity: subcity,
      photoUrls: photoUrls,
      status: AdStatus.pending,
      createdAt: DateTime.now(),
      attributes: attributes,
    );
    _ads.insert(0, ad);
    _notifications.insert(
      0,
      SellerNotification(
        id: _id('note'),
        adId: ad.id,
        kind: 'moderation_submitted',
        title: 'Ad submitted',
        body: '"${ad.title}" is pending review.',
        createdAt: DateTime.now(),
      ),
    );
    _notify();
    return ad;
  }

  @override
  Future<MarketAd> updateAd(
    String adId, {
    String? categoryId,
    String? title,
    String? description,
    int? priceEtb,
    AdCondition? condition,
    String? subcity,
    List<String>? photoUrls,
    Map<String, String>? attributes,
  }) async {
    final idx = _ads.indexWhere((a) => a.id == adId);
    if (idx < 0) throw StateError('Ad not found');
    final current = _ads[idx];
    final material = title != null ||
        description != null ||
        priceEtb != null ||
        photoUrls != null ||
        categoryId != null;
    _ads[idx] = current.copyWith(
      categoryId: categoryId,
      title: title,
      description: description,
      priceEtb: priceEtb,
      condition: condition,
      subcity: subcity,
      photoUrls: photoUrls,
      attributes: attributes,
      status: material ? AdStatus.pending : current.status,
      clearRejectReason: material,
    );
    _notify();
    return _ads[idx];
  }

  @override
  Future<MarketAd> updateAdStatus(
    String adId, {
    required AdStatus status,
    String? rejectReason,
  }) async {
    final idx = _ads.indexWhere((a) => a.id == adId);
    if (idx < 0) {
      throw StateError('Ad not found');
    }
    _ads[idx] = _ads[idx].copyWith(
      status: status,
      rejectReason: rejectReason,
      clearRejectReason: rejectReason == null && status != AdStatus.rejected,
    );
    final ad = _ads[idx];
    if (status == AdStatus.approved || status == AdStatus.rejected) {
      _notifications.insert(
        0,
        SellerNotification(
          id: _id('note'),
          adId: ad.id,
          kind: status == AdStatus.approved
              ? 'moderation_approved'
              : 'moderation_rejected',
          title: status == AdStatus.approved ? 'Ad approved' : 'Ad declined',
          body: status == AdStatus.approved
              ? '"${ad.title}" is now live.'
              : (rejectReason ?? 'Your ad was declined.'),
          createdAt: DateTime.now(),
        ),
      );
    }
    _notify();
    return _ads[idx];
  }

  @override
  Future<void> deleteAd(String adId) async {
    _ads.removeWhere((a) => a.id == adId);
    _notify();
  }

  @override
  Future<String> uploadPhoto({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return 'https://images.unsplash.com/photo-1560472355-536de3962603?w=800';
  }

  @override
  Future<MarketSeller> getMySeller() async {
    return _sellers.first;
  }

  @override
  Future<MarketSeller> updateMySeller({
    bool? showPhone,
    String? name,
    String? locationLabel,
  }) async {
    final idx = 0;
    _sellers[idx] = _sellers[idx].copyWith(
      showPhone: showPhone,
      name: name,
      locationLabel: locationLabel,
    );
    _notify();
    return _sellers[idx];
  }

  @override
  Future<List<SellerNotification>> getNotifications() async {
    return List.unmodifiable(_notifications);
  }

  @override
  Future<MarketOpsQueue> getOpsQueue() async {
    final pending =
        _ads.where((a) => a.status == AdStatus.pending).toList();
    return MarketOpsQueue(
      pendingAds: pending,
      reports: _openReports
          .map(
            (r) => MarketReportItem(
              id: r.id,
              adId: r.adId,
              adTitle: getAd(r.adId)?.title ?? 'Ad',
              sellerId: getAd(r.adId)?.sellerId ?? '',
              reporterId: r.reporterId,
              reason: r.reason,
              createdAt: r.createdAt,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> resolveReport({
    required String reportId,
    required String action,
    String? note,
  }) async {
    _openReports.removeWhere((r) => r.id == reportId);
    _notify();
  }

  @override
  Future<void> suspendSeller({
    required String sellerId,
    required bool suspended,
    String? note,
  }) async {
    final idx = _sellers.indexWhere((s) => s.id == sellerId);
    if (idx >= 0) {
      _sellers[idx] = _sellers[idx].copyWith(suspended: suspended);
    }
    _notify();
  }

  @override
  Future<String> revealPhone(String adId) async {
    final ad = getAd(adId);
    if (ad == null) throw StateError('Ad not found');
    final seller = getSeller(ad.sellerId);
    if (seller == null || !seller.showPhone) {
      throw StateError('Phone hidden');
    }
    final key = DateTime.now().toIso8601String().substring(0, 10);
    final used = _phoneRevealsToday[key] ?? 0;
    if (used >= _config.phoneRevealDailyLimit) {
      throw StateError('Daily call limit reached');
    }
    _phoneRevealsToday[key] = used + 1;
    return seller.phoneE164;
  }

  @override
  Future<MarketConfig> getConfig() async => _config;

  @override
  List<ChatThread> getThreadsForUser(String userId) {
    final list = _threads
        .where((t) => t.buyerId == userId || t.sellerId == userId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  List<ChatMessage> getMessages(String threadId) {
    final list = _messages.where((m) => m.threadId == threadId).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return list;
  }

  @override
  Future<ChatThread> openOrCreateThread({
    required String adId,
    required String buyerId,
  }) async {
    final ad = getAd(adId);
    if (ad == null) throw StateError('Ad not found');
    if (ad.sellerId == buyerId) {
      throw StateError('Cannot chat on your own ad');
    }

    for (final t in _threads) {
      if (t.adId == adId && t.buyerId == buyerId) return t;
    }

    final thread = ChatThread(
      id: _id('thread'),
      adId: adId,
      buyerId: buyerId,
      sellerId: ad.sellerId,
      updatedAt: DateTime.now(),
    );
    _threads.insert(0, thread);
    _messages.add(
      ChatMessage(
        id: _id('msg'),
        threadId: thread.id,
        senderId: 'system',
        body:
            'Safety tip: Meet in a public place. Inspect before you pay. Maekel never asks for fees via chat.',
        sentAt: DateTime.now(),
      ),
    );
    _notify();
    return thread;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String senderId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Message empty');
    }
    final msg = ChatMessage(
      id: _id('msg'),
      threadId: threadId,
      senderId: senderId,
      body: trimmed,
      sentAt: DateTime.now(),
    );
    _messages.add(msg);
    final idx = _threads.indexWhere((t) => t.id == threadId);
    if (idx >= 0) {
      _threads[idx] = _threads[idx].copyWith(updatedAt: msg.sentAt);
    }
    _notify();

    // Simple seller auto-reply for demo when buyer sends.
    ChatThread? thread;
    for (final t in _threads) {
      if (t.id == threadId) {
        thread = t;
        break;
      }
    }
    if (thread != null && senderId == thread.buyerId) {
      final sellerId = thread.sellerId;
      unawaited(Future<void>.delayed(const Duration(seconds: 1), () {
        _messages.add(
          ChatMessage(
            id: _id('msg'),
            threadId: threadId,
            senderId: sellerId,
            body: 'Thanks — still available. When can you meet in Addis?',
            sentAt: DateTime.now(),
          ),
        );
        final tIdx = _threads.indexWhere((t) => t.id == threadId);
        if (tIdx >= 0) {
          _threads[tIdx] = _threads[tIdx].copyWith(updatedAt: DateTime.now());
        }
        _notify();
      }));
    }

    return msg;
  }

  @override
  Future<AdReport> reportAd({
    required String adId,
    required String reporterId,
    required String reason,
  }) async {
    final report = AdReport(
      id: _id('report'),
      adId: adId,
      reporterId: reporterId,
      reason: reason.trim(),
      createdAt: DateTime.now(),
    );
    _reports.add(report);
    _openReports.add(report);
    _notify();
    return report;
  }
}
