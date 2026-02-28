import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

import 'package:go_router/go_router.dart';
import 'package:volex_terminal/features/subscriptions/services/subscription_service.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/providers/strategy_provider.dart';
import 'package:volex_terminal/services/analytics_service.dart';
import 'components/ai_input_form.dart';
import 'components/ai_strategy_results.dart';
import 'package:volex_terminal/services/haptic_service.dart';

/// AI Strategy Generator - KILLER FEATURE
/// Generates trading strategies using GPT-4 based on user description
class AIStrategyGeneratorScreen extends StatefulWidget {
  const AIStrategyGeneratorScreen({super.key});

  @override
  State<AIStrategyGeneratorScreen> createState() =>
      _AIStrategyGeneratorScreenState();
}

class _AIStrategyGeneratorScreenState extends State<AIStrategyGeneratorScreen> {
  final _descriptionController = TextEditingController();
  final _symbolController = TextEditingController(text: 'BTCUSDT');

  String _timeframe = '1h';
  double _riskTolerance = 0.5; // 0-1 scale
  bool _useCompanyKey = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'AI Strategy Builder',
          style: VxTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        actions: [
          _buildSubscriptionBadge(),
        ],
      ),
      body: SafeArea(
        child: Consumer<StrategyProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _buildGeneratingState(provider.currentStrategy == null
                  ? 'Creating strategy...'
                  : 'Running backtest...');
            }

            // Show Error if needed (could be a banner or snackbar, here simple banner on top)
            if (provider.error != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showError(provider.error!);
                provider.clearError();
              });
            }

            if (provider.currentStrategy != null) {
              return AIStrategyResults(
                strategy: provider.currentStrategy!,
                backtestResult: provider.backtestResult,
                onRunBacktest: _runBacktest,
                onReset: () {
                  provider.clearStrategy();
                },
                onDeploy: _deployStrategy,
                isBacktesting: provider
                    .isLoading, // Redundant if handled by outer loading check
              );
            }

            return Consumer<SubscriptionService>(
                builder: (context, subscriptionService, _) {
              final isPro = subscriptionService.currentStatus.isProMode ||
                  subscriptionService.currentStatus.isPremium;
              return AIInputForm(
                descriptionController: _descriptionController,
                symbolController: _symbolController,
                timeframe: _timeframe,
                riskTolerance: _riskTolerance,
                isGenerating: provider.isLoading,
                onTimeframeChanged: (tf) => setState(() => _timeframe = tf),
                onRiskRiskToleranceChanged: (val) =>
                    setState(() => _riskTolerance = val),
                canUseCompanyKey: isPro,
                useCompanyKey: _useCompanyKey,
                onUseCompanyKeyChanged: (val) =>
                    setState(() => _useCompanyKey = val),
                onGenerate: _generateStrategy,
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildSubscriptionBadge() {
    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, _) {
        final subscription = subscriptionService.currentStatus;
        if (subscription.isPremium) {
          return Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: VxColors.neonCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: VxColors.neonCyan.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                'PREMIUM',
                style: VxTypography.caption.copyWith(
                  color: VxColors.neonCyan,
                  fontWeight: FontWeight.w900,
                  fontSize: 8,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGeneratingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 200,
            child: Icon(
              Icons.auto_awesome,
              size: 80,
              color: VxColors.neonCyan,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: VxTypography.h2.copyWith(
              color: VxColors.neonCyan,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing your idea...',
            style:
                VxTypography.body.copyWith(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _generateStrategy() async {
    if (_descriptionController.text.trim().isEmpty) {
      HapticService.instance.warning(); // Tactile error
      _showError('Please describe your strategy');
      return;
    }

    // Soft Gate Check
    final subscriptionService = context.read<SubscriptionService>();
    final canGenerate =
        await subscriptionService.checkAndTrackStrategyGeneration();

    if (!canGenerate) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: VxColors.surface,
          title: const Text(
            'LIMIT REACHED',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "You've used your 3 free AI strategies today. Upgrade to Premium for unlimited generation — \$4.99/month.",
            style: TextStyle(color: VxColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later',
                  style: TextStyle(color: VxColors.textTertiary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/subscription');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: VxColors.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Unlock Now'),
            ),
          ],
        ),
      );
      return;
    }

    HapticService.instance.selection(); // Confirmation of button press

    if (!mounted) return;
    final provider = context.read<StrategyProvider>();

    // Analytics
    AnalyticsService.instance.logEvent(
      'ai_strategy_generation_started',
      parameters: {
        'timeframe': _timeframe,
        'risk_level': _riskTolerance.toString(),
        'pro_mode': _useCompanyKey.toString(),
      },
    );

    await provider.generateStrategy(_descriptionController.text,
        useCompanyKey: _useCompanyKey);

    if (provider.currentStrategy != null) {
      HapticService.instance.successPulse(); // Synthesis complete pulse
      AnalyticsService.instance.logEvent('ai_strategy_generated');
    }
  }

  Future<void> _runBacktest() async {
    HapticService.instance.selection();
    final provider = context.read<StrategyProvider>();
    await provider.runBacktest();
    if (provider.backtestResult != null) {
      HapticService.instance.medium();
      AnalyticsService.instance.logEvent('ai_strategy_backtested');
    }
  }

  void _deployStrategy() {
    HapticService.instance.successPulse();
    AnalyticsService.instance.logEvent('strategy_deployed');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Strategy deployed successfully!'),
        backgroundColor: VxColors.neonGreen,
      ),
    );

    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: VxColors.neonRed,
      ),
    );
  }
}
