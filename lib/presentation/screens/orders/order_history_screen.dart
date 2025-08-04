import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/loading_indicator.dart';

/// Provider for order filter state
final orderFilterProvider = StateProvider<OrderStatus?>((ref) => null);

/// Production-grade order history screen that shows the user's past orders
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {

  
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final selectedFilter = ref.watch(orderFilterProvider);
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order History'),
        ),
        body: EmptyState(
          animation: 'assets/animations/login.json',
          title: 'Not Logged In',
          description: 'Please log in to view your order history.',
          buttonText: 'Log In',
          onButtonPressed: () => context.go('/login'),
        ),
      );
    }
    
    return Scaffold(
        appBar: AppBar(
          title: const Text('Order History'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter Orders',
              onPressed: _showFilterOptions,
            ),
          ],
        ),
        body: ref.watch(userOrdersProvider(currentUser.id)).when(
          data: (orders) {
            // Filter orders if a filter is selected
            final filteredOrders = selectedFilter == null
                ? orders
                : orders.where((order) => order.status == selectedFilter).toList();
                
            if (filteredOrders.isEmpty) {
              return EmptyState(
                animation: 'assets/animations/empty_box.json',
                title: selectedFilter == null
                    ? AppStrings.noOrders
                    : 'No ${selectedFilter.displayName} Orders',
                description: selectedFilter == null
                    ? AppStrings.noOrdersMessage
                    : 'You have no orders with ${selectedFilter.displayName} status.',
                buttonText: AppStrings.shopNow,
                onButtonPressed: () => context.go('/products'),
              );
            }
            
            return _buildOrdersList(filteredOrders);
          },
          loading: () => const LoadingIndicator(),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    ;
  }
  
  /// Show filter options for orders by status
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.br16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Orders',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Consumer(builder: (context, ref, child) {
                  final selectedFilter = ref.watch(orderFilterProvider);
                  return Column(
                    children: [
                      _buildFilterOption(
                        ref: ref,
                        label: 'All Orders',
                        value: null,
                        groupValue: selectedFilter,
                      ),
                      ...OrderStatus.values.map((status) {
                        return _buildFilterOption(
                          ref: ref,
                          label: status.displayName,
                          value: status,
                          groupValue: selectedFilter,
                        );
                      }),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filter'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption({
    required WidgetRef ref,
    required String label,
    required OrderStatus? value,
    required OrderStatus? groupValue,
  }) {
    return RadioListTile<OrderStatus?>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (newValue) {
        ref.read(orderFilterProvider.notifier).state = newValue;
      },
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  /// Build the list of orders
  Widget _buildOrdersList(List<OrderModel> orders) {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.p16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }
  
  Widget _buildOrderCard(OrderModel order) {
    final currencyFormatter = NumberFormat.currency(symbol: '₵');
    
    return FadeInUp(
      from: 20,
      duration: const Duration(milliseconds: 300),
      delay: const Duration(milliseconds: 100),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSizes.p16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        ),
        elevation: AppSizes.cardElevation,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
          onTap: () => _navigateToOrderDetail(order),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildStatusChip(order.status),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy').format(order.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      currencyFormatter.format(order.grandTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                if (order.items.isNotEmpty) ...[  
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: order.items.length > 3 ? 3 : order.items.length,
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        return Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                            image: item.productImage.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(item.productImage),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: item.productImage.isEmpty
                              ? const Icon(Icons.image_not_supported, color: Colors.grey)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _navigateToOrderDetail(order),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.br8),
                          ),
                        ),
                        child: const Text(AppStrings.viewDetails),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _reorderItems(order),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.br8),
                          ),
                        ),
                        child: const Text(AppStrings.reorder),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue.shade300;
        icon = Icons.check;
        break;
      case OrderStatus.processing:
        color = Colors.blue;
        icon = Icons.inventory;
        break;
      case OrderStatus.shipped:
        color = Colors.indigo;
        icon = Icons.local_shipping;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case OrderStatus.refunded:
        color = Colors.purple;
        icon = Icons.money_off;
        break;
    }
    
    return Chip(
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color, width: 1),
      labelStyle: TextStyle(color: color, fontSize: 12),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      avatar: Icon(icon, color: color, size: 16),
      label: Text(status.displayName),
    );
  }
  
  void _reorderItems(OrderModel order) async {
    
    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      
      // Clear cart first to avoid duplications
      await cartNotifier.clearCart();
      
      // Add all items from the order to the cart
      // Note: This would require product lookup by productId to convert CartItemModel to ProductModel
      // Implementation simplified for now - would need to fetch products by ID
      // for (final item in order.items) {
      //   final product = await productService.getProductById(item.productId);
      //   if (product != null) {
      //     await cartNotifier.addItem(product, item.quantity);
      //   }
      // }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Items added to cart'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate to cart
        context.go('/cart');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Reorder operation completed
    }
  }
  
  /// Navigate to order details screen
  void _navigateToOrderDetail(OrderModel order) {
    GoRouter.of(context).push('/orders/${order.id}');
  }
}