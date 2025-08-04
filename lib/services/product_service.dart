import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'products';

  // Get all products
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Get products stream for real-time updates
  Stream<List<ProductModel>> getProductsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(productId).get();
      
      if (doc.exists && doc.data() != null) {
        return ProductModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // Get products by category
  Future<List<ProductModel>> getProductsByCategory(ProductCategory category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category.name)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllProducts();
      }

      // For now, we'll fetch all products and filter locally
      // In production, you might want to use Algolia or ElasticSearch
      final allProducts = await getAllProducts();
      final lowercaseQuery = query.toLowerCase();

      return allProducts.where((product) {
        return product.name.toLowerCase().contains(lowercaseQuery) ||
               product.description.toLowerCase().contains(lowercaseQuery) ||
               product.category.displayName.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Get featured products
  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured products: $e');
    }
  }

  // Get products with discounts
  Future<List<ProductModel>> getDiscountedProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isAvailable', isEqualTo: true)
          .where('discountPercentage', isGreaterThan: 0)
          .orderBy('discountPercentage', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch discounted products: $e');
    }
  }

  // Get low stock products (admin only)
  Future<List<ProductModel>> getLowStockProducts({int threshold = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('stockQuantity', isLessThanOrEqualTo: threshold)
          .where('stockQuantity', isGreaterThan: 0)
          .orderBy('stockQuantity')
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch low stock products: $e');
    }
  }

  // Add new product (admin only)
  Future<String> addProduct(ProductModel product) async {
    try {
      final doc = await _firestore.collection(_collection).add(product.toMap());
      return doc.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Update product (admin only)
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(product.id)
          .update(product.toMap());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product (admin only)
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Update product stock quantity
  Future<void> updateStock(String productId, int newQuantity) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(productId)
          .update({
        'stockQuantity': newQuantity,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  // Decrease stock after purchase
  Future<void> decreaseStock(String productId, int quantity) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final productRef = _firestore.collection(_collection).doc(productId);
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception('Product not found');
        }

        final currentStock = productSnapshot.data()!['stockQuantity'] as int;
        final newStock = currentStock - quantity;

        if (newStock < 0) {
          throw Exception('Insufficient stock');
        }

        transaction.update(productRef, {
          'stockQuantity': newStock,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      throw Exception('Failed to decrease stock: $e');
    }
  }

  // Get product categories with count
  Future<Map<ProductCategory, int>> getCategoriesWithCount() async {
    try {
      final allProducts = await getAllProducts();
      final categoryCounts = <ProductCategory, int>{};

      for (final product in allProducts) {
        categoryCounts[product.category] = 
            (categoryCounts[product.category] ?? 0) + 1;
      }

      return categoryCounts;
    } catch (e) {
      throw Exception('Failed to fetch category counts: $e');
    }
  }

  // Filter products with multiple criteria
  Future<List<ProductModel>> filterProducts({
    ProductCategory? category,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? hasDiscount,
    String? sortBy,
    bool sortAscending = true,
  }) async {
    try {
      var products = await getAllProducts();

      // Apply filters
      if (category != null) {
        products = products.where((p) => p.category == category).toList();
      }

      if (minPrice != null) {
        products = products.where((p) => p.discountedPrice >= minPrice).toList();
      }

      if (maxPrice != null) {
        products = products.where((p) => p.discountedPrice <= maxPrice).toList();
      }

      if (inStock == true) {
        products = products.where((p) => p.isAvailable && p.stockQuantity > 0).toList();
      }

      if (hasDiscount == true) {
        products = products.where((p) => p.hasDiscount).toList();
      }

      // Apply sorting
      if (sortBy != null) {
        products.sort((a, b) {
          int result = 0;
          switch (sortBy) {
            case 'name':
              result = a.name.compareTo(b.name);
              break;
            case 'price':
              result = a.discountedPrice.compareTo(b.discountedPrice);
              break;
            case 'rating':
              result = a.rating.compareTo(b.rating);
              break;
            case 'stock':
              result = a.stockQuantity.compareTo(b.stockQuantity);
              break;
            case 'date':
              result = a.createdAt.compareTo(b.createdAt);
              break;
            default:
              result = a.name.compareTo(b.name);
          }
          return sortAscending ? result : -result;
        });
      }

      return products;
    } catch (e) {
      throw Exception('Failed to filter products: $e');
    }
  }

  // Get product statistics (admin only)
  Future<Map<String, dynamic>> getProductStatistics() async {
    try {
      final products = await getAllProducts();
      
      final totalProducts = products.length;
      final availableProducts = products.where((p) => p.isAvailable).length;
      final outOfStockProducts = products.where((p) => p.stockQuantity == 0).length;
      final lowStockProducts = products.where((p) => p.stockQuantity > 0 && p.stockQuantity <= 10).length;
      final discountedProducts = products.where((p) => p.hasDiscount).length;
      
      final totalStock = products.fold<int>(0, (sum, p) => sum + p.stockQuantity);
      final averagePrice = products.isNotEmpty
          ? products.fold<double>(0, (sum, p) => sum + p.price) / products.length
          : 0.0;
      final averageRating = products.isNotEmpty
          ? products.fold<double>(0, (sum, p) => sum + p.rating) / products.length
          : 0.0;

      return {
        'totalProducts': totalProducts,
        'availableProducts': availableProducts,
        'outOfStockProducts': outOfStockProducts,
        'lowStockProducts': lowStockProducts,
        'discountedProducts': discountedProducts,
        'totalStock': totalStock,
        'averagePrice': averagePrice,
        'averageRating': averageRating,
      };
    } catch (e) {
      throw Exception('Failed to get product statistics: $e');
    }
  }

  // Bulk update products (admin only)
  Future<void> bulkUpdateProducts(
    List<String> productIds,
    Map<String, dynamic> updates,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final productId in productIds) {
        final productRef = _firestore.collection(_collection).doc(productId);
        batch.update(productRef, {
          ...updates,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk update products: $e');
    }
  }

  // Bulk delete products (admin only)
  Future<void> bulkDeleteProducts(List<String> productIds) async {
    try {
      final batch = _firestore.batch();

      for (final productId in productIds) {
        final productRef = _firestore.collection(_collection).doc(productId);
        batch.delete(productRef);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk delete products: $e');
    }
  }
} 