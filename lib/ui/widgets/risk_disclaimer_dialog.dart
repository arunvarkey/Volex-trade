import 'package:flutter/material.dart';
import '../design_system/vx_colors.dart';
import '../../engine/persistence/persistence_service.dart';
import '../../core/service_locator.dart';

/// Mandatory Risk Disclaimer for professional trading terminals.
/// Ensures users are aware of the volatility and risks before using real capital.
class RiskDisclaimerDialog extends StatelessWidget {
  const RiskDisclaimerDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final persistence = getIt<PersistenceService>();
    final hasAccepted =
        persistence.getBool('risk_disclaimer_accepted') ?? false;

    if (!hasAccepted && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const RiskDisclaimerDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: VxColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: VxColors.warning, size: 28),
          SizedBox(width: 12),
          Text(
            "RISK DISCLOSURE",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Trading digital assets involves significant risk. Prices are extremely volatile and influenced by complex global factors.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              "By using Volex Terminal, you acknowledge:",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            SizedBox(height: 8),
            _BulletItem(
                text: "You are solely responsible for your trading decisions."),
            _BulletItem(
                text: "Past performance does not guarantee future results."),
            _BulletItem(
                text:
                    "AI-generated strategies are for educational purposes only."),
            _BulletItem(text: "Volex Terminal is not a financial advisor."),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final persistence = getIt<PersistenceService>();
            await persistence.setBool('risk_disclaimer_accepted', true);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text(
            "I UNDERSTAND THE RISKS",
            style: TextStyle(
              color: VxColors.neonCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: VxColors.neonCyan)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
