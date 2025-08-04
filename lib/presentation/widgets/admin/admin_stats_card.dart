import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/admin_provider.dart';

class AdminStatsCard extends ConsumerWidget {
  const AdminStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Admin Dashboard Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: FadeInLeft(
                    delay: const Duration(milliseconds: 200),
                    child: _buildStatItem(
                      context,
                      icon: Icons.shopping_bag,
                      title: 'Total Orders',
                      value: '${stats['totalOrders']}',
                      subtitle: 'All time',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FadeInLeft(
                    delay: const Duration(milliseconds: 400),
                    child: _buildStatItem(
                      context,
                      icon: Icons.attach_money,
                      title: 'Total Revenue',
                      value: '\$${(stats['totalRevenue'] as double).toStringAsFixed(2)}',
                      subtitle: 'All time',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FadeInLeft(
                    delay: const Duration(milliseconds: 600),
                    child: _buildStatItem(
                      context,
                      icon: Icons.schedule,
                      title: 'Pending Orders',
                      value: '${stats['pendingOrders']}',
                      subtitle: 'Need attention',
                      isWarning: stats['pendingOrders'] > 0,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FadeInLeft(
                    delay: const Duration(milliseconds: 800),
                    child: _buildStatItem(
                      context,
                      icon: Icons.check_circle,
                      title: 'Completed',
                      value: '${stats['completedOrders']}',
                      subtitle: 'Delivered',
                      isSuccess: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Average Order Value
            FadeInUp(
              delay: const Duration(milliseconds: 1000),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Average Order Value',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '\$${(stats['averageOrderValue'] as double).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    bool isWarning = false,
    bool isSuccess = false,
  }) {
    Color iconColor = Colors.white;
    Color backgroundColor = Colors.white.withOpacity(0.2);
    
    if (isWarning) {
      iconColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.2);
    } else if (isSuccess) {
      iconColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.2);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = color ?? AppTheme.primaryColor;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: actionColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminQuickActions extends StatelessWidget {
  const AdminQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: QuickActionCard(
                icon: Icons.add_shopping_cart,
                title: 'Add Product',
                subtitle: 'Create new product',
                onTap: () {
                  // Navigate to add product screen
                },
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: QuickActionCard(
                icon: Icons.inventory,
                title: 'Manage Inventory',
                subtitle: 'Update stock levels',
                onTap: () {
                  // Navigate to inventory management
                },
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: QuickActionCard(
                icon: Icons.people,
                title: 'User Management',
                subtitle: 'Manage customers',
                onTap: () {
                  // Navigate to user management
                },
                color: Colors.blue,
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: QuickActionCard(
                icon: Icons.analytics,
                title: 'View Reports',
                subtitle: 'Sales analytics',
                onTap: () {
                  // Navigate to reports
                },
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
