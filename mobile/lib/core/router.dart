import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'auth/auth_provider.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/qr/qr_screen.dart';
import '../features/nfc/nfc_screen.dart';
import '../features/earnings/earnings_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;
      final location = state.matchedLocation;

      if (location == '/splash') return null;
      if (status == AuthStatus.unknown) return '/splash';

      if (status == AuthStatus.unauthenticated) {
        if (location == '/onboarding' ||
            location == '/login' ||
            location == '/register') {
          return null;
        }
        return '/login';
      }

      if (status == AuthStatus.authenticated) {
        if (location == '/login' || location == '/register') {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/qr',
        builder: (_, __) => const QrScreen(),
      ),
      GoRoute(
        path: '/nfc',
        builder: (_, __) => const NfcScreen(),
      ),
      GoRoute(
        path: '/earnings',
        builder: (_, __) => const EarningsScreen(),
      ),
    ],
  );
}
