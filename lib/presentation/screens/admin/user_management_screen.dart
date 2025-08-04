import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../providers/admin_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, users, admins
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(adminProvider.notifier).loadAllUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      await ref.read(adminProvider.notifier).toggleUserStatus(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user.isActive 
                ? 'User deactivated successfully' 
                : 'User activated successfully'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.firstName} ${user.lastName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(adminProvider.notifier).deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<UserModel> _getFilteredUsers(List<UserModel> users) {
    var filtered = users;

    // Apply role filter
    if (_selectedFilter == 'users') {
      filtered = filtered.where((user) => !user.isAdmin).toList();
    } else if (_selectedFilter == 'admins') {
      filtered = filtered.where((user) => user.isAdmin).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
        final email = user.email.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return fullName.contains(query) || email.contains(query);
      }).toList();
    }

    return filtered;
  }

  // Debug methods
  Future<void> _testFirestoreConnection() async {
    try {
      print('🔍 Testing Firestore connection...');
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      print('🔐 Current user: ${currentUser?.uid ?? "null"} (${currentUser?.email ?? "no email"})');
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Test basic Firestore access
      final testDoc = await FirebaseFirestore.instance.collection('users').limit(1).get();
      print('✅ Firestore connection successful. Found ${testDoc.docs.length} documents');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firestore connection successful! Found ${testDoc.docs.length} users'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Firestore connection failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firestore connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkUsersCollection() async {
    try {
      print('🔍 Checking users collection...');
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      print('📊 Users collection has ${snapshot.docs.length} documents');
      
      for (var doc in snapshot.docs.take(3)) {
        print('📄 User ${doc.id}: ${doc.data().keys.toList()}');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Users collection has ${snapshot.docs.length} documents'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('❌ Error checking users collection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Bar
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users by name or email...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filter Chips
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: Row(
                      children: [
                        const Text(
                          'Filter: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              _buildFilterChip('All Users', 'all'),
                              _buildFilterChip('Customers', 'users'),
                              _buildFilterChip('Admins', 'admins'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Users List
            Expanded(
              child: adminState.when(
                data: (data) {
                  final users = data.users ?? [];
                  final filteredUsers = _getFilteredUsers(users);
                  
                  if (filteredUsers.isEmpty) {
                    return EmptyState(
                      icon: Icons.people_outline,
                      title: _searchQuery.isNotEmpty || _selectedFilter != 'all'
                          ? 'No users found'
                          : 'No users yet',
                      message: _searchQuery.isNotEmpty || _selectedFilter != 'all'
                          ? 'Try adjusting your search or filter'
                          : 'Users will appear here once they register',
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: Duration(milliseconds: index * 100),
                          child: _buildUserCard(user),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ErrorState(
                      message: 'Failed to load users',
                      onRetry: _loadUsers,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Debug Tools:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        ElevatedButton(
                          onPressed: _testFirestoreConnection,
                          child: const Text('Test Connection'),
                        ),
                        ElevatedButton(
                          onPressed: _checkUsersCollection,
                          child: const Text('Check Users'),
                        ),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: const Text('Retry Load'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Error: $error',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildUserCard(UserModel user) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: user.isAdmin 
                      ? Colors.orange.withOpacity(0.2)
                      : AppTheme.primaryColor.withOpacity(0.2),
                  child: Icon(
                    user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: user.isAdmin ? Colors.orange : AppTheme.primaryColor,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${user.firstName} ${user.lastName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: user.isActive 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: user.isActive ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      
                      if (user.phoneNumber?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phoneNumber!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // User Details
            Row(
              children: [
                Icon(
                  user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  user.isAdmin ? 'Administrator' : 'Customer',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Joined ${dateFormatter.format(user.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _toggleUserStatus(user),
                  icon: Icon(
                    user.isActive ? Icons.block : Icons.check_circle,
                    size: 16,
                  ),
                  label: Text(user.isActive ? 'Deactivate' : 'Activate'),
                  style: TextButton.styleFrom(
                    foregroundColor: user.isActive ? Colors.orange : Colors.green,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                TextButton.icon(
                  onPressed: () => _deleteUser(user),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
