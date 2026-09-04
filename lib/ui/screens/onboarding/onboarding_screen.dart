import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/services/startup_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // These are the first words anyone reads, so they say what the app is
  // rather than what it would be impressive to be.
  //
  // The previous three slides led with "AI Trading Signals ... based on
  // advanced market analysis", which oversells a simulator the same way the
  // old splash tagline did, and closed with "Join thousands of traders using
  // AI to make better decisions" — invented social proof for an app that has
  // not launched and has no users. Claiming a crowd that does not exist is
  // both untrue and the kind of statement a store reviewer treats as
  // misleading.
  //
  // The order now follows the product: what it is, how you improve, how deep
  // it goes. Every claim below is something the app actually does.
  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      icon: Icons.shield_outlined,
      title: 'Trade without the risk',
      description:
          'Practise with virtual money against real market prices. Nothing '
          'here touches a real account.',
      color: VxColors.neonGreen,
    ),
    const OnboardingPage(
      icon: Icons.school_outlined,
      title: 'Learn as you go',
      description:
          'Short lessons on orders, stop-losses and position sizing — each '
          'one opens the screen where you can try it straight away.',
      color: VxColors.neonCyan,
    ),
    const OnboardingPage(
      icon: Icons.insights_rounded,
      title: 'Test before you trust',
      description:
          'Backtest a strategy on historical data with fees and slippage '
          'applied, and keep a journal of every trade you make.',
      color: VxColors.neonPurple,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as complete
    await StartupService().markOnboardingComplete();

    if (!mounted) return;
    // Firebase-free (no google-services.json): there's no auth backend, so
    // skip account creation and continue into the app as a guest — otherwise
    // the user gets stuck on a signup/login screen that can never succeed.
    if (Firebase.apps.isEmpty) {
      context.go('/mode-selection');
    } else {
      context.go('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _skipToEnd,
                    child: const Text('Skip'),
                  ),
                ),
              )
            else
              const SizedBox(height: 56),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? VxColors.primary
                        : VxColors.textTertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VxColors.primary,
                    foregroundColor: VxColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: VxColors
                          .deepBlack, // ✅ FIXED: Dark text on light button
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page.color.withValues(alpha: 0.2),
                  page.color.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: VxColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
