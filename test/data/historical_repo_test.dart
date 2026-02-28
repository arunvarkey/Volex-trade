import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/data/historical_data_repository.dart';

void main() {
  late Directory tempDir;
  late HistoricalDataRepository repo;

  setUp(() async {
    repo = HistoricalDataRepository();
    tempDir = await Directory.systemTemp.createTemp('volex_hist_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('loadFromCsv parses standard OHLCV format correctly', () async {
    final file = File('${tempDir.path}/test_data.csv');

    // Create dummy CSV
    // Format: timestamp, open, high, low, close, volume
    final now = DateTime.now().millisecondsSinceEpoch;
    final prev = DateTime.now()
        .subtract(const Duration(minutes: 1))
        .millisecondsSinceEpoch;

    // Write Header + 2 lines (unordered to test sort)
    await file.writeAsString('''
timestamp,open,high,low,close,volume
$now,100,105,95,102,500
$prev,90,95,85,92,300
''');

    final candles = await repo.loadFromCsv(file.path);

    expect(candles.length, equals(2));

    // Check Sorting (Oldest first)
    expect(candles[0].close, equals(92.0)); // The 'prev' candle
    expect(candles[1].close, equals(102.0)); // The 'now' candle

    // Check Value Parsing
    expect(candles[0].high, equals(95.0));
    expect(candles[1].volume, equals(500.0));
  });

  test('loadFromCsv handles missing volume gracefully', () async {
    final file = File('${tempDir.path}/no_vol.csv');
    // Format: timestamp, open, high, low, close
    await file.writeAsString('''
1672531200000,10,20,5,15
''');

    final candles = await repo.loadFromCsv(file.path);
    expect(candles.length, equals(1));
    expect(candles.first.volume, equals(0.0));
  });

  test('generateMockHistory creates valid sequence', () async {
    final candles = await repo.generateMockHistory(days: 1);
    expect(candles.isNotEmpty, isTrue);
    expect(candles.length, equals(1440)); // 24 * 60
    expect(candles.first.date.isBefore(candles.last.date), isTrue);
  });
}
