import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';

import '../../../models/order_model.dart';

import '../../../providers/admin_provider.dart';


import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/admin/advanced_order_filter.dart';

import '../orders/order_detail_screen.dart';

class OrderManagementScreen extends ConsumerStatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  ConsumerState<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends ConsumerState<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  OrderFilterCriteria _filterCriteria = const OrderFilterCriteria();
  bool _isLoading = false;
  bool _showFilters = false;

  final List<OrderStatus> _statusTabs = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.delivered,
    OrderStatus.cancelled,
    OrderStatus.refunded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          // Tab changed, trigger rebuild
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar and Filter Toggle
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _filterCriteria = _filterCriteria.copyWith(
                              searchQuery: value.isEmpty ? null : value,
                            );
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search orders by ID, customer name...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: _showFilters ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _filterCriteria.hasActiveFilters 
                              ? AppTheme.primaryColor 
                              : Colors.grey.shade300,
                          width: _filterCriteria.hasActiveFilters ? 2 : 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => setState(() => _showFilters = !_showFilters),
                        icon: Icon(
                          Icons.filter_list,
                          color: _showFilters ? Colors.white : 
                                 (_filterCriteria.hasActiveFilters ? AppTheme.primaryColor : Colors.grey.shade600),
                        ),
                        tooltip: 'Advanced Filters',
                      ),
                    ),
                  ],
                ),
              ),
              // Status Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: _statusTabs.map((status) => Tab(
                  text: status.displayName,
                )).toList(),
              ),
            ],
          ),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Advanced Filter Panel
            if (_showFilters)
              Container(
                margin: const EdgeInsets.all(16),
                child: AdvancedOrderFilter(
                  initialCriteria: _filterCriteria,
                  onFilterChanged: (criteria) {
                    setState(() {
                      _filterCriteria = criteria;
                    });
                  },
                ),
              ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _statusTabs.map((status) => _buildOrdersList(status)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(OrderStatus status) {
    return ref.watch(adminOrderProvider).when(
      data: (orders) {
        // Apply advanced filtering
        final adminNotifier = ref.read(adminOrderProvider.notifier);
        final filteredOrders = adminNotifier.getFilteredOrders(
          status: status,
          searchQuery: _filterCriteria.searchQuery,
          startDate: _filterCriteria.startDate,
          endDate: _filterCriteria.endDate,
          minAmount: _filterCriteria.minAmount,
          maxAmount: _filterCriteria.maxAmount,
        );

        if (filteredOrders.isEmpty) {
          return EmptyState(
            lottieAsset: 'assets/animations/empty_orders.json',
            title: 'No ${status.displayName} Orders',
            message: 'There are no orders with ${status.displayName.toLowerCase()} status.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.read(adminOrderProvider.notifier).loadAllOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: _buildOrderCard(order),
              );
            },
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading orders',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(adminOrderProvider.notifier).loadAllOrders(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 16),
              
              // Order Items Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '\$${order.grandTotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // First few items preview
                    ...order.items.take(2).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.productName}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '\$${(item.productPrice * item.quantity).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (order.items.length > 2)
                      Text(
                        '+${order.items.length - 2} more item${order.items.length - 2 > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Delivery Address
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddress,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToOrderDetail(order),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: order.status == OrderStatus.delivered || 
                                 order.status == OrderStatus.cancelled ||
                                 order.status == OrderStatus.refunded
                          ? null
                          : () => _showUpdateStatusDialog(order),
                      icon: const Icon(Icons.update, size: 16),
                      label: const Text('Update Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToOrderDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: order.id),
      ),
    );
  }

  void _showUpdateStatusDialog(OrderModel order) {
    final availableStatuses = _getAvailableStatusUpdates(order.status);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.id.substring(0, 8).toUpperCase()}'),
            const SizedBox(height: 8),
            Text(
              'Current Status: ${order.status.displayName}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const Text('Select new status:'),
            const SizedBox(height: 8),
            ...availableStatuses.map((status) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
              title: Text(status.displayName),
              onTap: () {
                Navigator.pop(context);
                _updateOrderStatus(order, status);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  List<OrderStatus> _getAvailableStatusUpdates(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.processing, OrderStatus.cancelled];
      case OrderStatus.processing:
        return [OrderStatus.shipped, OrderStatus.cancelled];
      case OrderStatus.shipped:
        return [OrderStatus.delivered];
      case OrderStatus.delivered:
        return [OrderStatus.refunded];
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return [];
    }
  }

  Future<void> _updateOrderStatus(OrderModel order, OrderStatus newStatus) async {
    setState(() => _isLoading = true);
    
    try {
      final orderNotifier = ref.read(adminOrderProvider.notifier);
      await orderNotifier.updateOrderStatus(order.id, newStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Refresh the orders
        ref.read(adminOrderProvider.notifier).loadAllOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.purple;
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

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.processing:
        return Icons.settings;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.refunded:
        return Icons.money_off;
    }
  }
}
