import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_model.dart';
import '../models/product_model.dart';

class CartService {
  static const String _cartKey = 'user_cart';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get cart from local storage
  Future<CartModel> getCart(String userId) async {
    try {
      // Try to get from local storage first
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('${_cartKey}_$userId');
      
      if (cartJson != null) {
        final cartMap = json.decode(cartJson) as Map<String, dynamic>;
        return CartModel.fromMap(cartMap);
      }
      
      // If not found locally, try to get from Firestore
      final doc = await _firestore.collection('carts').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final cart = CartModel.fromMap(doc.data()!);
        // Save to local storage for offline access
        await _saveCartLocally(cart);
        return cart;
      }
      
      // Return empty cart if not found anywhere
      return CartModel(
        userId: userId,
        items: const [],
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get cart: $e');
    }
  }

  // Save cart to both local storage and Firestore
  Future<void> saveCart(CartModel cart) async {
    try {
      // Save to local storage
      await _saveCartLocally(cart);
      
      // Save to Firestore
      await _firestore
          .collection('carts')
          .doc(cart.userId)
          .set(cart.toMap());
    } catch (e) {
      throw Exception('Failed to save cart: $e');
    }
  }

  // Save cart to local storage only
  Future<void> _saveCartLocally(CartModel cart) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(cart.toMap());
      await prefs.setString('${_cartKey}_${cart.userId}', cartJson);
    } catch (e) {
      throw Exception('Failed to save cart locally: $e');
    }
  }

  // Add item to cart
  Future<CartModel> addToCart(CartModel cart, ProductModel product, int quantity) async {
    try {
      final cartItem = CartItemModel.fromProduct(product, quantity);
      final updatedCart = cart.addItem(cartItem);
      await saveCart(updatedCart);
      return updatedCart;
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  // Remove item from cart
  Future<CartModel> removeFromCart(CartModel cart, String productId) async {
    try {
      final updatedCart = cart.removeItem(productId);
      await saveCart(updatedCart);
      return updatedCart;
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  // Update item quantity in cart
  Future<CartModel> updateItemQuantity(CartModel cart, String productId, int quantity) async {
    try {
      final updatedCart = cart.updateItemQuantity(productId, quantity);
      await saveCart(updatedCart);
      return updatedCart;
    } catch (e) {
      throw Exception('Failed to update item quantity: $e');
    }
  }

  // Clear cart
  Future<CartModel> clearCart(CartModel cart) async {
    try {
      final updatedCart = cart.clearCart();
      await saveCart(updatedCart);
      return updatedCart;
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Sync cart between local and remote
  Future<CartModel> syncCart(String userId) async {
    try {
      // Get local cart
      final prefs = await SharedPreferences.getInstance();
      final localCartJson = prefs.getString('${_cartKey}_$userId');
      
      // Get remote cart
      final doc = await _firestore.collection('carts').doc(userId).get();
      
      CartModel finalCart;
      
      if (localCartJson != null && doc.exists) {
        // Both exist, merge them (prioritize local if more recent)
        final localCart = CartModel.fromMap(json.decode(localCartJson));
        final remoteCart = CartModel.fromMap(doc.data()!);
        
        if (localCart.updatedAt.isAfter(remoteCart.updatedAt)) {
          finalCart = localCart;
        } else {
          finalCart = remoteCart;
        }
      } else if (localCartJson != null) {
        // Only local exists
        finalCart = CartModel.fromMap(json.decode(localCartJson));
      } else if (doc.exists) {
        // Only remote exists
        finalCart = CartModel.fromMap(doc.data()!);
      } else {
        // Neither exists, create empty cart
        finalCart = CartModel(
          userId: userId,
          items: const [],
          updatedAt: DateTime.now(),
        );
      }
      
      // Save the final cart to both locations
      await saveCart(finalCart);
      return finalCart;
    } catch (e) {
      throw Exception('Failed to sync cart: $e');
    }
  }

  // Get cart total
  double getCartTotal(CartModel cart) {
    return cart.totalAmount;
  }

  // Get cart item count
  int getCartItemCount(CartModel cart) {
    return cart.totalItems;
  }

  // Check if product is in cart
  bool isProductInCart(CartModel cart, String productId) {
    return cart.hasProduct(productId);
  }

  // Get item quantity for a specific product
  int getItemQuantity(CartModel cart, String productId) {
    final item = cart.getItemByProductId(productId);
    return item?.quantity ?? 0;
  }

  // Validate cart items (check if products still exist and have stock)
  Future<CartModel> validateCartItems(CartModel cart) async {
    try {
      final validItems = <CartItemModel>[];
      
      for (final item in cart.items) {
        // Check if product still exists in Firestore
        final productDoc = await _firestore
            .collection('products')
            .doc(item.productId)
            .get();
        
        if (productDoc.exists) {
          final productData = productDoc.data()!;
          final product = ProductModel.fromMap({...productData, 'id': productDoc.id});
          
          // Check if product is available and has sufficient stock
          if (product.isAvailable && product.stockQuantity >= item.quantity) {
            validItems.add(item);
          } else if (product.isAvailable && product.stockQuantity > 0) {
            // Adjust quantity to available stock
            final adjustedItem = item.copyWith(quantity: product.stockQuantity);
            validItems.add(adjustedItem);
          }
          // If product is not available or out of stock, skip it
        }
        // If product doesn't exist, skip it
      }
      
      final validatedCart = cart.copyWith(
        items: validItems,
        updatedAt: DateTime.now(),
      );
      
      await saveCart(validatedCart);
      return validatedCart;
    } catch (e) {
      throw Exception('Failed to validate cart items: $e');
    }
  }

  // Delete cart (when user logs out or deletes account)
  Future<void> deleteCart(String userId) async {
    try {
      // Delete from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cartKey}_$userId');
      
      // Delete from Firestore
      await _firestore.collection('carts').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete cart: $e');
    }
  }
} 