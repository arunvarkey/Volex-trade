import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/features/journal/models/journal_entry.dart';
import 'package:volex_terminal/features/journal/services/journal_service.dart';

JournalEntry _entry({
  required String id,
  String note = 'Took the breakout',
  JournalMood mood = JournalMood.neutral,
  String? symbol,
  DateTime? at,
}) =>
    JournalEntry(
      id: id,
      note: note,
      mood: mood,
      symbol: symbol,
      createdAt: at ?? DateTime(2024, 1, 1),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty', () async {
    final s = JournalService.forTesting();
    await s.ensureLoaded();
    expect(s.entries, isEmpty);
    expect(s.riskyMoodCount, 0);
  });

  test('entries come back newest first', () async {
    final s = JournalService.forTesting();
    await s.ensureLoaded();
    await s.add(_entry(id: 'old', at: DateTime(2024, 1, 1)));
    await s.add(_entry(id: 'new', at: DateTime(2024, 6, 1)));
    await s.add(_entry(id: 'mid', at: DateTime(2024, 3, 1)));

    expect(s.entries.map((e) => e.id).toList(), ['new', 'mid', 'old']);
  });

  test('remove deletes only that entry', () async {
    final s = JournalService.forTesting();
    await s.ensureLoaded();
    await s.add(_entry(id: 'a'));
    await s.add(_entry(id: 'b'));

    await s.remove('a');

    expect(s.entries.map((e) => e.id), ['b']);
  });

  test('forSymbol filters by market', () async {
    final s = JournalService.forTesting();
    await s.ensureLoaded();
    await s.add(_entry(id: '1', symbol: 'BTCUSDT'));
    await s.add(_entry(id: '2', symbol: 'ETHUSDT'));
    await s.add(_entry(id: '3')); // free-form reflection, no market

    expect(s.forSymbol('BTCUSDT').map((e) => e.id), ['1']);
    expect(s.forSymbol('SOLUSDT'), isEmpty);
  });

  test('riskyMoodCount counts only the danger states', () async {
    final s = JournalService.forTesting();
    await s.ensureLoaded();
    await s.add(_entry(id: '1', mood: JournalMood.calm));
    await s.add(_entry(id: '2', mood: JournalMood.revenge));
    await s.add(_entry(id: '3', mood: JournalMood.greedy));
    await s.add(_entry(id: '4', mood: JournalMood.confident));

    expect(s.riskyMoodCount, 2);
    expect(JournalMood.anxious.isRisky, isTrue);
    expect(JournalMood.neutral.isRisky, isFalse);
  });

  test('entries survive a JSON round-trip', () {
    final original = _entry(
      id: 'x',
      note: 'Revenge traded after a loss — broke my own rule',
      mood: JournalMood.revenge,
      symbol: 'BTCUSDT',
      at: DateTime(2024, 5, 4, 13, 30),
    );

    final restored = JournalEntry.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.note, original.note);
    expect(restored.mood, JournalMood.revenge);
    expect(restored.symbol, 'BTCUSDT');
    expect(restored.createdAt, original.createdAt);
  });

  test('unknown mood in stored JSON falls back to neutral', () {
    final restored = JournalEntry.fromJson({
      'id': 'y',
      'note': 'legacy entry',
      'mood': 'euphoric', // not a value we ship
      'createdAt': DateTime(2024, 1, 1).toIso8601String(),
    });

    expect(restored.mood, JournalMood.neutral);
  });

  test('persists to SharedPreferences', () async {
    final s = JournalService.forTesting();
    await s.ensureLoaded();
    await s.add(_entry(id: 'persisted', note: 'kept'));

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('trade_journal_v1');
    expect(raw, isNotNull);
    expect(raw, contains('persisted'));
  });
}
