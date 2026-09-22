import 'package:flutter/material.dart';
import '../../../engine/marketplace/marketplace_service.dart';
import '../../../engine/marketplace/models/strategy_listing.dart';
import '../../../core/service_locator.dart';
import '../../design_system/vx_colors.dart';

class StrategyDetailsScreen extends StatefulWidget {
  final StrategyListing strategy;

  const StrategyDetailsScreen({super.key, required this.strategy});

  @override
  State<StrategyDetailsScreen> createState() => _StrategyDetailsScreenState();
}

class _StrategyDetailsScreenState extends State<StrategyDetailsScreen> {
  final MarketplaceService _marketplace = getIt<MarketplaceService>();
  bool _isSubscribing = false;
  late bool _isSubscribed;

  @override
  void initState() {
    super.initState();
    _isSubscribed = _marketplace.isSubscribed(widget.strategy.id);
  }

  Future<void> _handleSubscribe() async {
    setState(() => _isSubscribing = true);

    final success = await _marketplace.subscribeToStrategy(widget.strategy.id);

    if (mounted) {
      setState(() {
        _isSubscribing = false;
        if (success) {
          _isSubscribed = true;
          // Show Success Toast via ScaffoldMessenger if VxToast isn't global
          // Say the limitation here rather than letting the user find it
          // when they try to run the thing. Publishing records a listing —
          // title, description, reported figures — not the rules, so the
          // registry hands back an UnavailableStrategy that takes no
          // trades. Adding it is still useful as a reading list; pretending
          // it is runnable is not.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 6),
              backgroundColor: VxColors.positive,
              content: Text(
                "Added to your strategies. Its rules are not included, so it "
                "cannot be run or backtested — rebuild it in the Strategy "
                "Builder from the description.",
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine tier color
    Color tierColor = VxColors.neutral400;
    if (widget.strategy.tier == MarketplaceTier.premium) {
      tierColor = VxColors.accent;
    }
    if (widget.strategy.tier == MarketplaceTier.exclusive) {
      tierColor = Colors.purpleAccent;
    }

    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: Text(widget.strategy.title),
        backgroundColor: VxColors.surface,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Stats
            Container(
              padding: const EdgeInsets.all(24),
              color: VxColors.surface,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: VxColors.neutral700,
                        child: Text(widget.strategy.title[0],
                            style: const TextStyle(
                                fontSize: 24, color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.strategy.title,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: VxColors.neutral100)),
                            Text("by ${widget.strategy.authorName}",
                                style: const TextStyle(
                                    color: VxColors.neutral400)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: tierColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: tierColor.withValues(alpha: 0.5))),
                              child: Text(
                                  widget.strategy.tier.name.toUpperCase(),
                                  style: TextStyle(
                                      color: tierColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // The "+" and the green were hardcoded, so a listing
                      // reporting -12% rendered as "+-12%" in profit green.
                      _buildStat(
                          "Return",
                          "${widget.strategy.totalReturn >= 0 ? '+' : ''}"
                              "${widget.strategy.totalReturn}%",
                          widget.strategy.totalReturn >= 0
                              ? VxColors.positive
                              : VxColors.negative),
                      _buildStat(
                          "Win Rate",
                          "${(widget.strategy.winRate * 100).toStringAsFixed(0)}%",
                          VxColors.neutral100),
                      _buildStat("Drawdown", "${widget.strategy.maxDrawdown}%",
                          VxColors.negative),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Strategy Logic",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: VxColors.neutral100)),
                  const SizedBox(height: 8),
                  Text(widget.strategy.description,
                      style: const TextStyle(
                          color: VxColors.neutral300, height: 1.5)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // This was a 200px empty box captioned "Equity Curve (Simulated)"
            // — a chart frame with no chart in it, which implies a verified
            // track record the app has never seen. The stats above come from
            // whoever published the listing and nothing here checks them, so
            // say that instead of drawing furniture around it.
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VxColors.neutral800,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VxColors.neutral700),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: VxColors.neutral500),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "The figures above are reported by the publisher and "
                      "have not been independently verified.\n\n"
                      "Publishing records a strategy's description and "
                      "settings, not its code, so this listing cannot be run "
                      "or backtested directly. Read the logic below and "
                      "rebuild it in the Strategy Builder to test it "
                      "yourself.",
                      style: TextStyle(
                          color: VxColors.neutral400, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Subscribe Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isSubscribed || _isSubscribing ? null : _handleSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isSubscribed ? VxColors.neutral700 : VxColors.accent,
                    foregroundColor: _isSubscribed
                        ? VxColors.neutral400
                        : VxColors.neutral900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubscribing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      // Was "Subscribe (\$X/mo)" / "Active Subscription" for
                      // an action that appends to a local list and charges
                      // nothing — the app has no payment provider at all.
                      : Text(
                          _isSubscribed ? "Added" : "Add to My Strategies",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: VxColors.neutral500)),
      ],
    );
  }
}
