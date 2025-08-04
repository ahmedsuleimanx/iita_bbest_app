import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product_model.dart';
import '../../../constants/app_sizes.dart';
import '../common/empty_state.dart';
import 'product_card.dart';

class ProductGridView extends ConsumerWidget {
  final List<ProductModel> products;
  final bool isLoading;
  final String emptyStateMessage;
  final VoidCallback? onRefresh;
  final Function(ProductModel)? onAddToCart;
  final bool showAddToCart;
  
  const ProductGridView({
    super.key,
    required this.products,
    this.isLoading = false,
    this.emptyStateMessage = 'No products found',
    this.onRefresh,
    this.onAddToCart,
    this.showAddToCart = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.shopping_basket_outlined,
          message: emptyStateMessage,
          buttonText: onRefresh != null ? 'Refresh' : null,
          onButtonPressed: onRefresh,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.m),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          showAddToCart: showAddToCart,
          onAddToCart: onAddToCart != null ? () => onAddToCart!(product) : null,
        );
      },
    );
  }
}
