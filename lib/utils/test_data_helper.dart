import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utility class to help create test data for debugging
class TestDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create test orders for debugging the admin dashboard
  static Future<void> createTestOrders() async {
    try {
      print('🧪 Creating test orders...');
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }

      print('👤 Current user: ${currentUser.uid} (${currentUser.email})');

      // Create 3 test orders
      final testOrders = [
        {
          'customerName': 'John Doe',
          'totalAmount': 150.50,
          'status': 'completed',
          'createdAt': Timestamp.now(),
          'userId': currentUser.uid,
          'items': [
            {
              'productId': 'test-product-1',
              'productName': 'Test Product 1',
              'quantity': 2,
              'price': 75.25,
            }
          ],
        },
        {
          'customerName': 'Jane Smith',
          'totalAmount': 89.99,
          'status': 'pending',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
          'userId': currentUser.uid,
          'items': [
            {
              'productId': 'test-product-2',
              'productName': 'Test Product 2',
              'quantity': 1,
              'price': 89.99,
            }
          ],
        },
        {
          'customerName': 'Bob Johnson',
          'totalAmount': 234.75,
          'status': 'shipped',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'userId': currentUser.uid,
          'items': [
            {
              'productId': 'test-product-3',
              'productName': 'Test Product 3',
              'quantity': 3,
              'price': 78.25,
            }
          ],
        },
      ];

      for (int i = 0; i < testOrders.length; i++) {
        final orderRef = await _firestore.collection('orders').add(testOrders[i]);
        print('✅ Created test order ${i + 1}: ${orderRef.id}');
      }

      print('🎉 Successfully created ${testOrders.length} test orders');
    } catch (e, stackTrace) {
      print('💥 Error creating test orders: $e');
      print('📍 Stack trace: $stackTrace');
    }
  }

  /// Check if orders collection exists and has data
  static Future<void> checkOrdersCollection() async {
    try {
      print('🔍 Checking orders collection...');
      
      final snapshot = await _firestore.collection('orders').get();
      print('📊 Orders collection has ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isNotEmpty) {
        print('📄 Sample order data:');
        for (var doc in snapshot.docs.take(3)) {
          print('  - Order ${doc.id}: ${doc.data()}');
        }
      } else {
        print('⚠️ Orders collection is empty');
      }
    } catch (e) {
      print('💥 Error checking orders collection: $e');
    }
  }

  /// Test Firestore connection and authentication
  static Future<void> testFirestoreConnection() async {
    try {
      print('🔗 Testing Firestore connection...');
      
      final currentUser = _auth.currentUser;
      print('👤 Current user: ${currentUser?.uid ?? "null"} (${currentUser?.email ?? "no email"})');
      
      if (currentUser == null) {
        print('❌ User not authenticated');
        return;
      }

      // Try to read from a simple collection
      final testDoc = await _firestore.collection('test').doc('connection').get();
      print('✅ Firestore connection successful');
      
      // Try to write to test collection
      await _firestore.collection('test').doc('connection').set({
        'timestamp': Timestamp.now(),
        'userId': currentUser.uid,
        'test': true,
      });
      print('✅ Firestore write successful');
      
    } catch (e) {
      print('💥 Firestore connection error: $e');
    }
  }

  /// Clean up test data
  static Future<void> cleanupTestData() async {
    try {
      print('🧹 Cleaning up test data...');
      
      // Delete test orders
      final ordersSnapshot = await _firestore.collection('orders')
          .where('customerName', whereIn: ['John Doe', 'Jane Smith', 'Bob Johnson'])
          .get();
      
      for (var doc in ordersSnapshot.docs) {
        await doc.reference.delete();
        print('🗑️ Deleted test order: ${doc.id}');
      }
      
      // Delete test connection doc
      await _firestore.collection('test').doc('connection').delete();
      print('🗑️ Deleted test connection document');
      
      print('✅ Cleanup completed');
    } catch (e) {
      print('💥 Error during cleanup: $e');
    }
  }
}
