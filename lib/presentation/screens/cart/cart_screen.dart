import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';

import '../../../constants/app_sizes.dart';
import '../../../models/cart_model.dart';
import '../../../providers/cart_provider.dart';
import '../../widgets/common/adaptive_image.dart';
import '../../widgets/common/custom_button.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final isCartEmpty = ref.watch(cartIsEmptyProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (!isCartEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear cart',
              onPressed: () => _showClearCartDialog(context, ref),
            ),
        ],
      ),
      body: isCartEmpty 
          ? _buildEmptyCartState(context)
          : _buildCartItems(context, ref, cart),
      bottomNavigationBar: isCartEmpty 
          ? null 
          : _buildCartSummary(context, ref, cart),
    );
  }
  
  Widget _buildEmptyCartState(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            AppSizes.mediumVerticalSpacer,
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSizes.smallVerticalSpacer,
            const Text(
              'Add some products to your cart',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            AppSizes.mediumVerticalSpacer,
            CustomButton(
              text: 'Continue Shopping',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCartItems(BuildContext context, WidgetRef ref, CartModel cart) {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cart.items.length,
        itemBuilder: (context, index) {
          final item = cart.items[index];
          return _buildCartItem(context, ref, item);
        },
      ),
    );
  }
  
  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FadeIn(
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: AdaptiveImage(
                    imagePath: item.productImage,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                    errorWidget: Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                    placeholder: Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Product details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      AppSizes.smallVerticalSpacer,
                      
                      // Product price
                      Text(
                        '\$${item.productPrice.toStringAsFixed(2)} per ${item.unit}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      
                      AppSizes.smallVerticalSpacer,
                      
                      // Quantity controls and price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Quantity control
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                // Decrease button
                                _buildQuantityButton(
                                  context,
                                  icon: Icons.remove,
                                  onPressed: () => _updateItemQuantity(
                                    ref, item.productId, item.quantity - 1,
                                  ),
                                ),
                                
                                // Quantity display
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                
                                // Increase button
                                _buildQuantityButton(
                                  context,
                                  icon: Icons.add,
                                  onPressed: () => _updateItemQuantity(
                                    ref, item.productId, item.quantity + 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Total price
                          Text(
                            '\$${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Remove button
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _removeItem(ref, item.productId),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuantityButton(BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: icon == Icons.remove 
              ? const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ) 
              : const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
  
  Widget _buildCartSummary(BuildContext context, WidgetRef ref, CartModel cart) {
    final totalAmount = ref.watch(cartTotalProvider);
    final itemCount = ref.watch(cartItemCountProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cart summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  'Total: \$${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSizes.mediumVerticalSpacer,
            
            // Checkout button
            CustomButton(
              text: 'Proceed to Checkout',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CheckoutScreen(),
                ),
              ),
              icon: Icons.shopping_bag_outlined,
            ),
          ],
        ),
      ),
    );
  }
  
  void _updateItemQuantity(WidgetRef ref, String productId, int quantity) {
    if (quantity <= 0) {
      _showRemoveItemDialog(ref, productId);
    } else {
      ref.read(cartProvider.notifier).updateItemQuantity(productId, quantity);
    }
  }
  
  void _removeItem(WidgetRef ref, String productId) {
    ref.read(cartProvider.notifier).removeItem(productId);
    
    // Show confirmation snackbar
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: const Text('Item removed from cart'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // This would require storing removed items temporarily
            // For now, just inform the user
            ScaffoldMessenger.of(ref.context).showSnackBar(
              const SnackBar(content: Text('Undo not implemented yet')),
            );
          },
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showRemoveItemDialog(WidgetRef ref, String productId) {
    showDialog(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: const Text('Do you want to remove this item from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).removeItem(productId);
              Navigator.of(context).pop();
            },
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }
  
  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart cleared')),
              );
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }
}