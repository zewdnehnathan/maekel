enum MerchantKind { restaurant, grocery }

enum OrderStatus {
  placed,
  confirmed,
  preparing,
  ready,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
}

enum PaymentMethod { cashOnDelivery }

class DeliveryAddress {
  const DeliveryAddress({
    required this.label,
    required this.subcity,
    required this.details,
  });

  final String label;
  final String subcity;
  final String details;
}

class MenuModifier {
  const MenuModifier({
    required this.id,
    required this.name,
    required this.priceEtb,
  });

  final String id;
  final String name;
  final int priceEtb;
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.description,
    required this.priceEtb,
    required this.photoUrl,
    required this.available,
    this.modifiers = const [],
  });

  final String id;
  final String merchantId;
  final String name;
  final String description;
  final int priceEtb;
  final String photoUrl;
  final bool available;
  final List<MenuModifier> modifiers;
}

class FoodMerchant {
  const FoodMerchant({
    required this.id,
    required this.name,
    required this.kind,
    required this.subcity,
    required this.isOpen,
    required this.etaMinutes,
    required this.deliveryFeeEtb,
    required this.minOrderEtb,
    required this.rating,
    required this.coverUrl,
    required this.hoursLabel,
  });

  final String id;
  final String name;
  final MerchantKind kind;
  final String subcity;
  final bool isOpen;
  final int etaMinutes;
  final int deliveryFeeEtb;
  final int minOrderEtb;
  final double rating;
  final String coverUrl;
  final String hoursLabel;
}

class CartLine {
  const CartLine({
    required this.item,
    required this.quantity,
    this.selectedModifierIds = const [],
  });

  final MenuItem item;
  final int quantity;
  final List<String> selectedModifierIds;

  int get unitPrice {
    var total = item.priceEtb;
    for (final mod in item.modifiers) {
      if (selectedModifierIds.contains(mod.id)) {
        total += mod.priceEtb;
      }
    }
    return total;
  }

  int get lineTotal => unitPrice * quantity;

  CartLine copyWith({int? quantity, List<String>? selectedModifierIds}) {
    return CartLine(
      item: item,
      quantity: quantity ?? this.quantity,
      selectedModifierIds: selectedModifierIds ?? this.selectedModifierIds,
    );
  }
}

class FoodCart {
  const FoodCart({this.merchantId, this.lines = const []});

  final String? merchantId;
  final List<CartLine> lines;

  int get subtotalEtb =>
      lines.fold<int>(0, (sum, line) => sum + line.lineTotal);

  bool get isEmpty => lines.isEmpty;

  FoodCart copyWith({String? merchantId, List<CartLine>? lines}) {
    return FoodCart(
      merchantId: merchantId ?? this.merchantId,
      lines: lines ?? this.lines,
    );
  }
}

class FoodOrder {
  const FoodOrder({
    required this.id,
    required this.customerId,
    required this.merchantId,
    required this.lines,
    required this.address,
    required this.notes,
    required this.subtotalEtb,
    required this.deliveryFeeEtb,
    required this.paymentMethod,
    required this.status,
    required this.deliveryOtp,
    required this.createdAt,
    this.cancelledAt,
  });

  final String id;
  final String customerId;
  final String merchantId;
  final List<CartLine> lines;
  final DeliveryAddress address;
  final String notes;
  final int subtotalEtb;
  final int deliveryFeeEtb;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final String deliveryOtp;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  int get grandTotalEtb => subtotalEtb + deliveryFeeEtb;

  bool get canCancel =>
      status == OrderStatus.placed || status == OrderStatus.confirmed;

  FoodOrder copyWith({OrderStatus? status, DateTime? cancelledAt}) {
    return FoodOrder(
      id: id,
      customerId: customerId,
      merchantId: merchantId,
      lines: lines,
      address: address,
      notes: notes,
      subtotalEtb: subtotalEtb,
      deliveryFeeEtb: deliveryFeeEtb,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      deliveryOtp: deliveryOtp,
      createdAt: createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for pickup';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.onTheWay:
        return 'On the way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

extension MerchantKindLabel on MerchantKind {
  String get label => this == MerchantKind.restaurant ? 'Restaurants' : 'Groceries';
}
