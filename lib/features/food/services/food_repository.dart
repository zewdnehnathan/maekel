import 'dart:async';
import 'dart:math';

import '../models/food_models.dart';

abstract class FoodRepository {
  List<FoodMerchant> getMerchants({MerchantKind? kind, String query = ''});
  FoodMerchant? getMerchant(String id);
  List<MenuItem> getMenu(String merchantId);
  FoodCart getCart();
  Future<void> addToCart({
    required MenuItem item,
    required int quantity,
    List<String> modifierIds,
  });
  Future<void> updateQty(String itemId, int quantity);
  Future<void> clearCart();
  List<FoodOrder> getOrdersForCustomer(String customerId);
  FoodOrder? getOrder(String id);
  Future<FoodOrder> placeOrder({
    required String customerId,
    required DeliveryAddress address,
    required String notes,
  });
  Future<FoodOrder> cancelOrder(String orderId);
  Future<FoodOrder> completeWithOtp({
    required String orderId,
    required String otp,
  });
  /// Ops-only force advance (legacy demo).
  Future<FoodOrder> advanceOrder(String orderId);

  List<SavedPlace> getPlaces();
  Future<List<SavedPlace>> refreshPlaces();
  Future<SavedPlace> savePlace({
    required String label,
    required String subcity,
    required String details,
  });
  Future<void> deletePlace(String id);

  Future<FoodMerchant?> getMyMerchant();
  Future<List<FoodMerchant>> getClaimableMerchants();
  Future<FoodMerchant> claimMerchant(String merchantId);
  Future<FoodMerchant> setMerchantOpen(bool isOpen);
  Future<List<FoodOrder>> getMerchantOrders();
  Future<List<MenuItem>> getMerchantMenu();
  Future<MenuItem> createMenuItem({
    required String name,
    required int priceEtb,
    String description,
    String? photoUrl,
    bool available,
  });
  Future<MenuItem> updateMenuItem(
    String itemId, {
    String? name,
    int? priceEtb,
    String? description,
    String? photoUrl,
    bool? available,
  });
  Future<void> deleteMenuItem(String itemId);
  Future<FoodOrder> merchantAccept(String orderId);
  Future<FoodOrder> merchantReject(String orderId, {String reason});
  Future<FoodOrder> merchantPreparing(String orderId);
  Future<FoodOrder> merchantReady(String orderId);

  Future<RiderJobs> getRiderJobs();
  Future<FoodOrder> riderClaim(String orderId);
  Future<FoodOrder> riderPickup(String orderId);
  Future<FoodOrder> riderOnTheWay(String orderId);
  Future<FoodOrder> riderComplete(String orderId, {required String otp});

  Future<FoodOpsBoard> getOpsBoard();
  Future<FoodMerchant> opsOnboardMerchant({
    required String name,
    required MerchantKind kind,
    required String subcity,
    List<String> coverageSubcities,
    int deliveryFeeEtb,
    int minOrderEtb,
    String? ownerPhone,
  });
  Future<FoodMerchant> opsAssignOwner(
    String merchantId, {
    String? ownerPhone,
    String? ownerUserId,
  });
  Future<FoodOrder> opsReassign(String orderId, {String? riderId});
  Future<FoodOrder> opsCancel(String orderId, {String reason});

  Stream<void> get changes;
}

class InMemoryFoodRepository implements FoodRepository {
  InMemoryFoodRepository() {
    _seed();
  }

  final _controller = StreamController<void>.broadcast();
  final _merchants = <FoodMerchant>[];
  final _menu = <MenuItem>[];
  final _orders = <FoodOrder>[];
  FoodCart _cart = const FoodCart();
  int _seq = 200;
  final _rng = Random();

  void _notify() => _controller.add(null);

  String _id(String prefix) {
    _seq += 1;
    return '$prefix-$_seq';
  }

  void _seed() {
    _merchants.addAll(const [
      FoodMerchant(
        id: 'm-habesha',
        name: 'Habesha Kitfo House',
        kind: MerchantKind.restaurant,
        subcity: 'Bole',
        isOpen: true,
        etaMinutes: 35,
        deliveryFeeEtb: 80,
        minOrderEtb: 200,
        rating: 4.7,
        coverUrl:
            'https://images.unsplash.com/photo-1604329760661-eeb838b49a5c?w=900',
        hoursLabel: '10:00 – 22:00',
        coverageSubcities: ['Bole', 'CMC', 'Kirkos'],
      ),
      FoodMerchant(
        id: 'm-burger',
        name: 'Addis Burger Lab',
        kind: MerchantKind.restaurant,
        subcity: 'Kazanchis',
        isOpen: true,
        etaMinutes: 28,
        deliveryFeeEtb: 70,
        minOrderEtb: 150,
        rating: 4.5,
        coverUrl:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900',
        hoursLabel: '11:00 – 23:00',
        coverageSubcities: ['Kazanchis', 'Kirkos', 'Bole'],
      ),
      FoodMerchant(
        id: 'm-mart',
        name: 'Bole Fresh Mart',
        kind: MerchantKind.grocery,
        subcity: 'Bole',
        isOpen: true,
        etaMinutes: 40,
        deliveryFeeEtb: 60,
        minOrderEtb: 250,
        rating: 4.3,
        coverUrl:
            'https://images.unsplash.com/photo-1542838132-92c53300491e?w=900',
        hoursLabel: '08:00 – 21:00',
        coverageSubcities: ['Bole', 'CMC', 'Yeka'],
      ),
      FoodMerchant(
        id: 'm-closed',
        name: 'Piassa Pasta (closed)',
        kind: MerchantKind.restaurant,
        subcity: 'Arada',
        isOpen: false,
        etaMinutes: 45,
        deliveryFeeEtb: 90,
        minOrderEtb: 180,
        rating: 4.1,
        coverUrl:
            'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=900',
        hoursLabel: '12:00 – 20:00',
        coverageSubcities: ['Arada', 'Piassa'],
      ),
    ]);

    _menu.addAll([
      const MenuItem(
        id: 'i-kitfo',
        merchantId: 'm-habesha',
        name: 'Special Kitfo',
        description: 'Minced beef, mitmita, ayib, kocho.',
        priceEtb: 420,
        photoUrl:
            'https://images.unsplash.com/photo-1544025162-d76694265947?w=700',
        available: true,
        modifiers: [
          MenuModifier(id: 'mod-injera', name: 'Extra injera', priceEtb: 40),
          MenuModifier(id: 'mod-spicy', name: 'Extra spicy', priceEtb: 0),
        ],
      ),
      const MenuItem(
        id: 'i-tibs',
        merchantId: 'm-habesha',
        name: 'Beef Tibs',
        description: 'Sautéed beef with rosemary & peppers.',
        priceEtb: 380,
        photoUrl:
            'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=700',
        available: true,
      ),
      const MenuItem(
        id: 'i-burger',
        merchantId: 'm-burger',
        name: 'Classic Smash Burger',
        description: 'Double patty, cheddar, house sauce.',
        priceEtb: 320,
        photoUrl:
            'https://images.unsplash.com/photo-1550547660-d9450f859349?w=700',
        available: true,
        modifiers: [
          MenuModifier(id: 'mod-fries', name: 'Add fries', priceEtb: 80),
        ],
      ),
      const MenuItem(
        id: 'i-shake',
        merchantId: 'm-burger',
        name: 'Vanilla Shake',
        description: 'Thick milkshake.',
        priceEtb: 150,
        photoUrl:
            'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=700',
        available: true,
      ),
      const MenuItem(
        id: 'i-milk',
        merchantId: 'm-mart',
        name: 'Fresh Milk 1L',
        description: 'Chilled dairy.',
        priceEtb: 95,
        photoUrl:
            'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=700',
        available: true,
      ),
      const MenuItem(
        id: 'i-bread',
        merchantId: 'm-mart',
        name: 'Sliced Bread',
        description: 'Soft white loaf.',
        priceEtb: 55,
        photoUrl:
            'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=700',
        available: true,
      ),
      const MenuItem(
        id: 'i-eggs',
        merchantId: 'm-mart',
        name: 'Eggs (12)',
        description: 'Farm eggs pack.',
        priceEtb: 180,
        photoUrl:
            'https://images.unsplash.com/photo-1582722879054-132667174001?w=700',
        available: true,
      ),
    ]);
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
    if (_cart.merchantId != null && _cart.merchantId != item.merchantId) {
      throw StateError('Cart holds another restaurant. Clear cart first.');
    }
    final lines = [..._cart.lines];
    final idx = lines.indexWhere(
      (l) =>
          l.item.id == item.id &&
          _sameMods(l.selectedModifierIds, modifierIds),
    );
    if (idx >= 0) {
      lines[idx] = lines[idx].copyWith(quantity: lines[idx].quantity + quantity);
    } else {
      lines.add(
        CartLine(
          item: item,
          quantity: quantity,
          selectedModifierIds: modifierIds,
        ),
      );
    }
    _cart = FoodCart(merchantId: item.merchantId, lines: lines);
    _notify();
  }

  bool _sameMods(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort();
    final sb = [...b]..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  @override
  Future<void> updateQty(String itemId, int quantity) async {
    if (quantity <= 0) {
      final lines = _cart.lines.where((l) => l.item.id != itemId).toList();
      _cart = lines.isEmpty
          ? const FoodCart()
          : FoodCart(merchantId: _cart.merchantId, lines: lines);
    } else {
      final lines = _cart.lines
          .map((l) => l.item.id == itemId ? l.copyWith(quantity: quantity) : l)
          .toList();
      _cart = FoodCart(merchantId: _cart.merchantId, lines: lines);
    }
    _notify();
  }

  @override
  Future<void> clearCart() async {
    _cart = const FoodCart();
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
    if (_cart.isEmpty || _cart.merchantId == null) {
      throw StateError('Cart is empty');
    }
    final merchant = getMerchant(_cart.merchantId!);
    if (merchant == null || !merchant.isOpen) {
      throw StateError('Merchant unavailable');
    }
    if (_cart.subtotalEtb < merchant.minOrderEtb) {
      throw StateError('Minimum order is ${merchant.minOrderEtb} ETB');
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));
    final otp = (_rng.nextInt(900000) + 100000).toString();
    final order = FoodOrder(
      id: _id('ord'),
      customerId: customerId,
      merchantId: merchant.id,
      lines: List.unmodifiable(_cart.lines),
      address: address,
      notes: notes.trim(),
      subtotalEtb: _cart.subtotalEtb,
      deliveryFeeEtb: merchant.deliveryFeeEtb,
      paymentMethod: PaymentMethod.cashOnDelivery,
      status: OrderStatus.placed,
      deliveryOtp: otp,
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    _cart = const FoodCart();
    _notify();

    // Manual merchant/rider flow — no auto-advance in local repo either.
    return order;
  }

  @override
  Future<FoodOrder> cancelOrder(String orderId) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) throw StateError('Order not found');
    final order = _orders[idx];
    if (!order.canCancel) {
      throw StateError('Cannot cancel after preparing starts');
    }
    _orders[idx] = order.copyWith(
      status: OrderStatus.cancelled,
      cancelledAt: DateTime.now(),
    );
    _notify();
    return _orders[idx];
  }

  @override
  Future<FoodOrder> completeWithOtp({
    required String orderId,
    required String otp,
  }) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) throw StateError('Order not found');
    final order = _orders[idx];
    if (order.status != OrderStatus.onTheWay &&
        order.status != OrderStatus.pickedUp) {
      throw StateError('Order is not out for delivery yet');
    }
    if (otp.trim() != order.deliveryOtp) {
      throw StateError('Wrong delivery OTP');
    }
    _orders[idx] = order.copyWith(status: OrderStatus.delivered);
    _notify();
    return _orders[idx];
  }

  @override
  Future<FoodOrder> advanceOrder(String orderId) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) throw StateError('Order not found');
    final order = _orders[idx];
    final next = switch (order.status) {
      OrderStatus.placed => OrderStatus.confirmed,
      OrderStatus.confirmed => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.ready,
      OrderStatus.ready => OrderStatus.pickedUp,
      OrderStatus.pickedUp => OrderStatus.onTheWay,
      OrderStatus.onTheWay => order.status,
      OrderStatus.delivered => order.status,
      OrderStatus.cancelled => order.status,
    };
    _orders[idx] = order.copyWith(status: next);
    _notify();
    return _orders[idx];
  }

  final _places = <SavedPlace>[];
  String? _ownerMerchantId;

  @override
  List<SavedPlace> getPlaces() => List.unmodifiable(_places);

  @override
  Future<List<SavedPlace>> refreshPlaces() async => getPlaces();

  @override
  Future<SavedPlace> savePlace({
    required String label,
    required String subcity,
    required String details,
  }) async {
    final place = SavedPlace(
      id: _id('plc'),
      label: label,
      subcity: subcity,
      details: details,
    );
    _places.insert(0, place);
    _notify();
    return place;
  }

  @override
  Future<void> deletePlace(String id) async {
    _places.removeWhere((p) => p.id == id);
    _notify();
  }

  @override
  Future<FoodMerchant?> getMyMerchant() async {
    if (_ownerMerchantId == null) return null;
    return getMerchant(_ownerMerchantId!);
  }

  @override
  Future<List<FoodMerchant>> getClaimableMerchants() async {
    return _merchants.where((m) => m.ownerUserId == null).toList();
  }

  @override
  Future<FoodMerchant> claimMerchant(String merchantId) async {
    final idx = _merchants.indexWhere((m) => m.id == merchantId);
    if (idx < 0) throw StateError('Not found');
    _ownerMerchantId = merchantId;
    _merchants[idx] = _merchants[idx].copyWith(ownerUserId: 'local');
    _notify();
    return _merchants[idx];
  }

  @override
  Future<FoodMerchant> setMerchantOpen(bool isOpen) async {
    final id = _ownerMerchantId;
    if (id == null) throw StateError('No merchant');
    final idx = _merchants.indexWhere((m) => m.id == id);
    _merchants[idx] = _merchants[idx].copyWith(isOpen: isOpen);
    _notify();
    return _merchants[idx];
  }

  @override
  Future<List<FoodOrder>> getMerchantOrders() async {
    final id = _ownerMerchantId;
    if (id == null) return const [];
    return _orders
        .where(
          (o) =>
              o.merchantId == id &&
              o.status != OrderStatus.delivered &&
              o.status != OrderStatus.cancelled,
        )
        .toList();
  }

  @override
  Future<List<MenuItem>> getMerchantMenu() async {
    final id = _ownerMerchantId;
    if (id == null) return const [];
    return getMenu(id);
  }

  @override
  Future<MenuItem> createMenuItem({
    required String name,
    required int priceEtb,
    String description = '',
    String? photoUrl,
    bool available = true,
  }) async {
    final id = _ownerMerchantId;
    if (id == null) throw StateError('No merchant');
    final item = MenuItem(
      id: _id('i'),
      merchantId: id,
      name: name,
      description: description,
      priceEtb: priceEtb,
      photoUrl: photoUrl ??
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=700',
      available: available,
    );
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
  }) async {
    final idx = _menu.indexWhere((i) => i.id == itemId);
    if (idx < 0) throw StateError('Not found');
    final cur = _menu[idx];
    final next = MenuItem(
      id: cur.id,
      merchantId: cur.merchantId,
      name: name ?? cur.name,
      description: description ?? cur.description,
      priceEtb: priceEtb ?? cur.priceEtb,
      photoUrl: photoUrl ?? cur.photoUrl,
      available: available ?? cur.available,
      modifiers: cur.modifiers,
    );
    _menu[idx] = next;
    _notify();
    return next;
  }

  @override
  Future<void> deleteMenuItem(String itemId) async {
    _menu.removeWhere((i) => i.id == itemId);
    _notify();
  }

  @override
  Future<FoodOrder> merchantAccept(String orderId) =>
      advanceOrder(orderId);

  @override
  Future<FoodOrder> merchantReject(
    String orderId, {
    String reason = 'Rejected by merchant',
  }) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) throw StateError('Order not found');
    _orders[idx] = _orders[idx].copyWith(
      status: OrderStatus.cancelled,
      cancelledAt: DateTime.now(),
      rejectReason: reason,
    );
    _notify();
    return _orders[idx];
  }

  @override
  Future<FoodOrder> merchantPreparing(String orderId) =>
      advanceOrder(orderId);

  @override
  Future<FoodOrder> merchantReady(String orderId) => advanceOrder(orderId);

  @override
  Future<RiderJobs> getRiderJobs() async {
    final available = _orders
        .where((o) => o.status == OrderStatus.ready && o.riderId == null)
        .toList();
    final active = _orders
        .where(
          (o) =>
              o.riderId == 'local' &&
              (o.status == OrderStatus.ready ||
                  o.status == OrderStatus.pickedUp ||
                  o.status == OrderStatus.onTheWay),
        )
        .toList();
    return RiderJobs(available: available, active: active);
  }

  @override
  Future<FoodOrder> riderClaim(String orderId) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) throw StateError('Not found');
    _orders[idx] = _orders[idx].copyWith(riderId: 'local');
    _notify();
    return _orders[idx];
  }

  @override
  Future<FoodOrder> riderPickup(String orderId) => advanceOrder(orderId);

  @override
  Future<FoodOrder> riderOnTheWay(String orderId) => advanceOrder(orderId);

  @override
  Future<FoodOrder> riderComplete(
    String orderId, {
    required String otp,
  }) =>
      completeWithOtp(orderId: orderId, otp: otp);

  @override
  Future<FoodOpsBoard> getOpsBoard() async {
    return FoodOpsBoard(orders: List.unmodifiable(_orders), merchants: _merchants);
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
    final m = FoodMerchant(
      id: _id('m'),
      name: name,
      kind: kind,
      subcity: subcity,
      isOpen: true,
      etaMinutes: 35,
      deliveryFeeEtb: deliveryFeeEtb,
      minOrderEtb: minOrderEtb,
      rating: 4.0,
      coverUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=900',
      hoursLabel: '10:00 – 22:00',
      ownerUserId: ownerPhone != null ? 'local-owner' : null,
      coverageSubcities:
          coverageSubcities.isEmpty ? [subcity] : coverageSubcities,
    );
    _merchants.add(m);
    _notify();
    return m;
  }

  @override
  Future<FoodMerchant> opsAssignOwner(
    String merchantId, {
    String? ownerPhone,
    String? ownerUserId,
  }) async {
    final idx = _merchants.indexWhere((m) => m.id == merchantId);
    if (idx < 0) throw StateError('Not found');
    _merchants[idx] = _merchants[idx].copyWith(
      ownerUserId: ownerUserId ?? (ownerPhone != null ? 'local-owner' : null),
    );
    _notify();
    return _merchants[idx];
  }

  @override
  Future<FoodOrder> opsReassign(String orderId, {String? riderId}) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) throw StateError('Not found');
    _orders[idx] = _orders[idx].copyWith(
      riderId: riderId,
      clearRiderId: riderId == null,
    );
    _notify();
    return _orders[idx];
  }

  @override
  Future<FoodOrder> opsCancel(
    String orderId, {
    String reason = 'Cancelled by support',
  }) async {
    return merchantReject(orderId, reason: reason);
  }
}
