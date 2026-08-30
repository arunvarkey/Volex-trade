import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:volex_terminal/features/subscriptions/models/subscription_tier.dart';
import 'package:volex_terminal/features/subscriptions/services/subscription_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/core/service_locator.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final bool _loading = false;
  bool _isAnnual = true; // Default to annual

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  // Title
                  const Text(
                    'Upgrade Your Trading Skills',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Learn faster with unlimited AI tools and advanced analytics.',
                    style: TextStyle(
                      fontSize: 16,
                      color: VxColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Tiers
                  _buildFreeTier(),
                  const SizedBox(height: 24),
                  _buildPremiumTier(),

                  const SizedBox(height: 32),

                  // Legal Footer
                  _buildFooter(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildFreeTier() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VxColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Free Forever',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Everything you need to start learning',
            style: TextStyle(fontSize: 14, color: VxColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildFeature('Simulated trading with \$100k balance'),
          _buildFeature('Real-time market data'),
          _buildFeature('3 AI strategy generations per day'),
          _buildFeature('1 backtest per day'),
          _buildFeature('10 trade signals per day'),
          _buildFeature('Basic candlestick charts'),
          _buildFeature('Trade checks that flag risky habits'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null, // Always active / fallback
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: VxColors.border),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Current Plan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTier() {
    return Container(
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VxColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: VxColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: VxColors.primary.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: const Text(
              'MOST POPULAR',
              style: TextStyle(
                color: VxColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Premium',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'For traders who want to improve seriously',
                  style: TextStyle(fontSize: 14, color: VxColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Toggle
                _buildBillingToggle(),
                const SizedBox(height: 24),

                const Text(
                  'Everything in Free, plus:',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildFeature('Unlimited AI strategy generation'),
                _buildFeature('Unlimited backtesting with metrics'),
                _buildFeature('Unlimited trade signals'),
                _buildFeature('All technical indicators'),
                _buildFeature('Strategy Optimizer (genetic algo)'),
                _buildFeature('Buzz & Predictions event markets'),
                _buildFeature('Export trade history (CSV)'),
                _buildFeature('Custom watchlists'),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _purchaseSelectedPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VxColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start 7-Day Free Trial',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _isAnnual
                        ? 'Then \$39.99/year (just \$3.33/mo)'
                        : 'Then \$4.99/month',
                    style: const TextStyle(
                      fontSize: 12,
                      color: VxColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Cancel anytime in Store settings',
                    style: TextStyle(
                      fontSize: 11,
                      color: VxColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      decoration: BoxDecoration(
        color: VxColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isAnnual ? VxColors.neutral700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Center(
                  child: Text(
                    'Monthly\n\$4.99/mo',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isAnnual ? VxColors.neutral700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Yearly',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$39.99/yr',
                      style: TextStyle(
                        color: _isAnnual
                            ? VxColors.neonGreen
                            : VxColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 18, color: VxColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _textButton('Terms of Service'),
            const Text(' · ', style: TextStyle(color: VxColors.textTertiary)),
            _textButton('Privacy Policy'),
            const Text(' · ', style: TextStyle(color: VxColors.textTertiary)),
            _textButton('Restore Purchases', onTap: _restorePurchases),
          ],
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Subscriptions auto-renew unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in your device\'s subscription settings. Payment is charged to your Apple ID or Google Play account at confirmation of purchase.',
            style: TextStyle(fontSize: 10, color: VxColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _textButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: VxColors.textSecondary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  bool _blockOnWeb() {
    if (!kIsWeb) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Purchases are available in the Volex mobile app.'),
      ),
    );
    return true;
  }

  void _restorePurchases() async {
    if (_blockOnWeb()) return;
    await getIt<SubscriptionService>().restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoring purchases...')),
      );
    }
  }

  void _purchaseSelectedPlan() async {
    if (_blockOnWeb()) return;
    final productToBuy = _isAnnual
        ? SubscriptionProduct.premiumYearly
        : SubscriptionProduct.explorerPremium;

    try {
      final success =
          await getIt<SubscriptionService>().purchaseSubscription(productToBuy);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: VxColors.danger,
          ),
        );
      }
    }
  }
}
