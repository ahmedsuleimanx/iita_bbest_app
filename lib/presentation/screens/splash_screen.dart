import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _startAnimation();
    
    // Add timeout to prevent infinite splash screen
    _setupSplashTimeout();
  }

  void _setupSplashTimeout() {
    // Auto-navigate after 3 seconds to prevent infinite loading
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final authState = ref.read(authProvider);
        
        // Handle different auth states
        authState.when(
          data: (user) {
            if (user != null) {
              context.go('/home');
            } else {
              // Navigate to onboarding for role selection
              context.go('/onboarding');
            }
          },
          loading: () {
            // Still loading, navigate to onboarding as fallback
            context.go('/onboarding');
          },
          error: (error, stack) {
            // Authentication error, navigate to onboarding
            print('Auth error in splash: $error');
            context.go('/onboarding');
          },
        );
      }
    });
  }

  void _startAnimation() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(51), // 0.2 opacity = 51/255
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/images/iita-logo.jpeg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.agriculture,
                                        size: 60,
                                        color: AppTheme.primaryColor,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // App Title
                              FadeInUp(
                                delay: const Duration(milliseconds: 600),
                                child: Text(
                                  'IITA BBEST',
                                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Subtitle
                              FadeInUp(
                                delay: const Duration(milliseconds: 800),
                                child: Text(
                                  'Agricultural Products Marketplace',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.black.withAlpha(26), // 0.1 opacity = 26/255
                                    fontWeight: FontWeight.w300,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Loading indicator
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInUp(
                      delay: const Duration(milliseconds: 1200),
                      child: const SpinKitThreeBounce(
                        color: Colors.white,
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      delay: const Duration(milliseconds: 1400),
                      child: Text(
                        'Loading fresh agricultural products...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withAlpha(204), // 0.8 opacity = 204/255
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: FadeInUp(
                  delay: const Duration(milliseconds: 1600),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.eco,
                            color: Colors.white.withAlpha(179),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sustainable Agriculture',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withAlpha(179), // 0.7 opacity = 179/255
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.eco,
                            color: Colors.white.withAlpha(179),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Empowering Farmers • Building Communities',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(153), // 0.6 opacity = 153/255
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 