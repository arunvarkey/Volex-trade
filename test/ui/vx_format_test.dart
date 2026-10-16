import 'package:flutter_test/flutter_test.dart';

import 'package:volex_terminal/ui/design_system/vx_format.dart';
import 'package:volex_terminal/ui/widgets/market_ticker/ticker_format.dart';

/// How numbers are written.
///
/// Worth pinning because formatting drifts silently: nobody notices that one
/// screen lost its thousands separators until a trader sees 1000000 next to
/// 100000 and cannot tell them apart at a glance.
void main() {
  group('price', () {
    test('uses more precision the smaller the number gets', () {
      // A terminal shows Bitcoin to two places and a sub-cent altcoin to
      // five. A single fixed precision makes one of them unreadable.
      expect(VxFormat.price(68895), '68,895.00');
      expect(VxFormat.price(3.14159), '3.142');
      expect(VxFormat.price(0.12345678), '0.12346');
    });

    test('groups thousands', () {
      expect(VxFormat.price(1234567.89), '1,234,567.89');
    });

    test('picks precision by magnitude, not by sign', () {
      expect(VxFormat.price(-68895), '-68,895.00');
      expect(VxFormat.price(-3.14159), '-3.142');
    });
  });

  group('money and P&L', () {
    test('groups thousands and carries the currency', () {
      expect(VxFormat.money(1240), '\$1,240.00');
      expect(VxFormat.money(-340.5), '-\$340.50');
    });

    test('P&L always shows an explicit sign', () {
      // Colour cannot carry this alone — roughly one man in twelve has a
      // red-green deficiency, and a column of results has to be scannable
      // without reading the digits.
      expect(VxFormat.signedMoney(1240), '+\$1,240.00');
      expect(VxFormat.signedMoney(-340), '-\$340.00');
      expect(VxFormat.signedMoney(0), '+\$0.00');
    });

    test('percentages too', () {
      expect(VxFormat.signedPercent(2.4567), '+2.46%');
      expect(VxFormat.signedPercent(-0.5), '-0.50%');
    });
  });

  group('compact', () {
    test('shortens by magnitude', () {
      expect(VxFormat.compactMoney(1.23e9), '\$1.2B');
      expect(VxFormat.compactMoney(845e6), '\$845M');
      // Deliberately not a .5 tie: Dart rounds half away from zero while
      // other languages use banker's rounding, and a test that depends on
      // which is a test about the runtime rather than about formatting.
      expect(VxFormat.compactMoney(12400), '\$12K');
      expect(VxFormat.compactMoney(12600), '\$13K');
    });

    test('keeps separators below the thousand threshold', () {
      expect(VxFormat.compactMoney(999), '\$999');
    });

    test('handles negatives', () {
      expect(VxFormat.compactMoney(-1.23e9), '-\$1.2B');
    });
  });

  test('counts are grouped', () {
    expect(VxFormat.count(1284), '1,284');
    expect(VxFormat.count(1000000), '1,000,000');
  });

  group('duration', () {
    test('reads the way a person would say it', () {
      expect(VxFormat.duration(const Duration(minutes: 45)), '45 min');
      expect(VxFormat.duration(const Duration(minutes: 150)), '2.5 hours');
      expect(VxFormat.duration(const Duration(hours: 36)), '1.5 days');
    });
  });

  group('the ticker still formats identically', () {
    // ticker_format now delegates to VxFormat. These guard the delegation —
    // the ticker's output was correct and must not change.
    test('price', () {
      expect(formatPrice(68895), VxFormat.price(68895));
      expect(formatPrice(0.12345678), '0.12346');
    });

    test('volume', () {
      expect(formatQuoteVolume(1.23e9), '\$1.2B');
      expect(formatQuoteVolume(845e6), '\$845M');
    });

    test('baseAsset is unchanged', () {
      expect(baseAsset('BTCUSDT'), 'BTC');
      expect(baseAsset('BTC'), 'BTC');
    });
  });
}
