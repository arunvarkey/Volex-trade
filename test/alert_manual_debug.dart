// ignore_for_file: avoid_print
import 'package:volex_terminal/domain/price_alert.dart';
import 'dart:io';

void main() {
  print('--- ALERT LOGIC DEBUG ---');
  try {
    // 1. Crosses Above
    final alert = PriceAlert(
      symbol: 'BTC',
      targetPrice: 50000,
      type: AlertType.crossesAbove,
    );

    if (alert.check(49000)) {
      print('FAILURE: Triggered early (Above)');
      exit(1);
    }
    if (!alert.check(50000)) {
      print('FAILURE: Did not trigger (Above)');
      exit(1);
    }
    if (alert.isActive) {
      print('FAILURE: Alert remained active');
      exit(1);
    }

    // 2. Crosses Below
    final alert2 = PriceAlert(
      symbol: 'ETH',
      targetPrice: 3000,
      type: AlertType.crossesBelow,
    );
    if (!alert2.check(2999)) {
      print('FAILURE: Did not trigger (Below)');
      exit(1);
    }

    print('SUCCESS: Alerts Logic Verified');
    exit(0);
  } catch (e) {
    print('EXCEPTION: $e');
    exit(1);
  }
}
