import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iita_bbest_app/presentation/widgets/common/adaptive_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key, this.category});
  
  final String? category;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  late ProductCategory? _selectedCategory;
  bool _isGridView = true;
  String _sortOption = 'Popularity';
  final List<String> _sortOptions = ['Popularity', 'Price: Low to High', 'Price: High to Low', 'Rating'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category != null
        ? ProductCategoryExtension.fromString(widget.category!)
        : null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category != null ? 'Products - ${widget.category}' : 'All Products',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppTheme.primaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          _buildSortButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(productProvider.notifier).refreshProducts(),
        color: AppTheme.primaryColor,
        child: productsAsync.when(
          data: (products) => _buildProductList(products),
          loading: () => _buildLoadingView(),
          error: (error, stackTrace) => ErrorState(
            message: 'Error loading products: $error',
            onRetry: () => ref.refresh(productProvider.notifier).refreshProducts(),
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort Products',
      onSelected: (value) {
        setState(() => _sortOption = value);
      },
      itemBuilder: (context) => _sortOptions
          .map((option) => PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    Text(option),
                    const Spacer(),
                    if (_sortOption == option)
                      const Icon(Icons.check, color: AppTheme.primaryColor),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildProductList(List<ProductModel> allProducts) {
    // Filter by category if selected
    final List<ProductModel> filteredProducts = _selectedCategory != null
        ? allProducts.where((p) => p.category == _selectedCategory).toList()
        : allProducts;

    // Sort based on selected option
    switch (_sortOption) {
      case 'Price: Low to High':
        filteredProducts.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
        break;
      case 'Price: High to Low':
        filteredProducts.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
        break;
      case 'Rating':
        filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default: // Popularity (based on review count)
        filteredProducts.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }

    if (filteredProducts.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No Products Found',
        message: _selectedCategory != null
            ? 'There are no products available in this category at the moment.'
            : 'There are no products available at the moment.',
        actionText: 'Refresh',
        onAction: () => ref.refresh(productProvider.notifier).refreshProducts(),
      );
    }

    return _isGridView
        ? _buildProductGrid(filteredProducts)
        : _buildProductListView(filteredProducts);
  }

  Widget _buildProductGrid(List<ProductModel> products) {
    return FadeIn(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: MasonryGridView.count(
          controller: _scrollController,
          crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(products[index]);
          },
        ),
      ),
    );
  }

  Widget _buildProductListView(List<ProductModel> products) {
    return FadeIn(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _buildProductListTile(products[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return FadeInUp(
      from: 20,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateToProductDetail(product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: product.imageUrls.isNotEmpty
                        ?  AdaptiveImage(
                            imagePath: product.mainImageUrl,
                            fit: BoxFit.cover,
                            placeholder: Shimmer.fromColors(
                              baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                              highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: const Icon(Icons.image_not_supported, size: 50),
                          )
                        : Container(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 50,
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.discountPercentage!.toInt()}% OFF',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (product.stockQuantity <= 5 && product.stockQuantity > 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Low Stock',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  if (product.stockQuantity == 0)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        child: const Center(
                          child: Text(
                            'OUT OF STOCK',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Product Info
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          product.hasDiscount
                              ? '₵${product.discountedPrice.toStringAsFixed(2)}'
                              : '₵${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        if (product.hasDiscount) ...[  
                          const SizedBox(width: 6),
                          Text(
                            '₵${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${product.reviewCount})',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(product.category),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category.displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductListTile(ProductModel product) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return FadeInUp(
      from: 20,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateToProductDetail(product),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    product.imageUrls.isNotEmpty
                        ? AdaptiveImage(
                            imagePath: product.mainImageUrl,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            placeholder: Shimmer.fromColors(
                              baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                              highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: const Icon(Icons.image_not_supported, size: 50),
                          )
                        : Container(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 50,
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                    if (product.hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.discountPercentage!.toInt()}% OFF',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ),
                    if (product.stockQuantity == 0)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.6),
                          child: const Center(
                            child: Text(
                              'OUT OF STOCK',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Product Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            product.hasDiscount
                                ? '₵${product.discountedPrice.toStringAsFixed(2)}'
                                : '₵${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (product.hasDiscount) ...[  
                            const SizedBox(width: 6),
                            Text(
                              '₵${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(product.category),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.category.displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            ' (${product.reviewCount})',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      if (product.stockQuantity <= 5 && product.stockQuantity > 0) ...[  
                        const SizedBox(height: 4),
                        Text(
                          'Only ${product.stockQuantity} left',
                          style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return _isGridView
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: MasonryGridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: 8,
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                  highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 150,
                          color: Colors.white,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 80,
                                height: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                  highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          color: Colors.white,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  height: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  height: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 80,
                                  height: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }

  Color _getCategoryColor(ProductCategory category) {
    switch (category) {
      case ProductCategory.seeds:
        return Colors.green[700]!;
      case ProductCategory.fertilizer:
        return Colors.brown[700]!;
      case ProductCategory.organicFertilizer:
        return Colors.brown[400]!;
      case ProductCategory.animalFeed:
        return Colors.orange[700]!;
      case ProductCategory.tools:
        return Colors.blueGrey[700]!;
      case ProductCategory.pesticides:
        return Colors.red[700]!;
      case ProductCategory.equipment:
        return Colors.blue[700]!;
      case ProductCategory.other:
        return Colors.purple[700]!;
    }
  }

  void _navigateToProductDetail(ProductModel product) {
    // Using GoRouter to navigate to product detail
    context.push('/products/${product.id}');
  }
}