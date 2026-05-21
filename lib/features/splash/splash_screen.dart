import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/secure_storage.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    if (_navigated) return;

    final hasUrl = await SecureStorage.hasUrl();
    if (!hasUrl) {
      await SecureStorage.saveServerUrl(SecureStorage.defaultUrl);
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _navigated) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_completado') ?? false;
    final permisosDone = prefs.getBool('permisos_concedidos') ?? false;
    final hasToken = await SecureStorage.hasToken();

    String target;
    if (!onboardingDone) {
      target = '/onboarding';
    } else if (!permisosDone) {
      target = '/permissions';
    } else if (hasToken) {
      await ref.read(authProvider.notifier).checkSession();
      if (!mounted || _navigated) return;
      target = '/dashboard';
    } else {
      target = '/login';
    }

    _navigated = true;
    if (mounted) {
      context.go(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.guinda,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/Mesa-de-trabajo-2_1.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            const Text(
              'SADERH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1),
            const SizedBox(height: 6),
            Text(
              'Gestion de Campo',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
            const SizedBox(height: 48),
            SizedBox(
              width: 40,
              height: 40,
              child: Lottie.asset('assets/loading.json'),
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
