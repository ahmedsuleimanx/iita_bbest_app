import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/routes/app_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class IITABBestApp extends ConsumerStatefulWidget {
  const IITABBestApp({super.key});

  @override
  ConsumerState<IITABBestApp> createState() => _IITABBestAppState();
}

class _IITABBestAppState extends ConsumerState<IITABBestApp> {
  @override
  void initState() {
    super.initState();
    
    // Initialize app authentication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // Check authentication state in background
    try {
      await ref.read(authProvider.notifier).checkAuthState()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Auth state check failed: $e');
      // App will still work, just might need manual login
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'IITA BBEST',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
} 