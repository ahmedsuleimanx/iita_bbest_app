import 'package:equatable/equatable.dart';
import 'cart_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }
}

enum PaymentMethod {
  mobileMoney,
  bankTransfer,
  cashOnDelivery,
  card,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.card:
        return 'Card Payment';
    }
  }

  static PaymentMethod fromString(String method) {
    switch (method.toLowerCase()) {
      case 'mobilemoney':
      case 'mobile_money':
      case 'mobile money':
        return PaymentMethod.mobileMoney;
      case 'banktransfer':
      case 'bank_transfer':
      case 'bank transfer':
        return PaymentMethod.bankTransfer;
      case 'cashondelivery':
      case 'cash_on_delivery':
      case 'cash on delivery':
        return PaymentMethod.cashOnDelivery;
      case 'card':
        return PaymentMethod.card;
      default:
        return PaymentMethod.cashOnDelivery;
    }
  }
}

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double totalAmount;
  final double shippingFee;
  final double tax;
  final double grandTotal;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String deliveryAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final String? trackingNumber;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    this.shippingFee = 0.0,
    this.tax = 0.0,
    required this.grandTotal,
    this.status = OrderStatus.pending,
    required this.paymentMethod,
    required this.deliveryAddress,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.trackingNumber,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  bool get canBeCancelled {
    return status == OrderStatus.pending || status == OrderStatus.confirmed;
  }

  bool get isCompleted => status == OrderStatus.delivered;

  bool get isCancelled => status == OrderStatus.cancelled;

  factory OrderModel.fromCart({
    required String id,
    required CartModel cart,
    required PaymentMethod paymentMethod,
    required String deliveryAddress,
    String? notes,
    double shippingFee = 0.0,
    double tax = 0.0,
  }) {
    final totalAmount = cart.totalAmount;
    final grandTotal = totalAmount + shippingFee + tax;

    return OrderModel(
      id: id,
      userId: cart.userId,
      items: cart.items,
      totalAmount: totalAmount,
      shippingFee: shippingFee,
      tax: tax,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items: List<CartItemModel>.from(
        (map['items'] ?? []).map((item) => CartItemModel.fromMap(item)),
      ),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      shippingFee: (map['shippingFee'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      grandTotal: (map['grandTotal'] ?? 0).toDouble(),
      status: OrderStatusExtension.fromString(map['status'] ?? ''),
      paymentMethod: PaymentMethodExtension.fromString(map['paymentMethod'] ?? ''),
      deliveryAddress: map['deliveryAddress'] ?? '',
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      deliveredAt: map['deliveredAt'] != null ? DateTime.parse(map['deliveredAt']) : null,
      trackingNumber: map['trackingNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'shippingFee': shippingFee,
      'tax': tax,
      'grandTotal': grandTotal,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'deliveryAddress': deliveryAddress,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'trackingNumber': trackingNumber,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    List<CartItemModel>? items,
    double? totalAmount,
    double? shippingFee,
    double? tax,
    double? grandTotal,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? deliveryAddress,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    String? trackingNumber,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      tax: tax ?? this.tax,
      grandTotal: grandTotal ?? this.grandTotal,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      trackingNumber: trackingNumber ?? this.trackingNumber,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        totalAmount,
        shippingFee,
        tax,
        grandTotal,
        status,
        paymentMethod,
        deliveryAddress,
        notes,
        createdAt,
        updatedAt,
        deliveredAt,
        trackingNumber,
      ];
} 