import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:volex_terminal/core/service_locator.dart';
import 'package:volex_terminal/features/trading/services/secure_trading_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

/// Exchange connection — deliberately not available.
///
/// This screen used to collect a real Binance API key and secret, store them,
/// and report "Exchange connected successfully". Nothing in the app ever read
/// them back: `SecureTradingService.executeTrade` has no callers and
/// `isLiveMode` is never set true from any UI. Pro-mode onboarding sent every
/// new user straight here, so the first thing the app asked a new Pro user for
/// was live exchange credentials it had no use for.
///
/// That is worse than a confusing screen. Exchange keys carry real authority;
/// asking for them buys the user nothing here and leaves credentials on the
/// device for no reason, and telling someone they are connected to an exchange
/// when they are not is exactly the kind of claim a simulator must never make.
///
/// The screen now says what is true, and offers to delete any keys stored by
/// the previous version. When live trading is actually built, the form belongs
/// back here — behind a working execution path, not in front of one.
class ApiKeySetupScreen extends StatefulWidget {
  const ApiKeySetupScreen({super.key});

  @override
  State<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends State<ApiKeySetupScreen> {
  bool _checking = true;
  bool _hasStoredKeys = false;
  String? _maskedKey;

  @override
  void initState() {
    super.initState();
    _checkExistingKeys();
  }

  Future<void> _checkExistingKeys() async {
    try {
      final service = getIt<SecureTradingService>();
      final hasKeys = await service.hasApiKeys();
      final masked = hasKeys ? await service.getMaskedApiKey() : null;
      if (!mounted) return;
      setState(() {
        _hasStoredKeys = hasKeys;
        _maskedKey = masked;
        _checking = false;
      });
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _removeKeys() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VxColors.surface,
        title: Text('Delete stored keys?',
            style: VxTypography.h3.copyWith(fontWeight: FontWeight.w700)),
        content: Text(
          'This removes the exchange API key and secret from this device. '
          'Nothing in Volex uses them, so nothing will stop working.',
          style: VxTypography.bodySmall.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: VxColors.neonRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await getIt<SecureTradingService>().removeApiKeys();
      if (!mounted) return;
      setState(() {
        _hasStoredKeys = false;
        _maskedKey = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stored keys deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete keys: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Exchange Connection'),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: VxColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: VxColors.primary.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: VxColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Volex does not connect to an exchange',
                          style: VxTypography.body
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Every trade in this app is simulated against real market '
                    'prices using virtual money. There is no live trading, so '
                    'there is nothing for exchange API keys to do.',
                    style: VxTypography.bodySmall.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('WHY WE DO NOT ASK FOR YOUR KEYS',
                style: VxTypography.caption.copyWith(
                  color: VxColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.6,
                )),
            const SizedBox(height: 8),
            Text(
              'An exchange API key can move real money. Handing one to an app '
              'that cannot use it gains you nothing and leaves a live '
              'credential sitting on your phone. An earlier version of this '
              'screen collected them anyway and reported success. It should '
              'not have, and it no longer does.',
              style: VxTypography.bodySmall.copyWith(
                color: VxColors.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'If live trading is added later, this is where it will be set '
              'up — and it will say plainly what it is about to do before it '
              'asks for anything.',
              style: VxTypography.bodySmall.copyWith(
                color: VxColors.textSecondary,
                height: 1.55,
              ),
            ),
            if (_checking) ...[
              const SizedBox(height: 32),
              const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: VxColors.primary),
                ),
              ),
            ] else if (_hasStoredKeys) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: VxColors.neonRed.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: VxColors.neonRed.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keys are stored on this device',
                      style: VxTypography.body
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _maskedKey == null
                          ? 'An earlier version of Volex saved exchange keys '
                              'here. Nothing uses them. We recommend deleting '
                              'them, and revoking them at your exchange.'
                          : 'Saved key $_maskedKey. Nothing uses it. We '
                              'recommend deleting it here, and revoking it at '
                              'your exchange.',
                      style: VxTypography.bodySmall.copyWith(
                        color: VxColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _removeKeys,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: VxColors.neonRed),
                          foregroundColor: VxColors.neonRed,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Delete stored keys'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
