import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthGuard {
  static final List<String> publicRoutes = [
    '/splash',
    '/login',
    '/signup',
    '/onboarding',
    '/verify-email'
  ];

  static String? handleRedirect(BuildContext context, GoRouterState state) {
    // Web preview runs without Firebase auth configured, so don't gate routes.
    if (kIsWeb) return null;

    final isPublic = publicRoutes.contains(state.uri.path);
    final user = FirebaseAuth.instance.currentUser;

    // Not logged in -> go to login unless already on public route
    if (user == null) {
      return isPublic ? null : '/login';
    }

    // Logged in but not verified -> go to verify-email unless on public route
    if (!user.emailVerified) {
      return (state.uri.path == '/verify-email' ||
              state.uri.path == '/login' ||
              state.uri.path == '/signup')
          ? null
          : '/verify-email';
    }

    // Logged in and verified on public route (except splash/onboarding/verify) -> go home
    if (isPublic &&
        state.uri.path != '/splash' &&
        state.uri.path != '/onboarding' &&
        state.uri.path != '/verify-email') {
      return '/';
    }

    return null;
  }
}
