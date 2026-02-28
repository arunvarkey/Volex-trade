import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/engine/sync/sync_engine.dart';

void main() {
  test('SyncEngine load test', () {
    // print("SyncEngine LOADED");
    expect(SyncEngine(), isNotNull);
  });
}
