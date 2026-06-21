import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/repository/auth_repository.dart';

import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent A Partner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRouter.generateRoute,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Check for Biometric Lock
    try {
      final bioEnabled = await _storage.read(key: 'biometric_lock');
      if (bioEnabled == 'true') {
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to access Rent A Partner',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
        );
        if (!didAuthenticate) {
          if (mounted) setState(() => _isLocked = true);
          return;
        }
      }
    } catch (e) {
      debugPrint('Biometric error: $e');
    }

    if (!mounted) return;

    // 2. Auth Check
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final isLoggedIn = await authRepo.isLoggedIn();
      
      if (isLoggedIn) {
        final user = await authRepo.getMe();
        if (user != null && mounted) {
          ref.read(currentUserProvider.notifier).state = user;
          Navigator.pushReplacementNamed(context, AppRouter.home);
          return;
        }
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }

    // 3. Navigate to Login if not logged in or fetch failed
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/splash_bg.jpg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0F172A),
                child: const Center(
                  child: Icon(Icons.favorite, color: Color(0xFFFF4D8D), size: 100),
                ),
              ),
            ),
          ),
          if (_isLocked)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 80, color: Colors.white),
                    const SizedBox(height: 24),
                    const Text('App Locked', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _initializeApp,
                      child: const Text('Unlock with Biometrics'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
