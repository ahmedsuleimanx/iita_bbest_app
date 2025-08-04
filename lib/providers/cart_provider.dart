import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import 'auth_provider.dart';

class CartNotifier extends StateNotifier<CartModel> {
  CartNotifier(this._cartService, this._userId) 
      : super(CartModel(userId: _userId, updatedAt: DateTime.now())) {
    _loadCart();
  }

  final CartService _cartService;
  final String _userId;

  Future<void> _loadCart() async {
    try {
      final cart = await _cartService.getCart(_userId);
      state = cart;
    } catch (e) {
      // Keep default empty cart if loading fails
    }
  }

  Future<void> addItem(ProductModel product, int quantity) async {
    try {
      final cartItem = CartItemModel.fromProduct(product, quantity);
      final updatedCart = state.addItem(cartItem);
      state = updatedCart;
      await _cartService.saveCart(updatedCart);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(String productId) async {
    try {
      final updatedCart = state.removeItem(productId);
      state = updatedCart;
      await _cartService.saveCart(updatedCart);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateItemQuantity(String productId, int quantity) async {
    try {
      final updatedCart = state.updateItemQuantity(productId, quantity);
      state = updatedCart;
      await _cartService.saveCart(updatedCart);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      final updatedCart = state.clearCart();
      state = updatedCart;
      await _cartService.saveCart(updatedCart);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncCart() async {
    try {
      await _cartService.saveCart(state);
    } catch (e) {
      rethrow;
    }
  }

  int getItemQuantity(String productId) {
    final item = state.getItemByProductId(productId);
    return item?.quantity ?? 0;
  }

  bool hasProduct(String productId) {
    return state.hasProduct(productId);
  }
}

final cartServiceProvider = Provider<CartService>((ref) {
  return CartService();
});

final cartProvider = StateNotifierProvider<CartNotifier, CartModel>((ref) {
  final cartService = ref.watch(cartServiceProvider);
  
  // Watch auth state and handle errors gracefully
  final authState = ref.watch(authProvider);
  
  // Handle auth errors or loading states
  final user = authState.when(
    data: (user) => user,
    loading: () => null,
    error: (error, stack) {
      print('Cart provider auth error: $error');
      return null;
    },
  );
  
  if (user == null) {
    // Return empty cart for unauthenticated users or auth errors
    return CartNotifier(cartService, '');
  }
  
  return CartNotifier(cartService, user.id);
});

final cartItemCountProvider = Provider<int>((ref) {
  try {
    final cart = ref.watch(cartProvider);
    return cart.totalItems;
  } catch (e) {
    print('Cart item count error: $e');
    return 0; // Return 0 items if there's an error
  }
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.totalAmount;
});

final cartIsEmptyProvider = Provider<bool>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.isEmpty;
});

final cartItemQuantityProvider = Provider.family<int, String>((ref, productId) {
  final cart = ref.watch(cartProvider);
  return cart.getItemByProductId(productId)?.quantity ?? 0;
});

final hasProductInCartProvider = Provider.family<bool, String>((ref, productId) {
  final cart = ref.watch(cartProvider);
  return cart.hasProduct(productId);
}); 