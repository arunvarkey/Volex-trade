// lib/core/config/legal_config.dart

/// Legal copy shown by [RiskDisclosureScreen].
///
/// This used to also carry `termsOfServiceUrl` / `privacyPolicyUrl` /
/// `riskDisclosureUrl` pointing at `yourusername.github.io/...` — placeholder
/// addresses that were never published, so every link built from them was
/// dead. The real documents now live in-app (`LegalScreen`), so the constants
/// are gone rather than left around waiting to be linked by mistake.
class LegalConfig {
  static const String riskDisclosure = '''
RISK DISCLOSURE:

Volex Terminal is a trading simulator. Every trade you place here uses virtual
money — you cannot lose real funds inside this app, and nothing here places a
real order.

The disclosure below is about real trading, which is what this app is teaching
you to practise for.

Trading cryptocurrencies involves a high degree of risk and is not suitable for
all investors. Leverage can work against you as easily as for you. Before
trading, consider your objectives, your level of experience, and your appetite
for risk.

You could lose some or all of the money you put in, so never trade money you
cannot afford to lose. Seek advice from an independent, qualified financial
adviser if you are in any doubt.

Volex Terminal is educational software. Nothing in it — signals,
suggestions, strategy templates, backtests or lessons — is investment advice or
a recommendation to buy or sell anything. Simulated results have inherent
limitations: they cannot reproduce real fees, real liquidity, or how a live
market would react to your orders, and they do not represent actual trading.
''';
}
