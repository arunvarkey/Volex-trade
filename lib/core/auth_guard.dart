import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthGuard {
  static final List<String> publicRoutes = [
    '/splash',
    '/login',
    '/signup',
    '/onboarding',
    '/risk-disclosure',
    '/verify-email'
  ];

  static String? handleRedirect(BuildContext context, GoRouterState state) {
    // Web preview runs without Firebase auth configured, so don't gate routes.
    if (kIsWeb) return null;

    // Native without a configured Firebase project (no google-services.json):
    // run open, exactly like the web preview, instead of crashing on
    // FirebaseAuth.instance.
    if (Firebase.apps.isEmpty) return null;

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

    // Logged in and verified on public route (except splash/onboarding/
    // risk-disclosure/verify) -> go home. The risk disclosure has to survive
    // this bounce: an existing signed-in user who hasn't acknowledged it yet
    // is routed there by the splash and must be allowed to stay.
    if (isPublic &&
        state.uri.path != '/splash' &&
        state.uri.path != '/onboarding' &&
        state.uri.path != '/risk-disclosure' &&
        state.uri.path != '/verify-email') {
      return '/';
    }

    return null;
  }
}
