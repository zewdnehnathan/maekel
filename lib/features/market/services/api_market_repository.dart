import 'dart:async';

import '../../../core/network/api_client.dart';
import '../models/market_models.dart';
import 'market_repository.dart';

/// HTTP market repo with an in-memory cache seeded from the gateway catalogs.
class ApiMarketRepository implements MarketRepository {
  ApiMarketRepository(this._client) {
    _seedLocalCatalog();
    unawaited(refreshCatalog());
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(refreshCatalog(silent: true));
    });
  }

  final ApiClient _client;
  final _controller = StreamController<void>.broadcast();
  Timer? _poll;

  final List<MarketCategory> _categories = [];
  final List<MarketSeller> _sellers = [];
  final List<MarketAd> _ads = [];
  final List<String> _subcities = List.of(InMemoryMarketRepository.subcities);
  final Set<String> _favoriteIds = {};
  final List<ChatThread> _threads = [];
  final Map<String, List<ChatMessage>> _messages = {};
  final List<SellerNotification> _notifications = [];
  MarketSeller? _mySeller;
  MarketConfig _config = const MarketConfig();

  void dispose() {
    _poll?.cancel();
    _controller.close();
  }

  void _notify() => _controller.add(null);

  Future<void> refreshCatalog({bool silent = false}) async {
    try {
      final catsRaw = await _client.get('/v1/market/categories');
      final sellersRaw = await _client.get('/v1/market/sellers');
      final adsRaw = await _client.get('/v1/market/ads');
      final subRaw = await _client.get('/v1/market/subcities');

      _categories
        ..clear()
        ..addAll(
          ((catsRaw as Map)['items'] as List)
              .cast<Map<String, dynamic>>()
              .map(_parseCategory),
        );
      _sellers
        ..clear()
        ..addAll(
          ((sellersRaw as Map)['items'] as List)
              .cast<Map<String, dynamic>>()
              .map(_parseSeller),
        );
      _ads
        ..clear()
        ..addAll(
          ((adsRaw as Map)['items'] as List)
              .cast<Map<String, dynamic>>()
              .map(_parseAd),
        );
      final subs = ((subRaw as Map)['items'] as List).cast<String>();
      if (subs.isNotEmpty) {
        _subcities
          ..clear()
          ..addAll(subs);
      }
      _notify();
    } catch (_) {
      if (!silent) {
        // Keep local seed if gateway is down.
      }
    }
  }

  Future<void> refreshAuthed(String userId) async {
    try {
      final favs = await _client.get('/v1/market/favorites', auth: true);
      _favoriteIds
        ..clear()
        ..addAll(
          ((favs as Map)['items'] as List)
              .cast<Map<String, dynamic>>()
              .map((a) => a['id'] as String),
        );

      final myAds = await _client.get('/v1/market/my-ads', auth: true);
      for (final raw in ((myAds as Map)['items'] as List)
          .cast<Map<String, dynamic>>()) {
        final ad = _parseAd(raw);
        final idx = _ads.indexWhere((a) => a.id == ad.id);
        if (idx >= 0) {
          _ads[idx] = ad;
        } else {
          _ads.add(ad);
        }
      }

      final threads = await _client.get('/v1/chat/threads', auth: true);
      _threads
        ..clear()
        ..addAll(
          ((threads as Map)['items'] as List)
              .cast<Map<String, dynamic>>()
              .map(_parseThread),
        );

      try {
        final sellerRaw =
            await _client.get('/v1/market/me/seller', auth: true);
        _mySeller = _parseSeller(sellerRaw as Map<String, dynamic>);
        _upsertSeller(_mySeller!);
      } catch (_) {}

      try {
        final notes =
            await _client.get('/v1/market/me/notifications', auth: true);
        _notifications
          ..clear()
          ..addAll(
            ((notes as Map)['items'] as List)
                .cast<Map<String, dynamic>>()
                .map(_parseNotification),
          );
      } catch (_) {}

      try {
        final cfg = await _client.get('/v1/market/config');
        _config = _parseConfig(cfg as Map<String, dynamic>);
      } catch (_) {}

      _notify();
    } catch (_) {
      // Ignore until signed in.
    }
  }

  @override
  Stream<void> get changes => _controller.stream;

  @override
  List<MarketCategory> getCategories() => List.unmodifiable(_categories);

  @override
  List<String> getSubcities() => List.unmodifiable(_subcities);

  @override
  MarketSeller? getSeller(String id) {
    for (final s in _sellers) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  MarketAd? getAd(String id) {
    for (final a in _ads) {
      if (a.id == id) return a;
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
  Set<String> getFavoriteIds(String userId) => Set.unmodifiable(_favoriteIds);

  @override
  Future<void> toggleFavorite(String userId, String adId) async {
    final raw = await _client.post(
      '/v1/market/favorites/$adId/toggle',
      auth: true,
    ) as Map<String, dynamic>;
    final favorited = raw['favorited'] as bool? ?? false;
    if (favorited) {
      _favoriteIds.add(adId);
    } else {
      _favoriteIds.remove(adId);
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
    final raw = await _client.post(
      '/v1/market/ads',
      auth: true,
      body: {
        'categoryId': categoryId,
        'title': title,
        'description': description,
        'priceEtb': priceEtb,
        'condition': condition.name,
        'subcity': subcity,
        'photoUrls': photoUrls,
        'attributes': attributes,
      },
    ) as Map<String, dynamic>;
    final ad = _parseAd(raw);
    _ads.insert(0, ad);
    await refreshAuthed(sellerId);
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
    final raw = await _client.patch(
      '/v1/market/ads/$adId',
      auth: true,
      body: {
        if (categoryId != null) 'categoryId': categoryId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (priceEtb != null) 'priceEtb': priceEtb,
        if (condition != null) 'condition': condition.name,
        if (subcity != null) 'subcity': subcity,
        if (photoUrls != null) 'photoUrls': photoUrls,
        if (attributes != null) 'attributes': attributes,
      },
    ) as Map<String, dynamic>;
    final ad = _parseAd(raw);
    final idx = _ads.indexWhere((a) => a.id == adId);
    if (idx >= 0) {
      _ads[idx] = ad;
    } else {
      _ads.add(ad);
    }
    _notify();
    return ad;
  }

  @override
  Future<MarketAd> updateAdStatus(
    String adId, {
    required AdStatus status,
    String? rejectReason,
  }) async {
    final raw = await _client.patch(
      '/v1/market/ads/$adId/status',
      auth: true,
      body: {
        'status': status.name,
        if (rejectReason != null) 'rejectReason': rejectReason,
      },
    ) as Map<String, dynamic>;
    final ad = _parseAd(raw);
    final idx = _ads.indexWhere((a) => a.id == adId);
    if (idx >= 0) {
      _ads[idx] = ad;
    } else {
      _ads.add(ad);
    }
    _notify();
    return ad;
  }

  @override
  Future<void> deleteAd(String adId) async {
    await _client.delete('/v1/market/ads/$adId', auth: true);
    _ads.removeWhere((a) => a.id == adId);
    _notify();
  }

  @override
  Future<String> uploadPhoto({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final raw = await _client.postMultipart(
      '/v1/market/media',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      auth: true,
    ) as Map<String, dynamic>;
    return raw['url'] as String;
  }

  @override
  Future<MarketSeller> getMySeller() async {
    final raw =
        await _client.get('/v1/market/me/seller', auth: true)
            as Map<String, dynamic>;
    _mySeller = _parseSeller(raw);
    _upsertSeller(_mySeller!);
    _notify();
    return _mySeller!;
  }

  @override
  Future<MarketSeller> updateMySeller({
    bool? showPhone,
    String? name,
    String? locationLabel,
  }) async {
    final raw = await _client.patch(
      '/v1/market/me/seller',
      auth: true,
      body: {
        if (showPhone != null) 'showPhone': showPhone,
        if (name != null) 'name': name,
        if (locationLabel != null) 'locationLabel': locationLabel,
      },
    ) as Map<String, dynamic>;
    _mySeller = _parseSeller(raw);
    _upsertSeller(_mySeller!);
    _notify();
    return _mySeller!;
  }

  @override
  Future<List<SellerNotification>> getNotifications() async {
    final raw =
        await _client.get('/v1/market/me/notifications', auth: true);
    _notifications
      ..clear()
      ..addAll(
        ((raw as Map)['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(_parseNotification),
      );
    _notify();
    return List.unmodifiable(_notifications);
  }

  @override
  Future<MarketOpsQueue> getOpsQueue() async {
    final raw =
        await _client.get('/v1/market/ops/queue', auth: true)
            as Map<String, dynamic>;
    final pending = ((raw['pendingAds'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_parseAd)
        .toList();
    final reports = ((raw['reports'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_parseReportItem)
        .toList();
    return MarketOpsQueue(pendingAds: pending, reports: reports);
  }

  @override
  Future<void> resolveReport({
    required String reportId,
    required String action,
    String? note,
  }) async {
    await _client.post(
      '/v1/market/ops/reports/$reportId/resolve',
      auth: true,
      body: {
        'action': action,
        if (note != null) 'note': note,
      },
    );
  }

  @override
  Future<void> suspendSeller({
    required String sellerId,
    required bool suspended,
    String? note,
  }) async {
    await _client.post(
      '/v1/market/ops/sellers/$sellerId/suspend',
      auth: true,
      body: {
        'suspended': suspended,
        if (note != null) 'note': note,
      },
    );
  }

  @override
  Future<String> revealPhone(String adId) async {
    final raw = await _client.post(
      '/v1/market/ads/$adId/reveal-phone',
      auth: true,
    ) as Map<String, dynamic>;
    return raw['phoneE164'] as String;
  }

  @override
  Future<MarketConfig> getConfig() async {
    final raw = await _client.get('/v1/market/config');
    _config = _parseConfig(raw as Map<String, dynamic>);
    return _config;
  }

  void _upsertSeller(MarketSeller seller) {
    final idx = _sellers.indexWhere((s) => s.id == seller.id);
    if (idx >= 0) {
      _sellers[idx] = seller;
    } else {
      _sellers.add(seller);
    }
  }

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
    return List.unmodifiable(_messages[threadId] ?? const []);
  }

  @override
  Future<ChatThread> openOrCreateThread({
    required String adId,
    required String buyerId,
  }) async {
    final raw = await _client.post(
      '/v1/market/ads/$adId/chat',
      auth: true,
    ) as Map<String, dynamic>;
    final threadId = raw['threadId'] as String;
    final threads = await _client.get('/v1/chat/threads', auth: true);
    _threads
      ..clear()
      ..addAll(
        ((threads as Map)['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(_parseThread),
      );
    await loadMessages(threadId);
    _notify();
    return _threads.firstWhere((t) => t.id == threadId);
  }

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String senderId,
    required String body,
  }) async {
    final raw = await _client.post(
      '/v1/chat/threads/$threadId/messages',
      auth: true,
      body: {'body': body},
    ) as Map<String, dynamic>;
    final msg = _parseMessage(raw);
    final list = _messages.putIfAbsent(threadId, () => []);
    list.add(msg);
    final idx = _threads.indexWhere((t) => t.id == threadId);
    if (idx >= 0) {
      _threads[idx] = _threads[idx].copyWith(updatedAt: msg.sentAt);
    }
    _notify();
    unawaited(Future<void>.delayed(const Duration(seconds: 2), () async {
      await loadMessages(threadId);
      _notify();
    }));
    return msg;
  }

  @override
  Future<AdReport> reportAd({
    required String adId,
    required String reporterId,
    required String reason,
  }) async {
    final raw = await _client.post(
      '/v1/market/ads/$adId/report',
      auth: true,
      body: {'reason': reason},
    ) as Map<String, dynamic>;
    return AdReport(
      id: raw['id'] as String,
      adId: adId,
      reporterId: reporterId,
      reason: reason.trim(),
      createdAt: DateTime.now(),
    );
  }

  Future<void> loadMessages(String threadId) async {
    final raw = await _client.get(
      '/v1/chat/threads/$threadId/messages',
      auth: true,
    );
    _messages[threadId] = ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(_parseMessage)
        .toList();
    _notify();
  }

  void _seedLocalCatalog() {
    _categories.addAll(const [
      MarketCategory(id: 'phones', name: 'Phones & Tablets', iconName: 'phone'),
      MarketCategory(id: 'electronics', name: 'Electronics', iconName: 'devices'),
      MarketCategory(id: 'vehicles', name: 'Vehicles', iconName: 'car'),
      MarketCategory(id: 'property', name: 'Property', iconName: 'home'),
      MarketCategory(
        id: 'furniture',
        name: 'Home & Furniture',
        iconName: 'chair',
      ),
      MarketCategory(id: 'fashion', name: 'Fashion', iconName: 'checkroom'),
    ]);

    _sellers.addAll(const [
      MarketSeller(
        id: '00000000-0000-4000-8000-000000000001',
        name: 'Hanna T.',
        phoneE164: '+251911100001',
        locationLabel: 'Bole, Addis Ababa',
      ),
      MarketSeller(
        id: '00000000-0000-4000-8000-000000000002',
        name: 'Yonas M.',
        phoneE164: '+251911100002',
        locationLabel: 'CMC, Addis Ababa',
        showPhone: false,
      ),
      MarketSeller(
        id: '00000000-0000-4000-8000-000000000003',
        name: 'Sara K.',
        phoneE164: '+251911100003',
        locationLabel: 'Piassa, Addis Ababa',
      ),
    ]);

    final now = DateTime.now();
    _ads.addAll([
      MarketAd(
        id: 'a0000000-0000-4000-8000-000000000001',
        sellerId: '00000000-0000-4000-8000-000000000001',
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
        id: 'a0000000-0000-4000-8000-000000000002',
        sellerId: '00000000-0000-4000-8000-000000000002',
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
        id: 'a0000000-0000-4000-8000-000000000003',
        sellerId: '00000000-0000-4000-8000-000000000003',
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
        id: 'a0000000-0000-4000-8000-000000000004',
        sellerId: '00000000-0000-4000-8000-000000000001',
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
        id: 'a0000000-0000-4000-8000-000000000005',
        sellerId: '00000000-0000-4000-8000-000000000002',
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
        id: 'a0000000-0000-4000-8000-000000000006',
        sellerId: '00000000-0000-4000-8000-000000000003',
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

  MarketCategory _parseCategory(Map<String, dynamic> j) {
    return MarketCategory(
      id: j['id'] as String,
      name: j['name'] as String,
      iconName: (j['iconName'] ?? j['icon_name']) as String,
    );
  }

  MarketSeller _parseSeller(Map<String, dynamic> j) {
    return MarketSeller(
      id: j['id'] as String,
      name: j['name'] as String,
      phoneE164: j['phoneE164'] as String,
      locationLabel: (j['locationLabel'] as String?) ?? 'Addis Ababa',
      showPhone: (j['showPhone'] as bool?) ?? true,
      suspended: (j['suspended'] as bool?) ?? false,
    );
  }

  SellerNotification _parseNotification(Map<String, dynamic> j) {
    return SellerNotification(
      id: j['id'] as String,
      adId: j['adId'] as String?,
      kind: j['kind'] as String,
      title: j['title'] as String,
      body: j['body'] as String,
      createdAt: DateTime.parse(j['createdAt'].toString()),
      readAt: j['readAt'] == null
          ? null
          : DateTime.tryParse(j['readAt'].toString()),
    );
  }

  MarketReportItem _parseReportItem(Map<String, dynamic> j) {
    return MarketReportItem(
      id: j['id'] as String,
      adId: j['adId'] as String,
      adTitle: (j['adTitle'] as String?) ?? 'Ad',
      sellerId: (j['sellerId'] as String?) ?? '',
      reporterId: (j['reporterId'] as String?) ?? '',
      reason: j['reason'] as String,
      status: (j['status'] as String?) ?? 'open',
      createdAt: DateTime.parse(j['createdAt'].toString()),
    );
  }

  MarketConfig _parseConfig(Map<String, dynamic> j) {
    return MarketConfig(
      maxActiveFreeAds: (j['maxActiveFreeAds'] as num?)?.toInt() ?? 5,
      phoneRevealDailyLimit:
          (j['phoneRevealDailyLimit'] as num?)?.toInt() ?? 10,
    );
  }

  MarketAd _parseAd(Map<String, dynamic> j) {
    final attrsRaw = j['attributes'];
    final attrs = <String, String>{};
    if (attrsRaw is Map) {
      attrsRaw.forEach((k, v) => attrs['$k'] = '$v');
    }
    return MarketAd(
      id: j['id'] as String,
      sellerId: j['sellerId'] as String,
      categoryId: j['categoryId'] as String,
      title: j['title'] as String,
      description: j['description'] as String,
      priceEtb: (j['priceEtb'] as num).toInt(),
      condition: AdCondition.values.byName(j['condition'] as String),
      locationLabel: j['locationLabel'] as String,
      subcity: j['subcity'] as String,
      photoUrls: (j['photoUrls'] as List).cast<String>(),
      status: AdStatus.values.byName(j['status'] as String),
      createdAt: DateTime.parse(j['createdAt'].toString()),
      rejectReason: j['rejectReason'] as String?,
      attributes: attrs,
    );
  }

  ChatThread _parseThread(Map<String, dynamic> j) {
    return ChatThread(
      id: j['id'] as String,
      adId: j['adId'] as String,
      buyerId: j['buyerId'] as String,
      sellerId: j['sellerId'] as String,
      updatedAt: DateTime.parse(j['updatedAt'].toString()),
    );
  }

  ChatMessage _parseMessage(Map<String, dynamic> j) {
    return ChatMessage(
      id: j['id'] as String,
      threadId: j['threadId'] as String,
      senderId: j['senderId'] as String,
      body: j['body'] as String,
      sentAt: DateTime.parse(j['sentAt'].toString()),
    );
  }
}
