import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/engine/execution_manager.dart';

/// Verifies the strategy Start/Stop (play button) state tracking — previously
/// a no-op that never reflected running state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('start/stop toggles a strategy\'s running state', () async {
    final m = ExecutionManager();
    expect(m.isStrategyRunning('s1'), isFalse);
    expect(m.activeStrategyIds, isEmpty);

    await m.startStrategy('s1');
    expect(m.isStrategyRunning('s1'), isTrue);
    expect(m.activeStrategyIds, contains('s1'));

    await m.startStrategy('s2');
    expect(m.activeStrategyIds.length, 2);

    await m.stopStrategy('s1');
    expect(m.isStrategyRunning('s1'), isFalse);
    expect(m.isStrategyRunning('s2'), isTrue);

    m.stopAllStrategy();
    expect(m.activeStrategyIds, isEmpty);
  });

  test('reset clears active strategies', () async {
    final m = ExecutionManager();
    await m.startStrategy('x');
    m.reset();
    expect(m.activeStrategyIds, isEmpty);
  });
}
