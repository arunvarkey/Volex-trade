import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/services/startup_service.dart';
import 'package:volex_terminal/core/app_logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup fade animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Initialize app
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    try {
      // Web preview: Firebase/auth aren't configured on web, so skip the
      // Firebase-dependent startup routing and go straight to the app.
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go('/');
        return;
      }

      // Determine startup route
      final startupService = StartupService();
      final destination = await startupService.determineStartupRoute();

      // Ensure minimum splash time (better UX)
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds < 2000) {
        await Future.delayed(
          Duration(milliseconds: 2000 - elapsed.inMilliseconds),
        );
      }

      // Navigate based on destination
      if (!mounted) return;

      switch (destination) {
        case StartupDestination.onboarding:
          context.go('/onboarding');
          break;
        case StartupDestination.signup:
          context.go('/signup');
          break;
        case StartupDestination.modeSelection:
          context.go('/mode-selection');
          break;
        case StartupDestination.home:
          context.go('/');
          break;
      }
    } catch (e) {
      AppLogger.error('❌ Error during startup: $e');
      // Fallback to onboarding
      if (mounted) {
        context.go('/onboarding');
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
      backgroundColor: VxColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            VxColors.primary,
                            VxColors.neonPurple,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: VxColors.primary.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // App Name
              const Text(
                'Volex Terminal',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 12),

              // Tagline
              const Text(
                'AI-Powered Trading Signals',
                style: TextStyle(
                  fontSize: 16,
                  color: VxColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 60),

              // Loading indicator
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(VxColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
