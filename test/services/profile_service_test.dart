import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/services/profile_service.dart';

/// Verifies the editable, persisted display name (the "create a profile" fix).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to Trader with no custom name', () {
    final s = ProfileService();
    expect(s.displayName, 'Trader');
    expect(s.hasCustomName, isFalse);
  });

  test('setDisplayName updates state and persists to storage', () async {
    final s = ProfileService();
    await s.setDisplayName('Alex');
    expect(s.displayName, 'Alex');
    expect(s.hasCustomName, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile_display_name'), 'Alex');
  });

  test('ignores empty / whitespace-only names', () async {
    final s = ProfileService();
    await s.setDisplayName('   ');
    expect(s.displayName, 'Trader');
    expect(s.hasCustomName, isFalse);
  });
}
