import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/permissions/permissions_screen.dart';
import 'features/auth/connection_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/download_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/beneficiario_detail_screen.dart';
import 'features/bitacora/bitacora_screen.dart';
import 'features/bitacora/bitacora_success_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/terminos_screen.dart';
import 'features/profile/config_screen.dart';
import 'features/historial/historial_screen.dart';
import 'features/about/about_screen.dart';
import 'shared/models/beneficiario.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/permissions', builder: (_, __) => const PermissionsScreen()),
      GoRoute(path: '/connection', builder: (_, __) => const ConnectionScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/download', builder: (_, __) => const DownloadScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: '/beneficiario/:id',
        builder: (_, state) {
          final b = state.extra as Beneficiario?;
          if (b == null) return const DashboardScreen();
          return BeneficiarioDetailScreen(beneficiario: b);
        },
      ),
      GoRoute(path: '/bitacora', builder: (_, state) {
        return const BitacoraScreen();
      }),
      GoRoute(
        path: '/bitacora-success',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BitacoraSuccessScreen(isOffline: extra?['offline'] as bool? ?? false);
        },
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/config', builder: (_, __) => const ConfigScreen()),
      GoRoute(path: '/historial', builder: (_, __) => const HistorialScreen()),
      GoRoute(path: '/terminos', builder: (_, __) => const TerminosScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
    ],
    errorBuilder: (_, __) => const Scaffold(
      body: Center(child: Text('Página no encontrada')),
    ),
  );
}
