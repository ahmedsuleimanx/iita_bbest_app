import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_model.dart';
import '../models/user_model.dart';
import '../utils/app_logger.dart';

/// Provider for admin-specific order management with filtering
class AdminOrderNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  AdminOrderNotifier() : super(const AsyncValue.loading()) {
    loadAllOrders();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load all orders for admin management
  Future<void> loadAllOrders() async {
    try {
      state = const AsyncValue.loading();
      
      final querySnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      
      final orders = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return OrderModel.fromMap(data);
          })
          .toList();
      
      state = AsyncValue.data(orders);
    } catch (e, stackTrace) {
      AppLogger.error('Error loading admin orders', e);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Reload orders after update
      await loadAllOrders();
    } catch (e) {
      AppLogger.error('Error updating order status', e);
      rethrow;
    }
  }

  /// Filter orders by status
  List<OrderModel> getOrdersByStatus(OrderStatus status) {
    return state.when(
      data: (orders) => orders.where((order) => order.status == status).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// Search orders by query
  List<OrderModel> searchOrders(String query) {
    if (query.isEmpty) return state.value ?? [];
    
    return state.when(
      data: (orders) => orders.where((order) =>
          order.id.toLowerCase().contains(query.toLowerCase()) ||
          order.deliveryAddress.toLowerCase().contains(query.toLowerCase())).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// Get orders with advanced filtering
  List<OrderModel> getFilteredOrders({
    OrderStatus? status,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) {
    return state.when(
      data: (orders) {
        var filteredOrders = orders;

        // Filter by status
        if (status != null) {
          filteredOrders = filteredOrders.where((order) => order.status == status).toList();
        }

        // Filter by search query
        if (searchQuery != null && searchQuery.isNotEmpty) {
          filteredOrders = filteredOrders.where((order) =>
              order.id.toLowerCase().contains(searchQuery.toLowerCase()) ||
              order.deliveryAddress.toLowerCase().contains(searchQuery.toLowerCase())).toList();
        }

        // Filter by date range
        if (startDate != null) {
          filteredOrders = filteredOrders.where((order) => 
              order.createdAt.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
        }
        if (endDate != null) {
          filteredOrders = filteredOrders.where((order) => 
              order.createdAt.isBefore(endDate.add(const Duration(days: 1)))).toList();
        }

        // Filter by amount range
        if (minAmount != null) {
          filteredOrders = filteredOrders.where((order) => order.grandTotal >= minAmount).toList();
        }
        if (maxAmount != null) {
          filteredOrders = filteredOrders.where((order) => order.grandTotal <= maxAmount).toList();
        }

        return filteredOrders;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

}

/// Provider for admin order management
final adminOrderProvider = StateNotifierProvider<AdminOrderNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return AdminOrderNotifier();
});

/// Provider for orders filtered by status
final ordersByStatusProvider = Provider.family<List<OrderModel>, OrderStatus>((ref, status) {
  final adminOrders = ref.watch(adminOrderProvider);
  return adminOrders.when(
    data: (orders) => orders.where((order) => order.status == status).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Admin state model to hold all admin-related data
class AdminState {
  final List<OrderModel>? orders;
  final List<UserModel>? users;
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.orders,
    this.users,
    this.stats,
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<OrderModel>? orders,
    List<UserModel>? users,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      orders: orders ?? this.orders,
      users: users ?? this.users,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Comprehensive admin provider with order and user management
class AdminNotifier extends StateNotifier<AsyncValue<AdminState>> {
  AdminNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _initialize() async {
    try {
      state = const AsyncValue.loading();
      await Future.wait([
        loadAllOrders(),
        loadAllUsers(),
      ]);
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing admin data', e);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Load all orders for admin management
  Future<void> loadAllOrders() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      
      final orders = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return OrderModel.fromMap(data);
          })
          .toList();
      
      final currentState = state.value ?? const AdminState();
      final stats = _calculateStats(orders, currentState.users ?? []);
      
      state = AsyncValue.data(currentState.copyWith(
        orders: orders,
        stats: stats,
      ));
    } catch (e, stackTrace) {
      AppLogger.error('Error loading admin orders', e);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Load all users for admin management
  Future<void> loadAllUsers() async {
    try {
      print('🔍 Starting to load all users...');
      
      // Check authentication state
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      print('🔐 Current user: ${currentUser?.uid ?? "null"} (${currentUser?.email ?? "no email"})');
      
      if (currentUser == null) {
        print('❌ No authenticated user found');
        throw Exception('User not authenticated');
      }
      
      print('📊 Attempting to fetch users from Firestore...');
      
      // Try without orderBy first to see if it's an index issue
      final querySnapshot = await _firestore
          .collection('users')
          .get();
      
      print('✅ Firestore query successful. Found ${querySnapshot.docs.length} users');
      
      if (querySnapshot.docs.isEmpty) {
        print('⚠️ No users found in the database');
        final currentState = state.value ?? const AdminState();
        state = AsyncValue.data(currentState.copyWith(
          users: [],
          stats: _calculateStats(currentState.orders ?? [], []),
        ));
        return;
      }
      
      final users = <UserModel>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print('📄 Processing user ${doc.id}: ${data.keys.toList()}');
          
          data['id'] = doc.id;
          final user = UserModel.fromMap(data);
          users.add(user);
          print('✅ Successfully processed user ${doc.id}');
        } catch (e) {
          print('❌ Error processing user ${doc.id}: $e');
          continue;
        }
      }
      
      print('📈 Total users processed: ${users.length}');
      
      // Sort in memory to avoid potential index issues
      users.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      
      final currentState = state.value ?? const AdminState();
      final stats = _calculateStats(currentState.orders ?? [], users);
      
      state = AsyncValue.data(currentState.copyWith(
        users: users,
        stats: stats,
      ));
      
      print('🎯 Successfully loaded ${users.length} users');
    } catch (e, stackTrace) {
      print('💥 Error loading users: $e');
      print('📍 Stack trace: $stackTrace');
      AppLogger.error('Error loading users', e);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Reload orders after update
      await loadAllOrders();
    } catch (e) {
      AppLogger.error('Error updating order status', e);
      rethrow;
    }
  }

  /// Toggle user active status
  Future<void> toggleUserStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final currentStatus = userDoc.data()?['isActive'] ?? true;
        await _firestore.collection('users').doc(userId).update({
          'isActive': !currentStatus,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        
        // Reload users after update
        await loadAllUsers();
      }
    } catch (e) {
      AppLogger.error('Error toggling user status', e);
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      // Note: In production, you might want to soft delete or archive users
      // instead of permanently deleting them
      await _firestore.collection('users').doc(userId).delete();
      
      // Reload users after deletion
      await loadAllUsers();
    } catch (e) {
      AppLogger.error('Error deleting user', e);
      rethrow;
    }
  }

  /// Calculate admin statistics
  Map<String, dynamic> _calculateStats(List<OrderModel> orders, List<UserModel> users) {
    final totalOrders = orders.length;
    final totalRevenue = orders.fold<double>(0.0, (sum, order) => sum + order.grandTotal);
    final pendingOrders = orders.where((order) => order.status == OrderStatus.pending).length;
    final completedOrders = orders.where((order) => order.status == OrderStatus.delivered).length;
    final totalUsers = users.length;
    final activeUsers = users.where((user) => user.isActive).length;
    final adminUsers = users.where((user) => user.isAdmin).length;
    
    return {
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'pendingOrders': pendingOrders,
      'completedOrders': completedOrders,
      'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0.0,
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'adminUsers': adminUsers,
      'customerUsers': totalUsers - adminUsers,
    };
  }

  /// Refresh all admin data
  Future<void> refreshAll() async {
    await _initialize();
  }
}

/// Provider for comprehensive admin management
final adminProvider = StateNotifierProvider<AdminNotifier, AsyncValue<AdminState>>((ref) {
  return AdminNotifier();
});

/// Provider for admin statistics
final adminStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final adminState = ref.watch(adminProvider);
  
  return adminState.when(
    data: (state) => state.stats ?? {
      'totalOrders': 0,
      'totalRevenue': 0.0,
      'pendingOrders': 0,
      'completedOrders': 0,
      'averageOrderValue': 0.0,
      'totalUsers': 0,
      'activeUsers': 0,
      'adminUsers': 0,
      'customerUsers': 0,
    },
    loading: () => {
      'totalOrders': 0,
      'totalRevenue': 0.0,
      'pendingOrders': 0,
      'completedOrders': 0,
      'averageOrderValue': 0.0,
      'totalUsers': 0,
      'activeUsers': 0,
      'adminUsers': 0,
      'customerUsers': 0,
    },
    error: (_, __) => {
      'totalOrders': 0,
      'totalRevenue': 0.0,
      'pendingOrders': 0,
      'completedOrders': 0,
      'averageOrderValue': 0.0,
      'totalUsers': 0,
      'activeUsers': 0,
      'adminUsers': 0,
      'customerUsers': 0,
    },
  );
});

/// Extended Auth Provider with additional admin methods
class ExtendedAuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ExtendedAuthNotifier() : super(const AsyncValue.loading()) {
    _initializeUser();
  }

  void _initializeUser() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final user = UserModel.fromMap(userData);
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No user logged in');

    final userDoc = _firestore.collection('users').doc(currentUser.uid);
    final updateData = <String, dynamic>{};

    if (firstName != null) updateData['firstName'] = firstName;
    if (lastName != null) updateData['lastName'] = lastName;
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
    if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
    
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await userDoc.update(updateData);
    await refreshUser();
  }

  Future<void> refreshUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _loadUserData(currentUser.uid);
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }
}

// Provider for the extended auth functionality
final extendedAuthProvider = StateNotifierProvider<ExtendedAuthNotifier, AsyncValue<UserModel?>>((ref) {
  return ExtendedAuthNotifier();
});
