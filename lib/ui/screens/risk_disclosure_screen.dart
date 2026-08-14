// lib/ui/screens/risk_disclosure_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/legal_config.dart';
import '../design_system/vx_colors.dart';

class RiskDisclosureScreen extends StatefulWidget {
  const RiskDisclosureScreen({super.key});

  @override
  State<RiskDisclosureScreen> createState() => _RiskDisclosureScreenState();
}

class _RiskDisclosureScreenState extends State<RiskDisclosureScreen> {
  bool _acceptedRisks = false;
  bool _acceptedSimulation = false;
  bool _over18 = false;

  @override
  Widget build(BuildContext context) {
    final canProceed = _acceptedRisks && _acceptedSimulation && _over18;

    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Warning icon
              const Center(
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 80,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'IMPORTANT RISK DISCLOSURE',
                style: TextStyle(
                  color: VxColors.neonCyan,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Disclosure text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border.all(color: Colors.grey[800]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  LegalConfig.riskDisclosure,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Checkboxes
              _buildCheckbox(
                'I understand that trading cryptocurrencies carries substantial risk of loss',
                _acceptedRisks,
                (value) => setState(() => _acceptedRisks = value),
              ),

              const SizedBox(height: 16),

              _buildCheckbox(
                'I understand that paper trading results do not guarantee real trading success',
                _acceptedSimulation,
                (value) => setState(() => _acceptedSimulation = value),
              ),

              const SizedBox(height: 16),

              _buildCheckbox(
                'I confirm that I am 18 years or older',
                _over18,
                (value) => setState(() => _over18 = value),
              ),

              const SizedBox(height: 32),

              // Legal links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _openUrl(LegalConfig.termsOfServiceUrl),
                    child: const Text(
                      'Terms of Service',
                      style: TextStyle(color: VxColors.neonCyan, fontSize: 12),
                    ),
                  ),
                  Text(' • ', style: TextStyle(color: Colors.grey[600])),
                  TextButton(
                    onPressed: () => _openUrl(LegalConfig.privacyPolicyUrl),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(color: VxColors.neonCyan, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Accept button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canProceed ? _accept : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canProceed ? VxColors.neonGreen : Colors.grey[800],
                    foregroundColor:
                        canProceed ? VxColors.deepBlack : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'I ACCEPT THE RISKS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String text, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? VxColors.neonGreen.withValues(alpha: 0.1) : Colors.grey[900],
          border: Border.all(
            color: value ? VxColors.neonGreen : Colors.grey[800]!,
            width: value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? VxColors.neonGreen : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: value ? Colors.white : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accepted_risk_disclosure', true);

    if (mounted) {
      context.go('/');
    }
  }

  void _openUrl(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.deepBlack,
        title: const Text('Link', style: TextStyle(color: VxColors.neonCyan)),
        content: Text(url, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Close', style: TextStyle(color: VxColors.neonCyan)),
          ),
        ],
      ),
    );
  }
}
