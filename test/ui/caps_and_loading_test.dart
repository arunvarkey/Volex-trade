import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Holds the two decisions in `vx_eyebrow.dart` and `vx_loading.dart`.
///
/// Both are the kind of rule that is easy to agree with and impossible to
/// keep by discipline, because the wrong version is shorter to type and looks
/// right in isolation. `'RUN BACKTEST'` is one string; a centred spinner is
/// one line. Each one is only obviously wrong next to the other forty.
///
/// So the rules are checked here instead of remembered:
///
/// 1. Capitals are set by `VxEyebrow`, never by a screaming literal or a
///    `.toUpperCase()` in a copy position.
/// 2. `CircularProgressIndicator` is constructed in exactly one place.
///
/// Each test prints the offending lines, and each exemption below says why it
/// is exempt — an exemption with no reason is the first step back.
void main() {
  /// Everything the user can actually reach. Excluded on purpose:
  ///
  /// * `lib/ui/*_panel.dart`, `lib/ui/terminal/`, `ticker_strip.dart`,
  ///   `hud_overlay.dart`, `vx_action_center.dart` and the rest of the
  ///   never-constructed widgets — they render nowhere, so restyling them
  ///   would be work with no user on the other end. They should be deleted;
  ///   until they are, they are not held to a rule about how the app looks.
  /// * services, models and repositories, where a capitalised string is a
  ///   ticker, an endpoint or a log level.
  List<File> liveUiFiles() {
    final live = <File>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path;

      final isUi = path.startsWith('lib/ui/screens/') ||
          path.startsWith('lib/ui/widgets/') ||
          path.startsWith('lib/ui/sheets/') ||
          path.startsWith('lib/ui/design_system/') ||
          path.startsWith('lib/ui/navigation/') ||
          path.startsWith('lib/ui/chart_engine/') ||
          (path.startsWith('lib/features/') && path.contains('/ui/')) ||
          (path.startsWith('lib/features/') && path.contains('/screens/')) ||
          path == 'lib/features/compliance/age_gate_screen.dart';
      if (!isUi) continue;

      // Unreachable widgets — see above.
      if (path == 'lib/ui/design_system/vx_action_center.dart') continue;
      if (path == 'lib/ui/screens/error/init_error_screen.dart') continue;
      if (path == 'lib/ui/widgets/trade_confirmation.dart') continue;
      if (path == 'lib/ui/widgets/mode_indicator.dart') continue;
      if (path == 'lib/ui/screens/strategies/strategy_detail_placeholder.dart') {
        continue;
      }
      if (path == 'lib/ui/screens/strategies/strategy_list_view.dart') continue;

      live.add(entity);
    }
    return live;
  }

  /// Not copy: tickers, indicator names, file formats, initialisms.
  final acronym = RegExp(
    r'^(?:[A-Z]{2,6}(?:USDT|USD|BTC|ETH|PERP)?|P&L|RSI|MACD|EMA|SMA|'
    r'ATR|ADX|VWAP|OBV|CCI|ROC|MFI|SAR|STOCH|XP|API|PIN|URL|UTC|OK|AM|PM|'
    r'OHLC|OHLCV|KYC|AML|GDPR|CSV|PDF|APK|SDK|YES|NO|BUY|SELL)$',
  );

  /// A quoted pair like 'BTC / USDT' or 'BTC/USDT' — a market, not copy.
  final tickerPair = RegExp(r'^[A-Z]{2,6} ?/ ?[A-Z]{2,6}$');

  test('capitalised copy goes through VxEyebrow, not a shouted literal', () {
    final shouted = RegExp(r"'([A-Z][A-Z0-9&\.\?!/ ]{2,})'");

    final offenders = <String>[];
    for (final file in liveUiFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trimLeft();
        if (trimmed.startsWith('//')) continue;

        for (final match in shouted.allMatches(lines[i])) {
          final value = match.group(1)!.trim();
          if (value.isEmpty) continue;
          if (acronym.hasMatch(value)) continue;
          if (tickerPair.hasMatch(value)) continue;
          // Every word an acronym: "BTC USDT", not copy.
          final words = value.split(' ').where((w) => w.isNotEmpty);
          if (words.every(acronym.hasMatch)) continue;
          offenders.add('${file.path}:${i + 1}  $trimmed');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'capitals are a label treatment, set by VxEyebrow from '
            'sentence-case text — not baked into the string:\n'
            '${offenders.join('\n')}');
  });

  test('.toUpperCase() is not used to style user-facing copy', () {
    /// Legitimate uppercasing: normalising a symbol for a lookup, building
    /// initials for an avatar, a timeframe like 1h → 1H.
    const allowed = <String>[
      'lib/ui/design_system/vx_eyebrow.dart', // where capitals are applied
      'lib/ui/design_system/vx_coin_icon.dart', // asset-key lookup
      'lib/ui/screens/profile/profile_screen.dart', // avatar initials
      'lib/ui/screens/chart/components/timeframe_selector.dart', // 1h → 1H
      'lib/features/journal/ui/journal_screen.dart', // symbol input
      // "3 × YES @ 62¢" — YES/NO is how a prediction contract is named.
      'lib/features/predictions/ui/event_market_detail_screen.dart',
    ];

    final offenders = <String>[];
    for (final file in liveUiFiles()) {
      if (allowed.contains(file.path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('toUpperCase()')) continue;
        final trimmed = lines[i].trimLeft();
        if (trimmed.startsWith('//')) continue;
        offenders.add('${file.path}:${i + 1}  $trimmed');
      }
    }

    expect(offenders, isEmpty,
        reason: 'pass sentence case to VxEyebrow instead — it uppercases for '
            'display and still reads the words to a screen reader:\n'
            '${offenders.join('\n')}');
  });

  test('CircularProgressIndicator is constructed in one place only', () {
    /// * `vx_loading.dart` is that place.
    /// * `vx_metric_gauge.dart` passes a `value`, so its ring is a chart of a
    ///   real number, not a loading state.
    /// * `splash_screen.dart` is the launch screen: there is no content whose
    ///   shape could be drawn, and nothing has been pressed.
    /// * the four `*_panel.dart` files are unreachable (see above).
    const allowed = <String>[
      'lib/ui/design_system/vx_loading.dart',
      'lib/ui/design_system/vx_metric_gauge.dart',
      'lib/ui/screens/splash/splash_screen.dart',
      'lib/ui/auto_tuning_panel.dart',
      'lib/ui/optimizer_panel.dart',
      'lib/ui/backtest_panel.dart',
      'lib/ui/genetic_optimization_panel.dart',
    ];

    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (allowed.contains(entity.path)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('CircularProgressIndicator(')) continue;
        final trimmed = lines[i].trimLeft();
        if (trimmed.startsWith('//')) continue;
        offenders.add('${entity.path}:${i + 1}  $trimmed');
      }
    }

    expect(offenders, isEmpty,
        reason: 'a spinner tells the user nothing about what is coming. '
            'Where the shape is known use VxListSkeleton, '
            'VxCardListSkeleton or VxChartSkeleton; inside a control the '
            'user just pressed use VxInlineSpinner:\n'
            '${offenders.join('\n')}');
  });

  test('the ARB holds sentence case, not capitals', () {
    // Capitals in the ARB would survive every rule above, and a translator
    // cannot un-shout a string whose language has no such convention.
    final arb = File('lib/l10n/app_en.arb').readAsStringSync();
    final values = RegExp(r'"(?!@)[a-zA-Z]+":\s*"([^"]+)"').allMatches(arb);

    final shouted = <String>[];
    for (final match in values) {
      final value = match.group(1)!;
      final words = value.split(' ').where((w) => w.length > 2);
      if (words.isEmpty) continue;
      if (words.every((w) => w == w.toUpperCase() && w != w.toLowerCase())) {
        shouted.add(value);
      }
    }

    expect(shouted, isEmpty,
        reason: 'these ARB values are in capitals; write them in sentence '
            'case and let VxEyebrow decide how they are set:\n'
            '${shouted.join('\n')}');
  });
}
