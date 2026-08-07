import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/forgot_password_email_screen.dart';
import 'screens/forgot_password_pin_screen.dart';
import 'screens/forgot_password_new_password_screen.dart';
import 'screens/register_verify_screen.dart';
import 'screens/register_complete_screen.dart';
import 'screens/stripe_success_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/onboarding_service.dart';

/// Top-level routes — all "shell" screens that matter for browser history.
/// Inner screens (PlantDetails, AddPlant, etc.) are pushed on top via
/// regular Navigator.push and don't need named routes.
final appRouter = GoRouter(
  initialLocation: '/welcome',
  redirect: _guardRedirect,
  refreshListenable: _AuthStateNotifier(),
  routes: [
    GoRoute(path: '/welcome', builder: (_, __) => const SplashScreen()),
    GoRoute(
      path: '/login',
      builder: (_, __) => const AuthScreen(isRegistration: false),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const AuthScreen(isRegistration: true),
    ),
    GoRoute(
      path: '/register/verify',
      builder: (_, state) {
        final email = state.extra as String? ?? '';
        return RegisterVerifyScreen(email: email);
      },
    ),
    GoRoute(
      path: '/register/complete',
      builder: (_, state) {
        final email = state.extra as String? ?? '';
        return RegisterCompleteScreen(email: email);
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (_, __) => const ForgotPasswordEmailScreen(),
    ),
    GoRoute(
      path: '/forgot-password/pin',
      builder: (_, state) {
        final email = state.extra as String? ?? '';
        return ForgotPasswordPinScreen(email: email);
      },
    ),
    GoRoute(
      path: '/forgot-password/reset',
      builder: (_, state) {
        final extra = (state.extra as Map?)?.cast<String, String>() ?? {};
        return ForgotPasswordNewPasswordScreen(
          email: extra['email'] ?? '',
          pin: extra['pin'] ?? '',
        );
      },
    ),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(
      path: '/home',
      builder: (_, __) =>
          MainNavigationScreen(user: FirebaseAuth.instance.currentUser),
    ),
    GoRoute(
      path: '/stripe-success',
      builder: (_, __) => const StripeSuccessScreen(),
    ),
  ],
);

String? _guardRedirect(BuildContext context, GoRouterState state) {
  final user = FirebaseAuth.instance.currentUser;
  final isAuthed = user != null;
  final path = state.uri.path;

  final isPublic =
      path == '/welcome' ||
      path == '/login' ||
      path == '/register' ||
      path.startsWith('/register/') ||
      path.startsWith('/forgot-password') ||
      path == '/stripe-success';

  // Not authed and trying to access protected route → send to welcome
  if (!isAuthed && !isPublic) return '/welcome';

  // Authed and on auth pages → check onboarding first
  if (isAuthed && isPublic) {
    if (!OnboardingService.isComplete) return '/onboarding';
    return '/home';
  }

  // Authed and already on /onboarding — only allowed if not yet complete
  if (isAuthed && path == '/onboarding' && OnboardingService.isComplete) {
    return '/home';
  }

  // Authed, on /home, but onboarding not done → redirect to onboarding
  if (isAuthed && path == '/home' && !OnboardingService.isComplete) {
    return '/onboarding';
  }

  return null;
}

/// Makes GoRouter react to Firebase auth state changes automatically.
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}
