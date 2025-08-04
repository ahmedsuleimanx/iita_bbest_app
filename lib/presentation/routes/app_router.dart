import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iita_bbest_app/presentation/screens/home/home_screen.dart';
import 'package:iita_bbest_app/presentation/screens/home/main_screen.dart';
import 'package:iita_bbest_app/presentation/screens/orders/order_history_screen.dart';

import '../../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/admin_login_screen.dart';
import '../screens/auth/admin_register_screen.dart';
import '../screens/onboarding/role_selection_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/product_management_screen.dart';
import '../screens/admin/order_management_screen.dart';
import '../screens/admin/admin_profile_screen.dart';
import '../screens/admin/user_management_screen.dart';

// Singleton router instance to prevent GlobalKey conflicts
class AppRouter {
  static GoRouter? _instance;
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  
  static GoRouter getInstance(ProviderRef ref) {
    _instance ??= GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isOnAuthPages = state.matchedLocation.startsWith('/auth/');
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      
      // Get current auth state without watching to prevent router recreation
      final authState = ref.read(authProvider);
      
      // Handle different auth states
      return authState.when(
        data: (user) {
          final isAuthenticated = user != null;
          
          // If on splash and not loading, redirect based on auth state
          if (isOnSplash) {
            if (isAuthenticated) {
              // Redirect admin users to admin dashboard, regular users to home
              return user.isAdmin ? '/admin' : '/home';
            } else {
              return '/onboarding';
            }
          }
          
          if (!isAuthenticated) {
            // Not authenticated - redirect to onboarding except if already on auth/onboarding pages
            if (!isOnAuthPages && !isOnOnboarding) {
              return '/onboarding';
            }
          } else {
            // Authenticated - redirect away from auth and onboarding pages
            if (isOnAuthPages || isOnOnboarding) {
              // Redirect admin users to admin dashboard, regular users to home
              return user.isAdmin ? '/admin' : '/home';
            }
            
            // Admin route protection - prevent non-admins from accessing admin routes
            if (state.matchedLocation.startsWith('/admin/') && !user.isAdmin) {
              return '/home';
            }
            
            // Regular user route protection - prevent admins from accessing regular user routes unnecessarily
            // (Optional: you can remove this if you want admins to access regular user features)
            if (user.isAdmin && state.matchedLocation == '/home') {
              return '/admin';
            }
          }
          
          return null; // No redirect needed
        },
        loading: () {
          // Show splash while loading
          if (isOnSplash) {
            return null; // Stay on splash while loading
          }
          // For other pages, let them load normally
          return null;
        },
        error: (error, stack) {
          // Authentication error - redirect to onboarding unless already there
          if (!isOnAuthPages && !isOnSplash && !isOnOnboarding) {
            return '/onboarding';
          }
          return null;
        },
      );
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding screen
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      
      // Authentication routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Admin authentication routes
      GoRoute(
        path: '/auth/admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/auth/admin-register',
        builder: (context, state) => const AdminRegisterScreen(),
      ),
      
      // Main app with shell navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) {
              final category = state.uri.queryParameters['category'];
              return ProductListScreen(category: category);
            },
            routes: [
              GoRoute(
                path: '/:productId',
                builder: (context, state) {
                  final productId = state.pathParameters['productId']!;
                  return ProductDetailScreen(productId: productId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) {
              final query = state.uri.queryParameters['q'] ?? '';
              return SearchScreen(initialQuery: query);
            },
          ),
        ],
      ),
      
      // Full-screen routes (outside shell)
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderHistoryScreen(),
        routes: [
          GoRoute(
            path: '/:orderId',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return OrderDetailScreen(orderId: orderId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      
      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const ProductManagementScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const OrderManagementScreen(),
      ),
      GoRoute(
        path: '/admin/profile',
        builder: (context, state) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
    
    return _instance!;
  }
}

// Create a stable router provider that doesn't recreate on every auth state change
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.getInstance(ref);
});

// Navigation helpers
extension AppRouterExtension on GoRouter {
  void goToLogin() => go('/auth/login');
  void goToSignup() => go('/auth/signup');
  void goToHome() => go('/home');
  void goToProducts({String? category}) {
    final uri = Uri(path: '/products', queryParameters: category != null ? {'category': category} : null);
    go(uri.toString());
  }
  void goToProductDetail(String productId) => go('/products/$productId');
  void goToCart() => go('/cart');
  void goToCheckout() => go('/checkout');
  void goToProfile() => go('/profile');
  void goToEditProfile() => go('/profile/edit');
  void goToOrders() => go('/orders');
  void goToOrderDetail(String orderId) => go('/orders/$orderId');
  void goToSearch({String? query}) {
    final uri = Uri(path: '/search', queryParameters: query != null ? {'q': query} : null);
    go(uri.toString());
  }
  void goToAdmin() => go('/admin');
  void goToAdminProducts() => go('/admin/products');
  void goToAdminOrders() => go('/admin/orders');
} 