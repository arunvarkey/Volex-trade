import 'package:flutter/material.dart';
import '../engine/strategy/strategy_metadata.dart';
import '../engine/strategy/strategy_engine.dart';
import 'strategy/strategy_edit_dialog.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_card.dart';
import 'design_system/vx_spacing.dart';
import 'design_system/vx_typography.dart';
import '../engine/subscription/entitlement_service.dart';
import '../engine/access_control_service.dart';
import 'package:provider/provider.dart';
import '../core/app_logger.dart';

class StrategyCard extends StatelessWidget {
  final StrategyMetadata metadata;
  final VoidCallback onTap;

  const StrategyCard({
    super.key,
    required this.metadata,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final entitlementService = EntitlementService();
    final accessService = AccessControlService();
    final hasAccess =
        entitlementService.hasAccess(accessService.currentUserId, metadata);

    final trustCategory = metadata.trustScore.category;
    Color trustColor = Colors.grey;
    if (trustCategory == "TRUSTED") trustColor = VxColors.neonGreen;
    if (trustCategory == "CAUTION") trustColor = VxColors.neonRed;
    if (trustCategory == "UNVERIFIED") trustColor = Colors.orange;

    return VxCard(
      animateOnHover: hasAccess,
      onTap: () {
        if (hasAccess) {
          onTap();
        } else {
          _showSubscribeDialog(context, entitlementService, accessService);
        }
      },
      backgroundColor: hasAccess ? null : Colors.black45,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: VxText.title(
              metadata.name,
              color: hasAccess ? Colors.white : Colors.white38,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: trustColor.withOpacity(0.1),
              border: Border.all(color: trustColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: VxText.monoBold(
              trustCategory,
              fontSize: 10,
              color: trustColor,
            ),
          ),
        ],
      ),
      description: "v${metadata.version} • by ${metadata.author}",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: VxSpacing.xs),
          // Price Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hasAccess
                  ? VxColors.neonCyan.withOpacity(0.1)
                  : VxColors.neonRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: VxText.monoBold(
              metadata.isPaid ? "\$${metadata.monthlyPrice}/mo" : "FREE",
              color: hasAccess ? VxColors.neonCyan : VxColors.neonRed,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: VxSpacing.md),
          // Description
          Text(
            metadata.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasAccess ? Colors.white70 : Colors.white24,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: VxSpacing.lg),
          if (!hasAccess)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: VxText.monoBold("🔒 LOCKED", color: VxColors.neonRed),
              ),
            ),
          if (hasAccess)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showConfigurationDialog(context, metadata),
                icon: const Icon(Icons.settings, size: 14),
                label: VxText.monoBold("CONFIGURE",
                    fontSize: 10, color: VxColors.neonCyan),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VxColors.neonCyan,
                  side: BorderSide(color: VxColors.neonCyan.withOpacity(0.5)),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
          const SizedBox(height: VxSpacing.md),
          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: metadata.tags.take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: VxText.caption(tag, fontSize: 9, color: Colors.white54),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showConfigurationDialog(
      BuildContext context, StrategyMetadata metadata) {
    // 1. Try to get the running instance from StrategyEngine
    try {
      final engine = Provider.of<StrategyEngine>(context, listen: false);
      final strategy = engine.getStrategy(metadata.id);

      if (strategy != null) {
        showDialog(
            context: context,
            builder: (_) => StrategyEditDialog(
                strategy: strategy,
                onSave: (newValues) {
                  engine.updateStrategyParams(strategy.id, newValues);
                }));
      } else {
        // Not running. Maybe show message or "Start with Params" (out of scope for now?)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Strategy is not currently active in the Engine.")));
      }
    } catch (e) {
      AppLogger.error("Error opening config: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Unable to configure: Engine not found.")));
    }
  }

  void _showSubscribeDialog(BuildContext context, EntitlementService entService,
      AccessControlService acService) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: VxColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: VxColors.neonCyan)),
              title: VxText.title("Subscribe to ${metadata.name}",
                  color: Colors.white),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VxText.body("Price: \$${metadata.monthlyPrice}/month",
                      color: Colors.white),
                  const SizedBox(height: 10),
                  VxText.body(
                      "By subscribing, you get full access to execute this strategy with your risk parameters.",
                      color: Colors.white70),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: VxText.monoBold("CANCEL", color: Colors.white38)),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: VxColors.neonCyan),
                    onPressed: () {
                      try {
                        entService.subscribe(acService.currentUserId, metadata);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Subscribed!")));
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    },
                    child:
                        VxText.monoBold("SUBSCRIBE NOW", color: Colors.black))
              ],
            ));
  }
}
