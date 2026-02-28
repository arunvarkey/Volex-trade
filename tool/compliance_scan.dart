import 'dart:io';

// ignore_for_file: avoid_print

void main() async {
  print("Starting Compliance Scan...");
  final riskyKeywords = [
    'guarantee',
    'profit',
    'return on investment',
    'roi',
    'hack',
    'admin',
    'binance', // Context dependent
    'coinbase',
    'ftx',
    'secret',
    'password',
    'key',
    'token',
  ];

  final rootDir = Directory.current;
  int issueCount = 0;

  await for (final entity
      in rootDir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      if (entity.path.contains('.git') ||
          entity.path.contains('.dart_tool') ||
          entity.path.contains('build') ||
          entity.path.contains(
              'test') || // Tests are usually exempt, but good to check
          entity.path.contains('windows') ||
          entity.path.contains('linux') ||
          entity.path.contains('macos') ||
          entity.path.contains('android') ||
          entity.path.contains('ios') ||
          entity.path.contains('web') ||
          entity.path.endsWith('.png') ||
          entity.path.endsWith('.jpg')) {
        continue;
      }

      try {
        final content = await entity.readAsString();
        final lowerContent = content.toLowerCase();

        for (final keyword in riskyKeywords) {
          if (lowerContent.contains(keyword)) {
            // Filter out some false positives
            if (keyword == 'key' &&
                (entity.path.endsWith('.yaml') ||
                    entity.path.contains('widget'))) continue;
            if (keyword == 'token' && entity.path.contains('auth')) {
              continue; // Auth tokens are fine logic
            }
            if (keyword == 'binance' && entity.path.contains('exchange')) {
              continue; // Connectors are fine
            }

            print("WARNING: Found '$keyword' in ${entity.path}");

            // Find line number
            final lines = content.split('\n');
            for (int i = 0; i < lines.length; i++) {
              if (lines[i].toLowerCase().contains(keyword)) {
                print("  Line ${i + 1}: ${lines[i].trim()}");
              }
            }
            issueCount++;
          }
        }
      } catch (e) {
        // Binary file or read error
      }
    }
  }

  if (issueCount == 0) {
    print("SUCCESS: No compliance risks found.");
  } else {
    print("FINISHED: Found $issueCount potential issues.");
  }
}
