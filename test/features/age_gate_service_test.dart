import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/features/compliance/age_gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = AgeGateService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await service.ensureLoaded();
    await service.reset();
  });

  test('minimum age is 13', () {
    expect(AgeGateService.minimumAge, 13);
  });

  test('fresh state: not confirmed, not blocked', () {
    expect(service.isConfirmed, isFalse);
    expect(service.isBlocked, isFalse);
  });

  test('confirming meets-minimum unlocks and clears blocked', () async {
    await service.declineUnderAge();
    expect(service.isBlocked, isTrue);
    await service.confirmMeetsMinimum();
    expect(service.isConfirmed, isTrue);
    expect(service.isBlocked, isFalse);
  });

  test('declining sets blocked and not confirmed', () async {
    await service.declineUnderAge();
    expect(service.isConfirmed, isFalse);
    expect(service.isBlocked, isTrue);
  });

  test('confirmation persists across a reload', () async {
    await service.confirmMeetsMinimum();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('age_gate_confirmed_13plus_v1'), isTrue);
  });

  test('stores only a boolean, never a birthdate', () async {
    await service.confirmMeetsMinimum();
    final prefs = await SharedPreferences.getInstance();
    // Only the two derived flags should exist — no date/birth keys.
    final keys = prefs.getKeys();
    for (final k in keys) {
      expect(k.contains('birth') || k.contains('dob') || k.contains('date'),
          isFalse,
          reason: 'age gate must not persist a birthdate ($k)');
    }
  });
}
