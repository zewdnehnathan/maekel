import 'dart:async';

import '../../../core/network/api_client.dart';
import '../models/food_models.dart';
import 'food_repository.dart';

/// HTTP food repo with an in-memory cache refreshed from the API.
class ApiFoodRepository implements FoodRepository {
  ApiFoodRepository(this._client) {
    unawaited(refreshCatalog());
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_pollActive());
    });
  }

  final ApiClient _client;
  final _controller = StreamController<void>.broadcast();
  Timer? _poll;

  final List<FoodMerchant> _merchants = [];
  final List<MenuItem> _menu = [];
  final List<FoodOrder> _orders = [];
  final List<SavedPlace> _places = [];
  FoodCart _cart = const FoodCart();
  bool _authed = false;

  void dispose() {
    _poll?.cancel();
    _controller.close();
  }

  void _notify() => _controller.add(null);

  Future<void> refreshCatalog() async {
    try {
      final merchantsRaw = await _client.get('/v1/food/merchants');
      final merchants = ((merchantsRaw as Map)['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(_parseMerchant)
          .toList();
      final menu = <MenuItem>[];
      for (final m in merchants) {
        final menuRaw = await _client.get('/v1/food/merchants/${m.id}/menu');
        menu.addAll(
          ((menuRaw as Map)['items'] as List)
              .cast<Map<String, dynamic>>()
              .map(_parseMenuItem),
        );
      }
      _merchants
        ..clear()
        ..addAll(merchants);
      _menu
        ..clear()
        ..addAll(menu);
      _notify();
    } catch (_) {
      // Keep local seed.
    }
  }

  Future<void> refreshAuthed() async {
    _authed = true;
    try {
      final cartRaw =
          await _client.get('/v1/food/cart', auth: true) as Map<String, dynamic>;
      _cart = _parseCart(cartRaw);
      final ordersRaw = await _client.get('/v1/food/orders', auth: true);
      _orders
        ..clear()
        ..addAll(
          ((ordersRaw as Map)['items'] as List)
              .cast<Map<String, dynamic>>()
              .map(_parseOrder),
        );
      await refreshPlaces();
      _notify();
    } catch (_) {
      _notify();
    }
  }

  void clearAuthed() {
    _authed = false;
    _orders.clear();
    _cart = const FoodCart();
    _places.clear();
    _notify();
  }

  Future<void> _pollActive() async {
    if (!_authed) return;
    try {
      // Always refresh customer orders so status stays live.
      final ordersRaw = await _client.get('/v1/food/orders', auth: true);
      _orders
        ..clear()
        ..addAll(
          ((ordersRaw as Map)['items'] as List)
              .cast<Map<String, dynamic>>()
              .map(_parseOrder),
        );
      _notify();
    } catch (_) {
      // Keep last known orders; next tick retries.
    }
  }

  @override
  Stream<void> get changes => _controller.stream;

  @override
  List<FoodMerchant> getMerchants({MerchantKind? kind, String query = ''}) {
    Iterable<FoodMerchant> list = _merchants;
    if (kind != null) {
      list = list.where((m) => m.kind == kind);
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((m) {
        if (m.name.toLowerCase().contains(q) ||
            m.subcity.toLowerCase().contains(q)) {
          return true;
        }
        return _menu.any(
          (i) =>
              i.merchantId == m.id &&
              (i.name.toLowerCase().contains(q) ||
                  i.description.toLowerCase().contains(q)),
        );
      });
    }
    return list.toList();
  }

  @override
  FoodMerchant? getMerchant(String id) {
    for (final m in _merchants) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  List<MenuItem> getMenu(String merchantId) {
    return _menu.where((i) => i.merchantId == merchantId).toList();
  }

  @override
  FoodCart getCart() => _cart;

  @override
  Future<void> addToCart({
    required MenuItem item,
    required int quantity,
    List<String> modifierIds = const [],
  }) async {
    if (!item.available) {
      throw StateError('This item is unavailable right now.');
    }
    final raw = await _client.post(
      '/v1/food/cart/items',
      auth: true,
      body: {
        'itemId': item.id,
        'quantity': quantity,
        'modifierIds': modifierIds,
      },
    ) as Map<String, dynamic>;
    _cart = _parseCart(raw);
    _notify();
  }

  @override
  Future<void> updateQty(String itemId, int quantity) async {
    final raw = await _client.patch(
      '/v1/food/cart/items/$itemId',
      auth: true,
      body: {'quantity': quantity},
    ) as Map<String, dynamic>;
    _cart = _parseCart(raw);
    _notify();
  }

  @override
  Future<void> clearCart() async {
    final raw =
        await _client.delete('/v1/food/cart', auth: true) as Map<String, dynamic>;
    _cart = _parseCart(raw);
    _notify();
  }

  @override
  List<FoodOrder> getOrdersForCustomer(String customerId) {
    final list = _orders.where((o) => o.customerId == customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  FoodOrder? getOrder(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  @override
  Future<FoodOrder> placeOrder({
    required String customerId,
    required DeliveryAddress address,
    required String notes,
  }) async {
    final raw = await _client.post(
      '/v1/food/orders',
      auth: true,
      body: {
        'address': {
          'label': address.label,
          'subcity': address.subcity,
          'details': address.details,
        },
        'notes': notes,
      },
    ) as Map<String, dynamic>;
    final order = _parseOrder(raw);
    _orders.insert(0, order);
    _cart = const FoodCart();
    _notify();
    return order;
  }

  @override
  Future<FoodOrder> cancelOrder(String orderId) async {
    final raw = await _client.post(
      '/v1/food/orders/$orderId/cancel',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<FoodOrder> completeWithOtp({
    required String orderId,
    required String otp,
  }) async {
    final raw = await _client.post(
      '/v1/food/orders/$orderId/complete',
      auth: true,
      body: {'otp': otp},
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<FoodOrder> advanceOrder(String orderId) async {
    final raw = await _client.post(
      '/v1/food/orders/$orderId/advance',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  List<SavedPlace> getPlaces() => List.unmodifiable(_places);

  @override
  Future<List<SavedPlace>> refreshPlaces() async {
    final raw = await _client.get('/v1/food/places', auth: true);
    _places
      ..clear()
      ..addAll(
        ((raw as Map)['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(_parsePlace),
      );
    _notify();
    return getPlaces();
  }

  @override
  Future<SavedPlace> savePlace({
    required String label,
    required String subcity,
    required String details,
  }) async {
    final raw = await _client.post(
      '/v1/food/places',
      auth: true,
      body: {'label': label, 'subcity': subcity, 'details': details},
    ) as Map<String, dynamic>;
    final place = _parsePlace(raw);
    _places.insert(0, place);
    _notify();
    return place;
  }

  @override
  Future<void> deletePlace(String id) async {
    await _client.delete('/v1/food/places/$id', auth: true);
    _places.removeWhere((p) => p.id == id);
    _notify();
  }

  @override
  Future<FoodMerchant?> getMyMerchant() async {
    final raw = await _client.get('/v1/food/merchant/me', auth: true)
        as Map<String, dynamic>;
    final m = raw['merchant'];
    if (m == null) return null;
    return _parseMerchant(m as Map<String, dynamic>);
  }

  @override
  Future<List<FoodMerchant>> getClaimableMerchants() async {
    final raw = await _client.get('/v1/food/merchant/claimable', auth: true);
    return ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(_parseMerchant)
        .toList();
  }

  @override
  Future<FoodMerchant> claimMerchant(String merchantId) async {
    final raw = await _client.post(
      '/v1/food/merchant/claim',
      auth: true,
      body: {'merchantId': merchantId},
    ) as Map<String, dynamic>;
    final merchant = _parseMerchant(raw);
    final idx = _merchants.indexWhere((m) => m.id == merchant.id);
    if (idx >= 0) {
      _merchants[idx] = merchant;
    } else {
      _merchants.add(merchant);
    }
    _notify();
    return merchant;
  }

  @override
  Future<FoodMerchant> setMerchantOpen(bool isOpen) async {
    final raw = await _client.patch(
      '/v1/food/merchant/me',
      auth: true,
      body: {'isOpen': isOpen},
    ) as Map<String, dynamic>;
    final merchant = _parseMerchant(raw);
    final idx = _merchants.indexWhere((m) => m.id == merchant.id);
    if (idx >= 0) _merchants[idx] = merchant;
    _notify();
    return merchant;
  }

  @override
  Future<List<FoodOrder>> getMerchantOrders() async {
    final raw = await _client.get('/v1/food/merchant/orders', auth: true);
    final items = ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(_parseOrder)
        .toList();
    for (final o in items) {
      _upsertOrder(o);
    }
    return items;
  }

  @override
  Future<List<MenuItem>> getMerchantMenu() async {
    final raw = await _client.get('/v1/food/merchant/menu', auth: true);
    final items = ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(_parseMenuItem)
        .toList();
    for (final item in items) {
      final idx = _menu.indexWhere((m) => m.id == item.id);
      if (idx >= 0) {
        _menu[idx] = item;
      } else {
        _menu.add(item);
      }
    }
    _notify();
    return items;
  }

  @override
  Future<String> uploadDishPhoto({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final raw = await _client.postMultipart(
      '/v1/food/merchant/media',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      auth: true,
    ) as Map<String, dynamic>;
    return raw['url'] as String;
  }

  @override
  Future<MenuItem> createMenuItem({
    required String name,
    required int priceEtb,
    String description = '',
    String? photoUrl,
    bool available = true,
    List<MenuModifier> modifiers = const [],
  }) async {
    final raw = await _client.post(
      '/v1/food/merchant/menu',
      auth: true,
      body: {
        'name': name,
        'description': description,
        'priceEtb': priceEtb,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'available': available,
        'modifiers': [
          for (final m in modifiers)
            {
              if (m.id.isNotEmpty) 'id': m.id,
              'name': m.name,
              'priceEtb': m.priceEtb,
            },
        ],
      },
    ) as Map<String, dynamic>;
    final item = _parseMenuItem(raw);
    _menu.add(item);
    _notify();
    return item;
  }

  @override
  Future<MenuItem> updateMenuItem(
    String itemId, {
    String? name,
    int? priceEtb,
    String? description,
    String? photoUrl,
    bool? available,
    List<MenuModifier>? modifiers,
  }) async {
    final raw = await _client.patch(
      '/v1/food/merchant/menu/$itemId',
      auth: true,
      body: {
        if (name != null) 'name': name,
        if (priceEtb != null) 'priceEtb': priceEtb,
        if (description != null) 'description': description,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (available != null) 'available': available,
        if (modifiers != null)
          'modifiers': [
            for (final m in modifiers)
              {
                if (m.id.isNotEmpty) 'id': m.id,
                'name': m.name,
                'priceEtb': m.priceEtb,
              },
          ],
      },
    ) as Map<String, dynamic>;
    final item = _parseMenuItem(raw);
    final idx = _menu.indexWhere((m) => m.id == item.id);
    if (idx >= 0) {
      _menu[idx] = item;
    } else {
      _menu.add(item);
    }
    _notify();
    return item;
  }

  @override
  Future<void> deleteMenuItem(String itemId) async {
    await _client.delete('/v1/food/merchant/menu/$itemId', auth: true);
    _menu.removeWhere((m) => m.id == itemId);
    _notify();
  }

  @override
  Future<FoodOrder> merchantAccept(String orderId) async {
    final raw = await _client.post(
      '/v1/food/merchant/orders/$orderId/accept',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<FoodOrder> merchantReject(
    String orderId, {
    String reason = 'Rejected by merchant',
  }) async {
    final raw = await _client.post(
      '/v1/food/merchant/orders/$orderId/reject',
      auth: true,
      body: {'reason': reason},
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<FoodOrder> merchantPreparing(String orderId) async {
    final raw = await _client.post(
      '/v1/food/merchant/orders/$orderId/preparing',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<FoodOrder> merchantReady(String orderId) async {
    final raw = await _client.post(
      '/v1/food/merchant/orders/$orderId/ready',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<RiderJobs> getRiderJobs() async {
    final raw = await _client.get('/v1/food/rider/jobs', auth: true)
        as Map<String, dynamic>;
    return RiderJobs(
      available: ((raw['available'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_parseOrder)
          .toList(),
      active: ((raw['active'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_parseOrder)
          .toList(),
    );
  }

  @override
  Future<FoodOrder> riderClaim(String orderId) async {
    final raw = await _client.post(
      '/v1/food/rider/jobs/$orderId/claim',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<FoodOrder> riderPickup(String orderId) async {
    final raw = await _client.post(
      '/v1/food/rider/jobs/$orderId/pickup',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<FoodOrder> riderOnTheWay(String orderId) async {
    final raw = await _client.post(
      '/v1/food/rider/jobs/$orderId/on-the-way',
      auth: true,
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<FoodOrder> riderComplete(
    String orderId, {
    required String otp,
  }) async {
    final raw = await _client.post(
      '/v1/food/rider/jobs/$orderId/complete',
      auth: true,
      body: {'otp': otp},
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<FoodOpsBoard> getOpsBoard() async {
    final raw = await _client.get('/v1/food/ops/board', auth: true)
        as Map<String, dynamic>;
    return FoodOpsBoard(
      orders: ((raw['orders'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_parseOrder)
          .toList(),
      merchants: ((raw['merchants'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_parseMerchant)
          .toList(),
    );
  }

  @override
  Future<FoodMerchant> opsOnboardMerchant({
    required String name,
    required MerchantKind kind,
    required String subcity,
    List<String> coverageSubcities = const [],
    int deliveryFeeEtb = 70,
    int minOrderEtb = 150,
    String? ownerPhone,
  }) async {
    final raw = await _client.post(
      '/v1/food/ops/merchants',
      auth: true,
      body: {
        'name': name,
        'kind': kind.name,
        'subcity': subcity,
        'coverageSubcities': coverageSubcities,
        'deliveryFeeEtb': deliveryFeeEtb,
        'minOrderEtb': minOrderEtb,
        if (ownerPhone != null && ownerPhone.isNotEmpty)
          'ownerPhone': ownerPhone,
      },
    ) as Map<String, dynamic>;
    final merchant = _parseMerchant(raw);
    _merchants.add(merchant);
    _notify();
    return merchant;
  }

  @override
  Future<FoodMerchant> opsAssignOwner(
    String merchantId, {
    String? ownerPhone,
    String? ownerUserId,
  }) async {
    final raw = await _client.post(
      '/v1/food/ops/merchants/$merchantId/assign-owner',
      auth: true,
      body: {
        if (ownerPhone != null) 'ownerPhone': ownerPhone,
        if (ownerUserId != null) 'ownerUserId': ownerUserId,
        if (ownerPhone == null && ownerUserId == null) 'ownerUserId': null,
      },
    ) as Map<String, dynamic>;
    final merchant = _parseMerchant(raw);
    final idx = _merchants.indexWhere((m) => m.id == merchant.id);
    if (idx >= 0) {
      _merchants[idx] = merchant;
    }
    _notify();
    return merchant;
  }

  @override
  Future<FoodOrder> opsReassign(String orderId, {String? riderId}) async {
    final raw = await _client.post(
      '/v1/food/ops/orders/$orderId/reassign',
      auth: true,
      body: {'riderId': riderId},
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<FoodOrder> opsCancel(
    String orderId, {
    String reason = 'Cancelled by support',
  }) async {
    final raw = await _client.post(
      '/v1/food/ops/orders/$orderId/cancel',
      auth: true,
      body: {'reason': reason},
    ) as Map<String, dynamic>;
    return _upsertOrder(_parseOrder(raw));
  }

  @override
  Future<String> uploadApplicationMedia({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final raw = await _client.postMultipart(
      '/v1/food/applications/media',
      auth: true,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    ) as Map<String, dynamic>;
    return raw['id'] as String;
  }

  @override
  Future<FoodApplication> submitApplication({
    required FoodApplicationKind kind,
    required String title,
    required String subcity,
    String? licenseMediaId,
  }) async {
    final raw = await _client.post(
      '/v1/food/applications',
      auth: true,
      body: {
        'kind': kind == FoodApplicationKind.deliveryOrg
            ? 'delivery_org'
            : 'restaurant',
        'title': title,
        'subcity': subcity,
        if (licenseMediaId != null) 'licenseMediaId': licenseMediaId,
      },
    ) as Map<String, dynamic>;
    return _parseApplication(raw);
  }

  @override
  Future<List<FoodApplication>> myApplications() async {
    final raw = await _client.get('/v1/food/applications/mine', auth: true);
    return ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(_parseApplication)
        .toList();
  }

  @override
  Future<List<FoodApplication>> opsListApplications({
    String status = 'pending',
  }) async {
    final raw = await _client.get(
      '/v1/food/ops/applications',
      auth: true,
      query: {'status': status},
    );
    return ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(_parseApplication)
        .toList();
  }

  @override
  Future<void> opsApproveApplication(String id, {String? note}) async {
    await _client.post(
      '/v1/food/ops/applications/$id/approve',
      auth: true,
      body: {if (note != null) 'note': note},
    );
  }

  @override
  Future<void> opsRejectApplication(
    String id, {
    String note = 'Rejected',
  }) async {
    await _client.post(
      '/v1/food/ops/applications/$id/reject',
      auth: true,
      body: {'note': note},
    );
  }

  @override
  Future<FoodMerchant> setSelfDelivery(bool enabled) async {
    final raw = await _client.patch(
      '/v1/food/merchant/self-delivery',
      auth: true,
      body: {'enabled': enabled},
    ) as Map<String, dynamic>;
    final merchant = _parseMerchant(raw);
    final idx = _merchants.indexWhere((m) => m.id == merchant.id);
    if (idx >= 0) {
      _merchants[idx] = merchant;
    }
    _notify();
    return merchant;
  }

  @override
  Future<List<DeliveryMember>> getMerchantRiders() async {
    final raw = await _client.get('/v1/food/merchant/riders', auth: true);
    return ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (j) => DeliveryMember(
            riderUserId: j['riderUserId'] as String,
            phone: j['phone'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<DeliveryMember> addMerchantRider(String phone) async {
    final raw = await _client.post(
      '/v1/food/merchant/riders',
      auth: true,
      body: {'phone': phone},
    ) as Map<String, dynamic>;
    return DeliveryMember(
      riderUserId: raw['riderUserId'] as String,
      phone: raw['phone'] as String,
    );
  }

  @override
  Future<void> removeMerchantRider(String riderUserId) async {
    await _client.delete(
      '/v1/food/merchant/riders/$riderUserId',
      auth: true,
    );
  }

  @override
  Future<DeliveryOrg> getDeliveryOrg() async {
    final raw = await _client.get('/v1/food/delivery/org', auth: true)
        as Map<String, dynamic>;
    return DeliveryOrg(
      id: raw['id'] as String,
      name: raw['name'] as String,
      ownerUserId: raw['ownerUserId'] as String,
      ownerPhone: raw['ownerPhone'] as String?,
      isActive: raw['isActive'] as bool? ?? true,
    );
  }

  @override
  Future<List<DeliveryMember>> getDeliveryMembers() async {
    final raw = await _client.get('/v1/food/delivery/members', auth: true);
    return ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (j) => DeliveryMember(
            riderUserId: j['riderUserId'] as String,
            phone: j['phone'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<DeliveryMember> addDeliveryMember(String phone) async {
    final raw = await _client.post(
      '/v1/food/delivery/members',
      auth: true,
      body: {'phone': phone},
    ) as Map<String, dynamic>;
    return DeliveryMember(
      riderUserId: raw['riderUserId'] as String,
      phone: raw['phone'] as String,
    );
  }

  @override
  Future<void> removeDeliveryMember(String riderUserId) async {
    await _client.delete(
      '/v1/food/delivery/members/$riderUserId',
      auth: true,
    );
  }

  @override
  Future<List<FoodOrder>> getDeliveryActiveOrders() async {
    final raw =
        await _client.get('/v1/food/delivery/active-orders', auth: true);
    return ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(_parseOrder)
        .toList();
  }

  @override
  Future<List<FoodOrder>> getDeliveryReportableOrders() async {
    final raw =
        await _client.get('/v1/food/delivery/reportable-orders', auth: true);
    return ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(_parseOrder)
        .toList();
  }

  @override
  Future<CustomerReport> reportCustomer({
    required String orderId,
    String reason = 'customer_no_show',
    String? note,
  }) async {
    final raw = await _client.post(
      '/v1/food/reports',
      auth: true,
      body: {
        'orderId': orderId,
        'reason': reason,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    ) as Map<String, dynamic>;
    return _parseReport(raw);
  }

  @override
  Future<List<CustomerReport>> opsListReports({
    String status = 'pending',
  }) async {
    final raw = await _client.get(
      '/v1/food/ops/reports',
      auth: true,
      query: {'status': status},
    );
    return ((raw as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(_parseReport)
        .toList();
  }

  @override
  Future<CustomerReport> opsReviewReport(
    String id, {
    required String action,
    String? message,
    String? note,
  }) async {
    final raw = await _client.post(
      '/v1/food/ops/reports/$id/review',
      auth: true,
      body: {
        'action': action,
        if (message != null) 'message': message,
        if (note != null) 'note': note,
      },
    ) as Map<String, dynamic>;
    return _parseReport(raw);
  }

  CustomerReport _parseReport(Map<String, dynamic> j) {
    return CustomerReport(
      id: j['id'] as String,
      orderId: j['orderId'] as String,
      customerId: j['customerId'] as String,
      reporterUserId: j['reporterUserId'] as String,
      reporterKind: j['reporterKind'] as String? ?? '',
      reason: j['reason'] as String? ?? 'customer_no_show',
      status: CustomerReportStatus.values.byName(j['status'] as String),
      note: j['note'] as String?,
      reviewNote: j['reviewNote'] as String?,
      createdAt: j['createdAt'] == null
          ? null
          : DateTime.tryParse(j['createdAt'].toString()),
    );
  }

  FoodApplication _parseApplication(Map<String, dynamic> j) {
    final kindRaw = j['kind'] as String;
    return FoodApplication(
      id: j['id'] as String,
      kind: kindRaw == 'delivery_org'
          ? FoodApplicationKind.deliveryOrg
          : FoodApplicationKind.restaurant,
      applicantUserId: j['applicantUserId'] as String,
      applicantPhone: j['applicantPhone'] as String? ?? '',
      title: j['title'] as String,
      subcity: j['subcity'] as String? ?? 'Bole',
      status: FoodApplicationStatus.values.byName(j['status'] as String),
      licenseMediaId: j['licenseMediaId'] as String?,
      reviewNote: j['reviewNote'] as String?,
      createdAt: j['createdAt'] == null
          ? null
          : DateTime.tryParse(j['createdAt'].toString()),
    );
  }

  FoodOrder _upsertOrder(FoodOrder order) {
    final idx = _orders.indexWhere((o) => o.id == order.id);
    if (idx >= 0) {
      _orders[idx] = order;
    } else {
      _orders.insert(0, order);
    }
    _notify();
    return order;
  }

  SavedPlace _parsePlace(Map<String, dynamic> j) {
    return SavedPlace(
      id: j['id'] as String,
      label: j['label'] as String,
      subcity: j['subcity'] as String,
      details: j['details'] as String,
    );
  }

  FoodMerchant _parseMerchant(Map<String, dynamic> j) {
    final coverage = <String>[];
    final rawCov = j['coverageSubcities'];
    if (rawCov is List) {
      coverage.addAll(rawCov.map((e) => '$e'));
    }
    return FoodMerchant(
      id: j['id'] as String,
      name: j['name'] as String,
      kind: MerchantKind.values.byName(j['kind'] as String),
      subcity: j['subcity'] as String,
      isOpen: j['isOpen'] as bool,
      etaMinutes: (j['etaMinutes'] as num).toInt(),
      deliveryFeeEtb: (j['deliveryFeeEtb'] as num).toInt(),
      minOrderEtb: (j['minOrderEtb'] as num).toInt(),
      rating: (j['rating'] as num).toDouble(),
      coverUrl: j['coverUrl'] as String,
      hoursLabel: j['hoursLabel'] as String,
      ownerUserId: j['ownerUserId'] as String?,
      ownerPhone: j['ownerPhone'] as String?,
      selfDelivery: j['selfDelivery'] as bool? ?? false,
      coverageSubcities: coverage,
    );
  }

  MenuItem _parseMenuItem(Map<String, dynamic> j) {
    final mods = <MenuModifier>[];
    final rawMods = j['modifiers'];
    if (rawMods is List) {
      for (final m in rawMods) {
        if (m is Map<String, dynamic>) {
          mods.add(
            MenuModifier(
              id: m['id'] as String,
              name: m['name'] as String,
              priceEtb: (m['priceEtb'] as num).toInt(),
            ),
          );
        }
      }
    }
    return MenuItem(
      id: j['id'] as String,
      merchantId: j['merchantId'] as String,
      name: j['name'] as String,
      description: j['description'] as String,
      priceEtb: (j['priceEtb'] as num).toInt(),
      photoUrl: j['photoUrl'] as String,
      available: j['available'] as bool? ?? true,
      modifiers: mods,
    );
  }

  FoodCart _parseCart(Map<String, dynamic> j) {
    final lines = <CartLine>[];
    final rawLines = j['lines'];
    if (rawLines is List) {
      for (final line in rawLines) {
        if (line is Map<String, dynamic>) {
          final item = _parseMenuItem(line['item'] as Map<String, dynamic>);
          lines.add(
            CartLine(
              item: item,
              quantity: (line['quantity'] as num).toInt(),
              selectedModifierIds:
                  (line['selectedModifierIds'] as List? ?? const [])
                      .cast<String>(),
            ),
          );
        }
      }
    }
    return FoodCart(
      merchantId: j['merchantId'] as String?,
      lines: lines,
    );
  }

  FoodOrder _parseOrder(Map<String, dynamic> j) {
    final addressRaw = j['address'] as Map<String, dynamic>;
    final lines = <CartLine>[];
    final rawLines = j['lines'];
    if (rawLines is List) {
      for (final line in rawLines) {
        if (line is Map<String, dynamic>) {
          final item = _parseMenuItem(line['item'] as Map<String, dynamic>);
          lines.add(
            CartLine(
              item: item,
              quantity: (line['quantity'] as num).toInt(),
              selectedModifierIds:
                  (line['selectedModifierIds'] as List? ?? const [])
                      .cast<String>(),
            ),
          );
        }
      }
    }
    return FoodOrder(
      id: j['id'] as String,
      customerId: j['customerId'] as String,
      merchantId: j['merchantId'] as String,
      lines: lines,
      address: DeliveryAddress(
        label: addressRaw['label'] as String,
        subcity: addressRaw['subcity'] as String,
        details: addressRaw['details'] as String,
      ),
      notes: (j['notes'] as String?) ?? '',
      subtotalEtb: (j['subtotalEtb'] as num).toInt(),
      deliveryFeeEtb: (j['deliveryFeeEtb'] as num).toInt(),
      paymentMethod: PaymentMethod.cashOnDelivery,
      status: OrderStatus.values.byName(j['status'] as String),
      deliveryOtp: j['deliveryOtp'] as String,
      createdAt: DateTime.parse(j['createdAt'].toString()),
      cancelledAt: j['cancelledAt'] == null
          ? null
          : DateTime.parse(j['cancelledAt'].toString()),
      riderId: j['riderId'] as String?,
      rejectReason: j['rejectReason'] as String?,
    );
  }
}
