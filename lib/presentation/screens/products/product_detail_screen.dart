import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/common/adaptive_image.dart';

import '../../../constants/app_sizes.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../utils/extensions.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/rating_bar.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsyncValue = ref.watch(productProvider);
    
    return Scaffold(
      body: productAsyncValue.when(
        loading: () => const _ProductDetailLoading(),
        error: (error, stackTrace) => ErrorState(
          title: 'Error Loading Product',
          message: 'Failed to load product details', 
          onRetry: () => ref.read(productProvider.notifier).refreshProducts(),
        ),
        data: (products) {
          final product = ref.read(productProvider.notifier).getProductById(productId);
          if (product == null) {
            return ErrorState(
              title: 'Product Not Found',
              message: 'Product not found', 
              onRetry: () => GoRouter.of(context).pop(),
            );
          }
          return _ProductDetailView(product: product);
        },
      ),
    );
  }
}

class _ProductDetailLoading extends StatelessWidget {
  const _ProductDetailLoading();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 28,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ),
                  AppSizes.gapH16,
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 20,
                      width: 150,
                      color: Colors.white,
                    ),
                  ),
                  AppSizes.gapH8,
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _ProductDetailView extends ConsumerStatefulWidget {
  const _ProductDetailView({required this.product});
  
  final ProductModel product;

  @override
  ConsumerState<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<_ProductDetailView> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  final PageController _imagePageController = PageController();

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    if (_quantity < widget.product.stockQuantity) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    
    return CustomScrollView(
      slivers: [
        // App Bar and Image Gallery
        SliverAppBar(
          expandedHeight: 350,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Image Gallery
                PageView.builder(
                  controller: _imagePageController,
                  itemCount: product.imageUrls.isEmpty ? 1 : product.imageUrls.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    if (product.imageUrls.isEmpty) {
                      return Image.asset(
                        'assets/images/placeholder.png',
                        fit: BoxFit.cover,
                      );
                    }
                    return Hero(
                      tag: 'product-${product.id}-$index',
                      child: AdaptiveImage(
                        imagePath: product.imageUrls[index],
                        fit: BoxFit.cover,
                        placeholder: Center(
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                        ),
                        errorWidget: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
                // Image indicators
                if (product.imageUrls.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        product.imageUrls.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? theme.colorScheme.primary
                                : Colors.grey.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Discount badge
                if (product.hasDiscount)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: FadeIn(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.p12,
                          vertical: AppSizes.p4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(AppSizes.p16),
                        ),
                        child: Text(
                          '-${product.discountPercentage!.round()}%',
                          style: theme.textTheme.labelMedium!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Stock status
                Positioned(
                  top: 16,
                  right: 16,
                  child: FadeIn(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p12,
                        vertical: AppSizes.p4,
                      ),
                      decoration: BoxDecoration(
                        color: product.isAvailable && product.stockQuantity > 0
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(AppSizes.p16),
                      ),
                      child: Text(
                        product.isAvailable && product.stockQuantity > 0
                            ? 'In Stock'
                            : 'Out of Stock',
                        style: theme.textTheme.labelMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Product Details
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  FadeInUp(
                    from: 20,
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p12,
                        vertical: AppSizes.p4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSizes.p16),
                      ),
                      child: Text(
                        product.category.displayName,
                        style: theme.textTheme.labelMedium!.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  AppSizes.gapH16,
                  // Product Name
                  FadeInUp(
                    from: 20,
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      product.name,
                      style: theme.textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AppSizes.gapH8,
                  // Rating and Review Count
                  FadeInUp(
                    from: 20,
                    delay: const Duration(milliseconds: 300),
                    child: Row(
                      children: [
                        RatingBar(
                          rating: product.rating,
                          size: 18,
                        ),
                        AppSizes.gapW8,
                        Text(
                          '(${product.reviewCount} reviews)',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSizes.gapH16,
                  // Price
                  FadeInUp(
                    from: 20,
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (product.hasDiscount) ...[                          
                          Text(
                            context.formatCurrency(product.discountedPrice),
                            style: theme.textTheme.headlineSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          AppSizes.gapW8,
                          Text(
                            context.formatCurrency(product.price),
                            style: theme.textTheme.titleMedium!.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                            ),
                          ),
                        ] else
                          Text(
                            context.formatCurrency(product.price),
                            style: theme.textTheme.headlineSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        const Spacer(),
                        Text(
                          'per ${product.unit}',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSizes.gapH24,
                  // Description
                  FadeInUp(
                    from: 20,
                    delay: const Duration(milliseconds: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSizes.gapH8,
                        Text(
                          product.description,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSizes.gapH24,
                  // Specifications
                  if (product.specifications != null && product.specifications!.isNotEmpty)
                    FadeInUp(
                      from: 20,
                      delay: const Duration(milliseconds: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Specifications',
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSizes.gapH8,
                          ...product.specifications!.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSizes.p8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.key}: ',
                                    style: theme.textTheme.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value.toString(),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  AppSizes.gapH24,
                  // Quantity Selection
                  if (product.isAvailable && product.stockQuantity > 0)
                    FadeInUp(
                      from: 20,
                      delay: const Duration(milliseconds: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity',
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSizes.gapH8,
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppSizes.p8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: _decrementQuantity,
                                      icon: const Icon(Icons.remove),
                                      color: _quantity > 1
                                          ? theme.colorScheme.primary
                                          : Colors.grey,
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSizes.p12,
                                        vertical: AppSizes.p8,
                                      ),
                                      child: Text(
                                        _quantity.toString(),
                                        style: theme.textTheme.titleMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _incrementQuantity,
                                      icon: const Icon(Icons.add),
                                      color: _quantity < product.stockQuantity
                                          ? theme.colorScheme.primary
                                          : Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                              AppSizes.gapW16,
                              Text(
                                '${product.stockQuantity} ${product.unit} available',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  AppSizes.gapH32,
                  // Add to Cart Button
                  FadeInUp(
                    from: 20,
                    delay: const Duration(milliseconds: 800),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: product.isAvailable && product.stockQuantity > 0
                            ? () async {
                                try {
                                  // Add to cart logic
                                  await ref.read(cartProvider.notifier).addItem(product, _quantity);
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$_quantity ${product.name} added to cart',
                                        ),
                                        action: SnackBarAction(
                                          label: 'View Cart',
                                          onPressed: () {
                                            // Navigate to cart
                                            GoRouter.of(context).push('/cart');
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to add item to cart: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                        ),
                        icon: const Icon(Icons.shopping_cart),
                        label: Text(
                          product.isAvailable && product.stockQuantity > 0
                              ? 'Add to Cart'
                              : 'Out of Stock',
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: product.isAvailable && product.stockQuantity > 0
                                ? theme.colorScheme.onPrimary
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSizes.gapH16,
                  // Buy Now Button
                  FadeInUp(
                    from: 20,
                    delay: const Duration(milliseconds: 900),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: product.isAvailable && product.stockQuantity > 0
                            ? () {
                                // Buy now logic
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Proceeding to checkout'),
                                  ),
                                );
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                          side: BorderSide(
                            color: product.isAvailable && product.stockQuantity > 0
                                ? theme.colorScheme.primary
                                : Colors.grey[300]!,
                          ),
                        ),
                        icon: const Icon(Icons.bolt),
                        label: Text(
                          'Buy Now',
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSizes.gapH32,
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}