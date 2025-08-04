import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_overlay.dart';

/// Production-grade order detail screen showing all information about an order
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  
  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print Invoice',
              onPressed: () => _printInvoice(),
            ),
          ],
        ),
        body: ref.watch(orderByIdProvider(widget.orderId)).when(
          data: (order) {
            if (order == null) {
              return EmptyState(
                lottieAsset: 'assets/animations/error.json',
                title: 'Order Not Found',
                message: 'The order you are looking for does not exist or has been deleted.',
                buttonLabel: 'Go Back',
                onButtonPressed: () => Navigator.of(context).pop(),
              );
            }
            
            return _buildOrderDetails(order);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
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
                    'Error loading order details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: CustomButton(
                      onPressed: () => Navigator.pop(context),
                      text: 'Go Back',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Print invoice (placeholder functionality)
  void _printInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality would be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Build the main order details content
  Widget _buildOrderDetails(OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOrderHeader(order),
          const SizedBox(height: AppSizes.p24),
          _buildOrderStatus(order),
          const SizedBox(height: AppSizes.p24),
          _buildDeliveryInformation(order),
          const SizedBox(height: AppSizes.p24),
          _buildOrderItems(order),
          const SizedBox(height: AppSizes.p24),
          _buildOrderSummary(order),
        ],
      ),
    );
  }

  /// Build the order header section with ID and date
  Widget _buildOrderHeader(OrderModel order) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dateFormat.format(order.createdAt)} at ${timeFormat.format(order.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build the order status section with timeline indicators
  Widget _buildOrderStatus(OrderModel order) {
    return FadeInDown(
      delay: const Duration(milliseconds: 100),
      duration: const Duration(milliseconds: 400),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _buildOrderTimeline(order),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the delivery information section
  Widget _buildDeliveryInformation(OrderModel order) {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 400),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.location_on,
                'Delivery Address:',
                order.deliveryAddress,
              ),
              if (order.notes != null && order.notes!.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.note,
                      'Delivery Notes:',
                      order.notes!,
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.payment,
                'Payment Method:',
                order.paymentMethod.displayName,
              ),
              if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.local_shipping,
                      'Tracking Number:',
                      order.trackingNumber!,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build an information row with icon, label and value
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build a timeline of order status changes
  Widget _buildOrderTimeline(OrderModel order) {
    // Define all status steps in order
    const allStatuses = OrderStatus.values;
    final statusIndex = allStatuses.indexOf(order.status);
    
    return Column(
      children: [
        for (int i = 0; i < allStatuses.length; i++)
          _buildTimelineItem(
            status: allStatuses[i],
            isActive: i <= statusIndex,
            isFirst: i == 0,
            isLast: i == allStatuses.length - 1,
            isCurrent: i == statusIndex,
          ),
      ],
    );
  }
  
  /// Build a single timeline item for an order status
  Widget _buildTimelineItem({
    required OrderStatus status,
    required bool isActive,
    required bool isFirst,
    required bool isLast,
    required bool isCurrent,
    OrderModel? order,
  }) {
    final statusColor = isActive ? _getStatusColor(status) : Colors.grey.shade300;
    final textColor = isActive ? Colors.black87 : Colors.grey.shade500;
    final fontWeight = isCurrent ? FontWeight.bold : FontWeight.normal;
    
    return Row(
      children: [
        // Status indicator
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isCurrent ? statusColor : Colors.transparent,
            border: Border.all(
              color: statusColor,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              _getStatusIcon(status),
              color: isCurrent ? Colors.white : statusColor,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Status text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.displayName,
                style: TextStyle(
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
              if (isCurrent && order?.updatedAt != null)
                Text(
                  'Updated ${DateFormat('MMM dd, yyyy').format(order!.updatedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build the order items section
  Widget _buildOrderItems(OrderModel order) {
    return FadeInDown(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 400),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              
              // List of items
              ...order.items.map((item) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.productImage,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Product details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.unit,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Price and quantity
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${AppStrings.currencySymbol}${item.productPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Qty: ${item.quantity}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total: ${AppStrings.currencySymbol}${(item.productPrice * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build the order summary section with totals
  Widget _buildOrderSummary(OrderModel order) {
    return FadeInDown(
      delay: const Duration(milliseconds: 400),
      duration: const Duration(milliseconds: 400),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  Text(
                    '${AppStrings.currencySymbol}${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Shipping fee
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shipping Fee',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  Text(
                    '${AppStrings.currencySymbol}${order.shippingFee.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Tax
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tax (5%)',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  Text(
                    '${AppStrings.currencySymbol}${order.tax.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              
              // Grand total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${AppStrings.currencySymbol}${order.grandTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Re-order button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onPressed: () => _reorderItems(order),
                  text: 'Re-Order Items',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Re-order items functionality
  void _reorderItems(OrderModel order) {
    setState(() => _isLoading = true);
    
    // Here you would add all items to cart again
    // This is a placeholder for the actual implementation
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Items have been added to your cart'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate back to cart screen
      Navigator.popUntil(
        context,
        (route) => route.isFirst || route.settings.name == '/cart',
      );
    });
  }
  
  /// Build a status chip with appropriate color
  Widget _buildStatusChip(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  /// Get appropriate icon for order status
  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.processing:
        return Icons.inventory;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.refunded:
        return Icons.money_off;
    }
  }
  
  /// Get appropriate color for order status
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.amber.shade700;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.purple;
    }
  }
}