import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/product_model.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../../utils/test_data_helper.dart';
import 'product_management_screen.dart';
import 'order_management_screen.dart';
import 'user_management_screen.dart';
import 'admin_profile_screen.dart';

final productCountProvider = FutureProvider<int>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('products').count().get();
  return snapshot.count ?? 0;
});

final orderCountProvider = FutureProvider<int>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('orders').count().get();
  return snapshot.count ?? 0;
});

final userCountProvider = FutureProvider<int>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('users').count().get();
  return snapshot.count ?? 0;
});

final revenueProvider = FutureProvider<double>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('orders')
      .where('status', isEqualTo: 'completed')
      .get();
  
  double total = 0;
  for (var doc in snapshot.docs) {
    total += (doc.data()['totalAmount'] as num).toDouble();
  }
  
  return total;
});

final recentOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    print('🔍 Starting to fetch recent orders...');
    
    // Check authentication state
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    print('🔐 Current user: ${currentUser?.uid ?? "null"} (${currentUser?.email ?? "no email"})');
    
    if (currentUser == null) {
      print('❌ No authenticated user found');
      throw Exception('User not authenticated');
    }
    
    print('📊 Attempting to fetch orders from Firestore...');
    final snapshot = await FirebaseFirestore.instance.collection('orders')
        .get();
    
    print('✅ Firestore query successful. Found ${snapshot.docs.length} orders');
    
    if (snapshot.docs.isEmpty) {
      print('⚠️ No orders found in the database');
      return [];
    }
    
    final orders = <Map<String, dynamic>>[];
    
    for (var doc in snapshot.docs) {
      try {
        final data = doc.data();
        print('📄 Processing order ${doc.id}: ${data.keys.toList()}');
        
        final order = {
          'id': doc.id,
          'customerName': data['customerName'] ?? 'Unknown',
          'amount': data['totalAmount'] ?? 0.0,
          'date': data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          'status': data['status'] ?? 'pending',
        };
        
        orders.add(order);
        print('✅ Successfully processed order ${doc.id}');
      } catch (e) {
        print('❌ Error processing order ${doc.id}: $e');
        continue;
      }
    }
    
    print('📈 Total orders processed: ${orders.length}');
    
    // Sort in memory to avoid Firestore index requirement
    orders.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    // Return only the first 5 orders
    final recentOrders = orders.take(5).toList();
    print('🎯 Returning ${recentOrders.length} recent orders');
    
    return recentOrders;
  } catch (e, stackTrace) {
    print('💥 Error fetching recent orders: $e');
    print('📍 Stack trace: $stackTrace');
    return [];
  }
});

final productCategoriesCountProvider = FutureProvider<Map<String, int>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('products').get();
  
  Map<String, int> categoryCounts = {};
  
  for (var doc in snapshot.docs) {
    final category = doc.data()['category'] as String? ?? 'other';
    categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
  }
  
  return categoryCounts;
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _validateAdmin();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _validateAdmin() async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have admin privileges.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        // Navigate back to home if not an admin
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.surfaceColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Products'),
            Tab(text: 'Orders'),
            Tab(text: 'Users'),
            Tab(text: 'Profile'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
            tooltip: 'Settings',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildProductsTab(),
            _buildOrdersTab(),
            _buildUsersTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Implement product form navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product form coming soon'),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildOverviewTab() {
    final productCount = ref.watch(productCountProvider);
    final orderCount = ref.watch(orderCountProvider);
    final userCount = ref.watch(userCountProvider);
    final revenue = ref.watch(revenueProvider);
    final recentOrders = ref.watch(recentOrdersProvider);
    final productCategoriesCount = ref.watch(productCategoriesCountProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh all providers
        await Future.wait([
          ref.refresh(productCountProvider.future),
          ref.refresh(orderCountProvider.future),
          ref.refresh(userCountProvider.future),
          ref.refresh(revenueProvider.future),
          ref.refresh(recentOrdersProvider.future),
          ref.refresh(productCategoriesCountProvider.future),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            FadeInDown(
              child: Text(
                'Welcome, Admin',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'Here\'s what\'s happening with your store',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats cards
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    title: 'Products',
                    value: productCount.when(
                      data: (count) => count.toString(),
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.inventory_2_outlined,
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    title: 'Orders',
                    value: orderCount.when(
                      data: (count) => count.toString(),
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    title: 'Customers',
                    value: userCount.when(
                      data: (count) => count.toString(),
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.people_outline,
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    title: 'Revenue',
                    value: revenue.when(
                      data: (amount) => '₵${amount.toStringAsFixed(2)}',
                      loading: () => '...',
                      error: (_, __) => '₵0.00',
                    ),
                    icon: Icons.attach_money,
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Recent orders
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Orders',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _tabController.animateTo(2),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      recentOrders.when(
                        data: (orders) {
                          if (orders.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No recent orders'),
                              ),
                            );
                          }
                          return Column(
                            children: orders.map((order) => _buildOrderItem(order)).toList(),
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stackTrace) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Failed to load recent orders',
                                  style: TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Error: $error',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        await TestDataHelper.testFirestoreConnection();
                                      },
                                      child: const Text('Test Connection'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await TestDataHelper.checkOrdersCollection();
                                      },
                                      child: const Text('Check Orders'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await TestDataHelper.createTestOrders();
                                        ref.refresh(recentOrdersProvider);
                                      },
                                      child: const Text('Create Test Orders'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref.refresh(recentOrdersProvider);
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Product categories
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Product Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _tabController.animateTo(1),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      productCategoriesCount.when(
                        data: (categories) {
                          if (categories.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No product categories'),
                              ),
                            );
                          }
                          return Column(
                            children: categories.entries.map(
                              (entry) => _buildCategoryItem(
                                category: entry.key,
                                count: entry.value,
                              ),
                            ).toList(),
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (_, __) => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Failed to load product categories'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderItem(Map<String, dynamic> order) {
    final status = order['status'] as String;
    Color statusColor;
    
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'processing':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        order['customerName'],
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(_dateFormat.format(order['date'])),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₵${(order['amount'] as num).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        // Navigate to order detail
      },
    );
  }
  
  Widget _buildCategoryItem({
    required String category,
    required int count,
  }) {
    // Try to parse the category string to our enum
    ProductCategory? productCategory;
    try {
      productCategory = ProductCategoryExtension.fromString(category);
    } catch (_) {
      // Use 'other' if we can't parse it
      productCategory = ProductCategory.other;
    }
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        productCategory.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () {
        // Navigate to filtered products list
      },
    );
  }
  
  Widget _buildProductsTab() {
    return const ProductManagementScreen();
  }
  
  Widget _buildOrdersTab() {
    return const OrderManagementScreen();
  }
  
  Widget _buildUsersTab() {
    return const UserManagementScreen();
  }
  
  Widget _buildProfileTab() {
    return const AdminProfileScreen();
  }
} 