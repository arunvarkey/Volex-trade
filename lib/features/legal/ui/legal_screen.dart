import 'package:flutter/material.dart';

import '../../../ui/design_system/vx_colors.dart';
import '../../../ui/design_system/vx_typography.dart';

enum LegalDoc { privacy, terms }

/// In-app privacy disclosure and terms.
///
/// These used to be links to volexterminal.com/privacy and /terms — a domain
/// that isn't published, so both simply failed to open. The content below is a
/// factual description of what this build actually does with data, written
/// from an audit of the code rather than boilerplate.
class LegalScreen extends StatelessWidget {
  final LegalDoc doc;

  const LegalScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = doc == LegalDoc.privacy;
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: Text(isPrivacy ? 'Privacy' : 'Terms of Use'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: isPrivacy ? _privacy() : _terms(),
      ),
    );
  }

  List<Widget> _privacy() => [
        _p('Volex is a trading simulator. It uses virtual money and does not '
            'place real trades.'),
        _h('What stays on your device'),
        _p('Almost everything. Your display name and avatar, paper-trading '
            'balance and positions, saved strategies, chart drawings, Academy '
            'progress, journal entries and app settings are stored locally on '
            'your phone. Uninstalling the app removes them.'),
        _h('What leaves your device'),
        _b([
          'Market data requests to Binance\'s public price API. These ask for '
              'public prices only — no account or personal information is '
              'attached.',
          'If you sign in, your account email and synced data go to Google '
              'Firebase. Sign-in is optional: without it the app runs as a '
              'guest and nothing is uploaded.',
          'If you choose to connect exchange API keys, they are held in the '
              'device\'s encrypted secure storage. They are not sent to us.',
        ]),
        _h('Analytics and crash reports'),
        _p('Anonymous usage events and crash reports are sent through Firebase '
            'Analytics and Crashlytics, and only when the app is built with a '
            'Firebase configuration. A build without one sends neither.'),
        _h('What we never do'),
        _b([
          'We do not sell your data.',
          'We do not collect your contacts, photos beyond an avatar you pick, '
              'location, or device identifiers for advertising.',
          'We do not take custody of any money — there is none to take.',
        ]),
        _note('This page describes how this build behaves. Before publishing '
            'to an app store you should have it reviewed and hosted at a '
            'public URL, as store policies require.'),
      ];

  List<Widget> _terms() => [
        _h('What this app is'),
        _p('Volex is an educational trading simulator. All trading is paper '
            'trading with virtual funds. Nothing here executes a real order or '
            'holds real money.'),
        _h('Not financial advice'),
        _p('Signals, AI suggestions, strategy templates, backtest results and '
            'Academy lessons are educational material, not investment advice '
            'and not a recommendation to buy or sell anything. Decisions you '
            'make with real money elsewhere are your own.'),
        _h('Simulated results are not real results'),
        _p('Backtests replay historical data with modelled fees and slippage. '
            'They cannot capture every real-world cost or how a live market '
            'would react to your orders. Past performance — real or simulated '
            '— does not predict future results.'),
        _h('Market data'),
        _p('Prices come from public exchange endpoints and may be delayed or '
            'unavailable. When the feed cannot be reached the app generates '
            'stand-in candles so the simulator keeps working; these are '
            'labelled "simulated data" on the chart and are not real prices.'),
        _h('Your responsibilities'),
        _b([
          'Keep your device and any API keys you add secure.',
          'Use the app for learning and practice.',
          'The app is provided as-is, without warranty.',
        ]),
        _note('This page describes how this build behaves. Before publishing '
            'to an app store you should have it reviewed by someone qualified.'),
      ];

  Widget _h(String text) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Text(text, style: VxTypography.h3),
      );

  Widget _p(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: VxTypography.body.copyWith(
              color: VxColors.textSecondary, height: 1.55),
        ),
      );

  Widget _b(List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 10),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: VxColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      i,
                      style: VxTypography.body.copyWith(
                          color: VxColors.textSecondary, height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VxColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VxColors.border),
          ),
          child: Text(
            text,
            style: VxTypography.caption.copyWith(
                color: VxColors.textTertiary, height: 1.5),
          ),
        ),
      );
}
