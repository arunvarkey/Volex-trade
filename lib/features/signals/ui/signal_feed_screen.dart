import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:volex_terminal/features/signals/models/trade_signal.dart';
import 'package:volex_terminal/features/signals/services/signal_engine.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_card.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/widgets/paywalls/signal_limit_banner.dart';
import 'package:volex_terminal/features/subscriptions/services/subscription_service.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/services/startup_service.dart';
import 'package:volex_terminal/ui/widgets/paywalls/upgrade_prompt_dialog.dart';

class SignalFeedScreen extends StatefulWidget {
  const SignalFeedScreen({super.key});

  @override
  State<SignalFeedScreen> createState() => _SignalFeedScreenState();
}

class _SignalFeedScreenState extends State<SignalFeedScreen> {
  final SignalEngine _engine = getIt<SignalEngine>();
  final List<TradeSignal> _signals = [];
  StreamSubscription<TradeSignal>? _sub;
  bool _scanning = true;
  bool _upgradeDismissed = false;

  @override
  void initState() {
    super.initState();
    // Seed from any signals the engine already generated — the broadcast
    // stream doesn't replay, so without this the feed would sit empty.
    _signals.addAll(_engine.recentSignals);

    _sub = _engine.signalStream.listen((signal) {
      if (mounted) {
        setState(() {
          _signals.insert(0, signal);
          if (_signals.length > 50) _signals.removeLast();
        });
      }
    });

    if (_signals.isEmpty) {
      _refresh();
    } else {
      _scanning = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _scanning = true);
    await _engine.scanNow();
    if (mounted) setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SignalLimitBanner(),
            Expanded(
              child: _signals.isEmpty
                  ? (_scanning ? _buildScanningState() : _buildNoSignalsState())
                  : Consumer<SubscriptionService>(
                      builder: (context, subscription, child) {
                        final limit = subscription.maxSignals;
                        final showUpgrade = _signals.length > limit &&
                            !subscription.isPremium &&
                            !_upgradeDismissed;
                        final displayCount =
                            showUpgrade ? limit : _signals.length;

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayCount + (showUpgrade ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == displayCount) {
                              return _buildUpgradeCard();
                            }
                            return _SignalCard(signal: _signals[index]);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VxText.heading2('Live Signals', color: Colors.white),
          const SizedBox(height: 8),
          VxText.body('Real-time AI opportunities from the Volex Engine.',
              color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: VxColors.primary),
          const SizedBox(height: 16),
          VxText.body('Scanning markets...', color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildNoSignalsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radar_rounded,
                color: VxColors.textTertiary, size: 48),
            const SizedBox(height: 16),
            VxText.subtitle('No signals right now', color: Colors.white70),
            const SizedBox(height: 8),
            VxText.body(
              'The engine re-scans the market every minute. Check back shortly or scan again now.',
              color: Colors.white38,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Scan now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VxColors.primary.withValues(alpha: 0.1),
            VxColors.primary.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(color: VxColors.primary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_open, color: VxColors.primary, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Unlock Unlimited Signals',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ve seen today\'s free signals. Premium members get unlimited signals delivered first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/subscription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VxColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('See Plans'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _upgradeDismissed = true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text("I'm Good"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final TradeSignal signal;

  const _SignalCard({required this.signal});

  @override
  Widget build(BuildContext context) {
    final isBuy = signal.side.name.toLowerCase() == 'buy';
    final color = isBuy ? VxColors.neonGreen : VxColors.neonRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => context.push('/chart?symbol=${signal.symbol}'),
        borderRadius: BorderRadius.circular(16),
        child: VxCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Symbol + Side + Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isBuy ? Icons.arrow_upward : Icons.arrow_downward,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VxText.bodyBold(signal.symbol),
                            VxText.caption(signal.strategyName,
                                color: Colors.white38),
                          ],
                        ),
                      ],
                    ),
                    _ConfidenceBadge(confidence: signal.confidence),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),

                // Prices
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PriceColumn(
                        label: 'ENTRY',
                        price: signal.entryPrice,
                        color: Colors.white),
                    _PriceColumn(
                        label: 'TARGET',
                        price: signal.takeProfit,
                        color: VxColors.neonGreen),
                    _PriceColumn(
                        label: 'STOP',
                        price: signal.stopLoss,
                        color: VxColors.neonRed),
                  ],
                ),

                const SizedBox(height: 16),

                // Reasoning
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    signal.reasoning,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ),

                // AI Warning
                if (signal.aiWarning != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          signal.aiWarning!,
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Actions
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final canView = await getIt<SubscriptionService>()
                          .checkAndTrackSignalView(signal.id);

                      if (!canView) {
                        if (context.mounted) {
                          context.push('/subscription');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Daily limit reached. Upgrade to Premium!')),
                          );
                        }
                        return;
                      }

                      Clipboard.setData(
                          ClipboardData(text: signal.toShareableText()));

                      // Track interaction and check for upgrade prompt
                      await StartupService().trackSignalView();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Signal copied to clipboard!')),
                        );

                        // Show prompt if needed
                        await UpgradePromptDialog.showIfNeeded(context);
                      }
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('COPY SIGNAL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                if (signal.isExpired)
                  Center(
                      child: VxText.caption("EXPIRED", color: Colors.white24))
                else
                  Center(
                      child: VxText.caption(
                          "Expires in ${signal.timeRemaining.inMinutes}m",
                          color: Colors.white24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  final String label;
  final double price;
  final Color color;

  const _PriceColumn(
      {required this.label, required this.price, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(price.toStringAsFixed(2),
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: VxColors.neonPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.neonPurple.withValues(alpha: 0.3)),
      ),
      child: Text(
        "${confidence.toStringAsFixed(0)}%",
        style: const TextStyle(
            color: VxColors.neonPurple,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
