import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/ui/sheets/smart_order_sheet.dart';

import '../test_helper.dart';

/// The trade ticket, driven the way a user drives it.
///
/// The engine tests prove that a quantity handed to ExecutionManager is
/// accounted for correctly. They say nothing about whether the *ticket* hands
/// it the right quantity — and that is the number deciding how much a losing
/// trade costs. A ticket that sizes 10x too large would sail through every
/// engine test in the repo while emptying the account on one stop-out.
///
/// Risk-based sizing is the app's central teaching claim: you say what you are
/// willing to lose, and the app works out the size. These tests hold it to
/// that claim arithmetically.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const entry = 50000.0;
  const startingBalance = 100000.0;

  late ExecutionManager manager;

  setUp(() async {
    // GuidanceBanner reads its dismissal flag from here.
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
    manager = ExecutionManager();
  });

  Future<void> pumpTicket(WidgetTester tester, {bool isBuy = true}) async {
    // The ticket is a tall sheet. At the default 800x600 test surface its
    // column overflows, and a RenderFlex overflow is an exception, which
    // fails the test for a reason that has nothing to do with sizing.
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider<ExecutionManager>.value(
        value: manager,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SmartOrderSheet(
                symbol: 'BTCUSDT',
                currentPrice: entry,
                isBuy: isBuy,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  double amountIn(WidgetTester tester) {
    final field =
        tester.widget<TextField>(find.byKey(const Key('ticket_amount')));
    return double.parse(field.controller!.text);
  }

  group('risk-based sizing', () {
    testWidgets('1% risk sizes the trade to lose exactly 1% at the stop',
        (tester) async {
      await pumpTicket(tester);

      await tester.tap(find.text('Risk 1%'));
      await tester.pump();

      // The ticket defaults to a 2% stop, so the stop sits 1,000 below a
      // 50,000 entry. Risking 1% of 100,000 is 1,000, so the size that loses
      // exactly that much is 1.0.
      final qty = amountIn(tester);
      const stopDistance = entry * 0.02;
      final lossAtStop = qty * stopDistance;

      expect(lossAtStop, closeTo(startingBalance * 0.01, 0.01),
          reason: 'the whole point of sizing from risk is that the loss at '
              'the stop equals the risk you asked for');
      expect(qty, closeTo(1.0, 0.0001));
    });

    testWidgets('2% risk sizes to exactly twice the 1% size', (tester) async {
      await pumpTicket(tester);

      await tester.tap(find.text('Risk 1%'));
      await tester.pump();
      final one = amountIn(tester);

      await tester.tap(find.text('2%'));
      await tester.pump();
      final two = amountIn(tester);

      expect(two, closeTo(one * 2, 0.0001),
          reason: 'risk scales linearly with size at a fixed stop distance');
    });

    testWidgets('sizing works the same for a short', (tester) async {
      await pumpTicket(tester, isBuy: false);

      await tester.tap(find.text('Risk 1%'));
      await tester.pump();

      // The stop is above entry on a short, but it is the same distance away,
      // so the size that risks 1% is identical.
      final qty = amountIn(tester);
      const stopDistance = entry * 0.02;

      expect(qty * stopDistance, closeTo(startingBalance * 0.01, 0.01),
          reason: 'a short sized from risk must risk the same as a long; '
              'getting the sign wrong here doubles or zeroes the size');
    });

    testWidgets('a wider stop produces a smaller position', (tester) async {
      await pumpTicket(tester);

      await tester.tap(find.text('Risk 1%'));
      await tester.pump();
      final atTwoPercent = amountIn(tester);

      // Widen the stop to 4%: the same cash risk over twice the distance is
      // half the size. This is the relationship beginners get backwards --
      // a wider stop feels safer, so they leave the size alone and double
      // what they stand to lose.
      await tester.enterText(find.byType(TextField).at(1), '4');
      await tester.pump();
      await tester.tap(find.text('Risk 1%'));
      await tester.pump();
      final atFourPercent = amountIn(tester);

      expect(atFourPercent, lessThan(atTwoPercent));
      expect(atFourPercent, closeTo(atTwoPercent / 2, 0.001));
    });
  });

  group('the risk read-out', () {
    testWidgets('shows the cash at risk and the reward', (tester) async {
      await pumpTicket(tester);

      await tester.tap(find.text('Risk 1%'));
      await tester.pump();

      // 1% of 100,000, and a 4% target against a 2% stop is twice that.
      expect(find.text('Risk \$1000.00'), findsOneWidget);
      expect(find.text('Reward \$2000.00'), findsOneWidget);
    });

    testWidgets('shows 1:2 for the default 2% stop and 4% target',
        (tester) async {
      await pumpTicket(tester);
      await tester.tap(find.text('Risk 1%'));
      await tester.pump();

      expect(find.text('R:R 1:2.00'), findsOneWidget,
          reason: 'a 4% target against a 2% stop is two to one whichever '
              'side the trade is on');
    });

    testWidgets('is 1:2 on a short as well', (tester) async {
      await pumpTicket(tester, isBuy: false);
      await tester.tap(find.text('Risk 1%'));
      await tester.pump();

      expect(find.text('R:R 1:2.00'), findsOneWidget);
    });
  });

  testWidgets('sizing is unavailable until a stop is set', (tester) async {
    await pumpTicket(tester);

    // Turning protective exits off removes the stop, and without one there is
    // no distance to size against. The ticket has to say so rather than
    // silently sizing from nothing.
    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    expect(find.text('Set a stop loss to size by risk'), findsOneWidget);
  });
}
