import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/journal_entry.dart';

/// Stores trading-journal entries in SharedPreferences.
///
/// Same self-contained singleton pattern as the other feature services: a
/// lazily-loaded in-memory list that persists on every change and notifies
/// listeners so the journal screen rebuilds.
class JournalService extends ChangeNotifier {
  JournalService._();
  static final JournalService instance = JournalService._();

  /// Visible for testing — an isolated instance so tests don't share state
  /// with the app singleton.
  @visibleForTesting
  factory JournalService.forTesting() = JournalService._;

  static const String _prefsKey = 'trade_journal_v1';

  final List<JournalEntry> _entries = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Newest first — the order a journal is actually read in.
  List<JournalEntry> get entries => List.unmodifiable(_entries);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _entries
          ..clear()
          ..addAll(decoded
              .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)));
        _sort();
      }
    } catch (_) {
      // Corrupt or unavailable storage → start clean rather than crash.
      _entries.clear();
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> add(JournalEntry entry) async {
    _entries.add(entry);
    _sort();
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  /// Entries for one market, newest first.
  List<JournalEntry> forSymbol(String symbol) => List.unmodifiable(
      _entries.where((e) => e.symbol == symbol).toList(growable: false));

  /// How many entries were logged in a risky emotional state. The point of
  /// journaling is to make this number visible.
  int get riskyMoodCount => _entries.where((e) => e.mood.isRisky).length;

  void _sort() => _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefsKey, jsonEncode(_entries.map((e) => e.toJson()).toList()));
    } catch (_) {
      // Persistence failure must never take the UI down; the in-memory list
      // stays correct for this session.
    }
  }

  /// Visible for testing — clears memory and storage.
  @visibleForTesting
  Future<void> clearAll() async {
    _entries.clear();
    _loaded = false;
    notifyListeners();
    await _persist();
  }
}
