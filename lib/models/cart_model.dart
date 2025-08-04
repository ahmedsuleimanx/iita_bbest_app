import 'package:equatable/equatable.dart';
import 'product_model.dart';

class CartItemModel extends Equatable {
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final int quantity;
  final String unit;
  final DateTime addedAt;

  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.quantity,
    required this.unit,
    required this.addedAt,
  });

  double get totalPrice => productPrice * quantity;

  factory CartItemModel.fromProduct(ProductModel product, int quantity) {
    return CartItemModel(
      productId: product.id,
      productName: product.name,
      productImage: product.mainImageUrl,
      productPrice: product.discountedPrice,
      quantity: quantity,
      unit: product.unit,
      addedAt: DateTime.now(),
    );
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      productPrice: (map['productPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      unit: map['unit'] ?? 'pieces',
      addedAt: DateTime.parse(map['addedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'quantity': quantity,
      'unit': unit,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  CartItemModel copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? productPrice,
    int? quantity,
    String? unit,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        productImage,
        productPrice,
        quantity,
        unit,
        addedAt,
      ];
}

class CartModel extends Equatable {
  final String userId;
  final List<CartItemModel> items;
  final DateTime updatedAt;

  const CartModel({
    required this.userId,
    this.items = const [],
    required this.updatedAt,
  });

  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  CartItemModel? getItemByProductId(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  bool hasProduct(String productId) {
    return items.any((item) => item.productId == productId);
  }

  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      userId: map['userId'] ?? '',
      items: List<CartItemModel>.from(
        (map['items'] ?? []).map((item) => CartItemModel.fromMap(item)),
      ),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CartModel copyWith({
    String? userId,
    List<CartItemModel>? items,
    DateTime? updatedAt,
  }) {
    return CartModel(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  CartModel addItem(CartItemModel newItem) {
    final existingItemIndex = items.indexWhere(
      (item) => item.productId == newItem.productId,
    );

    List<CartItemModel> updatedItems;
    if (existingItemIndex != -1) {
      // Update existing item quantity
      updatedItems = List.from(items);
      updatedItems[existingItemIndex] = items[existingItemIndex].copyWith(
        quantity: items[existingItemIndex].quantity + newItem.quantity,
      );
    } else {
      // Add new item
      updatedItems = [...items, newItem];
    }

    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  CartModel removeItem(String productId) {
    final updatedItems = items.where((item) => item.productId != productId).toList();
    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  CartModel updateItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      return removeItem(productId);
    }

    final updatedItems = items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  CartModel clearCart() {
    return copyWith(
      items: [],
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, items, updatedAt];
} 