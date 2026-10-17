import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Stops localised screens quietly reverting to English.
///
/// The app ships English only, so nothing *looks* wrong when a string goes in
/// as a literal — which is exactly why extraction rots. The next person adding
/// a menu item writes `title: 'Alerts'` because that is what the line above
/// used to look like, and the half-extracted state is invisible until someone
/// tries to translate and finds the copy scattered back across the screens.
///
/// So the screens that have been done are listed here, and this reads their
/// source. A file in the list with a hardcoded user-facing string fails the
/// build, with the offending line printed.
///
/// Adding a screen to [_localisedScreens] is the final step of localising it.
void main() {
  /// Files that have been fully extracted and must stay that way.
  const localisedScreens = <String>[
    'lib/ui/screens/more_screen.dart',
    'lib/ui/screens/home/home_screen_v2.dart',
    'lib/features/academy/ui/academy_screen.dart',
    'lib/features/daily/ui/daily_screen.dart',
  ];

  /// Literals in these argument positions are user-facing copy.
  final suspicious = RegExp(
    r"""(?:^|\s)(?:title|subtitle|label|hintText|labelText|helperText)\s*:\s*(?:const\s+)?(?:Text\()?'([^']{3,})'""",
  );

  /// Not copy: route paths, asset keys, ticker symbols, format patterns and
  /// anything inside a comment.
  bool isCode(String value) {
    if (value.startsWith('/') || value.startsWith('assets/')) return true;
    if (RegExp(r'^[A-Z]{2,6}(USDT|USD|BTC|ETH)?$').hasMatch(value)) return true;
    if (RegExp(r'^[#,0.]+$').hasMatch(value)) return true;
    return false;
  }

  for (final path in localisedScreens) {
    test('$path has no hardcoded user-facing strings', () {
      final file = File(path);
      expect(file.existsSync(), isTrue,
          reason: '$path is in the localised list but does not exist — the '
              'list is now stale');

      final offenders = <String>[];
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//')) continue;

        for (final match in suspicious.allMatches(line)) {
          final value = match.group(1)!;
          if (isCode(value)) continue;
          offenders.add('  line ${i + 1}: $trimmed');
        }
      }

      expect(offenders, isEmpty,
          reason: 'these went in as English literals instead of ARB keys:\n'
              '${offenders.join('\n')}');
    });
  }

  test('the localised list is not empty', () {
    // Guards against someone "fixing" a failure by emptying the list.
    expect(localisedScreens, isNotEmpty);
  });
}
