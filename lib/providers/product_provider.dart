import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  ProductNotifier() : super(const AsyncValue.loading()) {
    loadProducts();
  }

  final ProductService _productService = ProductService();
  List<ProductModel> _allProducts = [];

  Future<void> loadProducts() async {
    try {
      state = const AsyncValue.loading();
      _allProducts = await _productService.getAllProducts();
      state = AsyncValue.data(_allProducts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }

  List<ProductModel> get allProducts => _allProducts;

  List<ProductModel> getProductsByCategory(ProductCategory category) {
    return _allProducts.where((product) => product.category == category).toList();
  }

  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return _allProducts;
    
    final lowercaseQuery = query.toLowerCase();
    return _allProducts.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
             product.description.toLowerCase().contains(lowercaseQuery) ||
             product.category.displayName.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  List<ProductModel> filterProducts({
    ProductCategory? category,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? hasDiscount,
  }) {
    var filteredProducts = _allProducts;

    if (category != null) {
      filteredProducts = filteredProducts
          .where((product) => product.category == category)
          .toList();
    }

    if (minPrice != null) {
      filteredProducts = filteredProducts
          .where((product) => product.discountedPrice >= minPrice)
          .toList();
    }

    if (maxPrice != null) {
      filteredProducts = filteredProducts
          .where((product) => product.discountedPrice <= maxPrice)
          .toList();
    }

    if (inStock == true) {
      filteredProducts = filteredProducts
          .where((product) => product.isAvailable && product.stockQuantity > 0)
          .toList();
    }

    if (hasDiscount == true) {
      filteredProducts = filteredProducts
          .where((product) => product.hasDiscount)
          .toList();
    }

    return filteredProducts;
  }

  ProductModel? getProductById(String productId) {
    try {
      return _allProducts.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  Future<ProductModel> addProduct(ProductModel product) async {
    try {
      final productId = await _productService.addProduct(product);
      final newProduct = product.copyWith(id: productId);
      _allProducts.add(newProduct);
      state = AsyncValue.data(_allProducts);
      return newProduct;
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      await _productService.updateProduct(product);
      final index = _allProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _allProducts[index] = product;
        state = AsyncValue.data(_allProducts);
      }
      return product;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _productService.deleteProduct(productId);
      _allProducts.removeWhere((product) => product.id == productId);
      state = AsyncValue.data(_allProducts);
    } catch (e) {
      rethrow;
    }
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<ProductModel>>>((ref) {
  return ProductNotifier();
});

final productByIdProvider = Provider.family<ProductModel?, String>((ref, productId) {
  final products = ref.watch(productProvider);
  return products.when(
    data: (productList) => productList.firstWhere(
      (product) => product.id == productId,
      orElse: () => ProductModel(
        id: '',
        name: '',
        description: '',
        price: 0,
        category: ProductCategory.other,
        stockQuantity: 0,
        unit: '',
        createdAt: DateTime.now(),
      ),
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

final productsByCategoryProvider = Provider.family<List<ProductModel>, ProductCategory>((ref, category) {
  final products = ref.watch(productProvider);
  return products.when(
    data: (productList) => productList.where((product) => product.category == category).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final featuredProductsProvider = Provider<List<ProductModel>>((ref) {
  final products = ref.watch(productProvider);
  return products.when(
    data: (productList) => productList
        .where((product) => product.rating >= 4.0 || product.hasDiscount)
        .take(10)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final availableProductsProvider = Provider<List<ProductModel>>((ref) {
  final products = ref.watch(productProvider);
  return products.when(
    data: (productList) => productList
        .where((product) => product.isAvailable && product.stockQuantity > 0)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final productCategoriesProvider = Provider<List<ProductCategory>>((ref) {
  final products = ref.watch(productProvider);
  return products.when(
    data: (productList) {
      final categories = productList.map((product) => product.category).toSet().toList();
      categories.sort((a, b) => a.displayName.compareTo(b.displayName));
      return categories;
    },
    loading: () => [],
    error: (_, __) => [],
  );
}); 