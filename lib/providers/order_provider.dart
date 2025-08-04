import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart'; // Contains OrderStatus enum
import '../utils/app_logger.dart';

/// Provider that fetches recent orders from Firestore
final recentOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    
    return querySnapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return OrderModel.fromMap(data);
        })
        .toList();
  } catch (e) {
    AppLogger.error('Error fetching recent orders', e);
    return [];
  }
});

/// Provider that gets orders by user ID
final userOrdersProvider = FutureProvider.family<List<OrderModel>, String>(
  (ref, userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();
      
      final orders = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return OrderModel.fromMap(data);
          })
          .toList();
      
      // Sort in memory to avoid Firestore index requirement
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return orders;
    } catch (e) {
      AppLogger.error('Error fetching user orders', e);
      return [];
    }
  }
);

/// Provider that gets a single order by its ID
final orderByIdProvider = FutureProvider.family<OrderModel?, String>(
  (ref, orderId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return OrderModel.fromMap(data);
      } else {
        return null;
      }
    } catch (e) {
      AppLogger.error('Error fetching order $orderId', e);
      return null;
    }
  }
);

/// Provider for order counts by status
final orderCountByStatusProvider = FutureProvider.family<int, OrderStatus>(
  (ref, status) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: status.toString().split('.').last)
          .count()
          .get();
      
      return querySnapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Error counting orders with status ${status.name}', e);
      return 0;
    }
  }
);
