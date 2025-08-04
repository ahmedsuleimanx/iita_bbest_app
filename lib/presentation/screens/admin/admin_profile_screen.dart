import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';

import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/admin_provider.dart';
import '../../widgets/common/adaptive_image.dart';
import '../../widgets/common/loading_overlay.dart';

import 'admin_edit_profile_screen.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('No user data available'),
            ),
          );
        }
        return _buildProfileScreen(context, ref, user);
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildProfileScreen(BuildContext context, WidgetRef ref, UserModel user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _navigateToEditProfile(user),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                FadeInDown(
                  child: _buildProfileHeader(user),
                ),
                const SizedBox(height: 24),
                
                // Personal Information
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildPersonalInfoSection(user),
                ),
                const SizedBox(height: 24),
                
                // Administrative Information
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _buildAdminInfoSection(user),
                ),
                const SizedBox(height: 24),
                
                // System Access & Permissions
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: _buildSystemAccessSection(user),
                ),
                const SizedBox(height: 24),
                
                // Account Statistics
                FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: _buildAccountStatsSection(user),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                FadeInUp(
                  delay: const Duration(milliseconds: 1000),
                  child: _buildActionButtons(user),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: user.profileImageUrl?.isNotEmpty == true
                        ? AdaptiveImage(
                            imagePath: user.profileImageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorWidget: Icon(
                              Icons.admin_panel_settings,
                              size: 50,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : Icon(
                            Icons.admin_panel_settings,
                            size: 50,
                            color: AppTheme.primaryColor,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Name and Role
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'System Administrator',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(UserModel user) {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person,
      children: [
        _buildInfoTile(
          icon: Icons.badge,
          title: 'Full Name',
          value: user.fullName,
        ),
        _buildInfoTile(
          icon: Icons.email,
          title: 'Email Address',
          value: user.email,
        ),
        _buildInfoTile(
          icon: Icons.phone,
          title: 'Phone Number',
          value: user.phoneNumber ?? 'Not provided',
        ),
        _buildInfoTile(
          icon: Icons.location_on,
          title: 'Address',
          value: user.addresses.isNotEmpty ? user.addresses.first : 'Not provided',
        ),
        _buildInfoTile(
          icon: Icons.calendar_today,
          title: 'Date of Birth',
          value: 'Not provided',
        ),
      ],
    );
  }

  Widget _buildAdminInfoSection(UserModel user) {
    return _buildSection(
      title: 'Administrative Information',
      icon: Icons.admin_panel_settings,
      children: [
        _buildInfoTile(
          icon: Icons.business,
          title: 'Department',
          value: 'Information Technology',
        ),
        _buildInfoTile(
          icon: Icons.work,
          title: 'Position',
          value: 'System Administrator',
        ),
        _buildInfoTile(
          icon: Icons.schedule,
          title: 'Admin Since',
          value: DateFormat('MMMM yyyy').format(user.createdAt),
        ),
        _buildInfoTile(
          icon: Icons.info,
          title: 'Bio',
          value: 'No bio provided',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSystemAccessSection(UserModel user) {
    final permissions = [
      'User Management',
      'Product Management',
      'Order Management',
      'Analytics & Reports',
      'System Settings',
      'Database Access',
      'Security Controls',
      'Backup & Maintenance',
    ];

    return _buildSection(
      title: 'System Access & Permissions',
      icon: Icons.security,
      children: [
        _buildInfoTile(
          icon: Icons.verified_user,
          title: 'Access Level',
          value: 'Full Administrator',
        ),
        _buildInfoTile(
          icon: Icons.last_page,
          title: 'Last Login',
          value: user.updatedAt != null ? DateFormat('MMM dd, yyyy').format(user.updatedAt!) : 'Never',
        ),
        const SizedBox(height: 16),
        Text(
          'Granted Permissions',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: permissions.map((permission) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  permission,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildAccountStatsSection(UserModel user) {
    return _buildSection(
      title: 'Account Statistics',
      icon: Icons.analytics,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.schedule,
                title: 'Account Age',
                value: _calculateAccountAge(user.createdAt),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.login,
                title: 'Member Since',
                value: DateFormat('MMM yyyy').format(user.createdAt),
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.verified,
                title: 'Account Status',
                value: user.isAdmin ? 'Admin' : 'User',
                color: user.isAdmin ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.update,
                title: 'Last Updated',
                value: user.updatedAt != null 
                    ? DateFormat('MMM dd').format(user.updatedAt!)
                    : 'Never',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(UserModel user) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToEditProfile(user),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showChangePasswordDialog,
            icon: const Icon(Icons.lock),
            label: const Text('Change Password'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _calculateAccountAge(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''}';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    }
  }

  void _navigateToEditProfile(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEditProfileScreen(user: user),
      ),
    );
  }

  Future<void> _refreshProfile() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(extendedAuthProvider.notifier).refreshUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh profile: ${e.toString()}'),
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

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('This feature will redirect you to the password change screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to change password screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password change feature coming soon'),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from your admin account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await ref.read(extendedAuthProvider.notifier).logout();
                if (mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
