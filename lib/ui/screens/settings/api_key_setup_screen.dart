import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/features/trading/services/secure_trading_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiKeySetupScreen extends StatefulWidget {
  const ApiKeySetupScreen({super.key});

  @override
  State<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends State<ApiKeySetupScreen> {
  final _apiKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureSecret = true;
  bool _loading = false;
  bool _hasExistingKeys = false;

  @override
  void initState() {
    super.initState();
    _checkExistingKeys();
  }

  Future<void> _checkExistingKeys() async {
    final hasKeys = await getIt<SecureTradingService>().hasApiKeys();
    setState(() => _hasExistingKeys = hasKeys);

    if (hasKeys) {
      final masked = await getIt<SecureTradingService>().getMaskedApiKey();
      _apiKeyController.text = masked ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Connect Exchange'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security warning
              _buildSecurityWarning(),

              const SizedBox(height: 32),

              // Instructions
              _buildInstructions(),

              const SizedBox(height: 32),

              // API Key input
              const Text(
                'API Key',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apiKeyController,
                enabled: !_hasExistingKeys,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: VxTypography.monoFamily,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your Binance API key',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: VxColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _hasExistingKeys
                      ? const Icon(Icons.check_circle, color: VxColors.positive)
                      : null,
                ),
                validator: (value) {
                  if (!_hasExistingKeys && (value == null || value.isEmpty)) {
                    return 'API key is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Secret Key input
              const Text(
                'Secret Key',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _secretKeyController,
                enabled: !_hasExistingKeys,
                obscureText: _obscureSecret,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: VxTypography.monoFamily,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your Binance secret key',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: VxColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureSecret ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white38,
                    ),
                    onPressed: () =>
                        setState(() => _obscureSecret = !_obscureSecret),
                  ),
                ),
                validator: (value) {
                  if (!_hasExistingKeys && (value == null || value.isEmpty)) {
                    return 'Secret key is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Critical security checklist
              _buildSecurityChecklist(),

              const SizedBox(height: 32),

              // Action buttons
              if (_hasExistingKeys)
                _buildExistingKeysActions()
              else
                _buildNewKeysActions(),

              const SizedBox(height: 24),

              // Help link
              Center(
                child: TextButton.icon(
                  onPressed: _openBinanceApiHelp,
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('How to create API keys?'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityWarning() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VxColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VxColors.danger.withValues(alpha: 0.3), width: 2),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: VxColors.danger, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Security First',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '• Your API keys NEVER leave your device\n'
            '• Keys are encrypted with AES-256\n'
            '• We NEVER see or store your keys\n'
            '• Withdrawal permission MUST be disabled',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Setup Instructions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildInstructionStep('1', 'Go to Binance → API Management'),
        _buildInstructionStep('2', 'Create new API key'),
        _buildInstructionStep('3', 'Enable "Spot & Margin Trading"'),
        _buildInstructionStep('4', 'DISABLE "Enable Withdrawals" ⚠️'),
        _buildInstructionStep('5', 'Copy keys and paste below'),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: VxColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: VxColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(
                  color: VxColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityChecklist() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ CRITICAL: Before connecting',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildChecklistItem(
            '❌ "Enable Withdrawals" is DISABLED',
            'This prevents anyone from stealing your funds',
          ),
          _buildChecklistItem(
            '✅ "Enable Spot Trading" is ENABLED',
            'This allows the app to place trades',
          ),
          _buildChecklistItem(
            '✅ API key has IP restrictions (optional)',
            'Additional security layer',
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: VxColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewKeysActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _connectExchange,
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.primary,
              foregroundColor: VxColors.deepBlack, // ✅ ADDED
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VxColors.deepBlack, // ✅ FIXED
                    ),
                  )
                : const Text(
                    'Connect Exchange',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingKeysActions() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VxColors.positive.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VxColors.positive.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: VxColors.positive),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Exchange Connected',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _disconnectExchange,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: VxColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Disconnect Exchange',
              style: TextStyle(
                color: VxColors.danger,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _connectExchange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await getIt<SecureTradingService>().storeApiKeys(
        apiKey: _apiKeyController.text.trim(),
        secretKey: _secretKeyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Exchange connected successfully!'),
            backgroundColor: VxColors.positive,
          ),
        );
        context.pop();
      }
    } on SecurityException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: VxColors.surface,
            title: const Row(
              children: [
                Icon(Icons.error, color: VxColors.danger),
                SizedBox(width: 12),
                Text('Security Error',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              e.message,
              style: const TextStyle(color: VxColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: _openBinanceApiManagement,
                child: const Text('Open Binance'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: VxColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _disconnectExchange() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.surface,
        title: const Text('Disconnect Exchange?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your API keys will be permanently deleted from this device. '
          'You can reconnect anytime.',
          style: TextStyle(color: VxColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: VxColors.danger),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await getIt<SecureTradingService>().removeApiKeys();
      setState(() {
        _hasExistingKeys = false;
        _apiKeyController.clear();
        _secretKeyController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exchange disconnected')),
        );
      }
    }
  }

  Future<void> _openBinanceApiHelp() async {
    final url = Uri.parse(
        'https://www.binance.com/en/support/faq/how-to-create-api-360002502072');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openBinanceApiManagement() async {
    final url =
        Uri.parse('https://www.binance.com/en/my/settings/api-management');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }
}
