import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/ui/chart_engine/chart_drawing.dart';
import 'package:volex_terminal/ui/chart_engine/drawing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final svc = DrawingService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await svc.resetForTest();
    await svc.ensureLoaded();
  });

  test('starts empty for any symbol', () {
    expect(svc.forSymbol('BTCUSDT'), isEmpty);
    expect(svc.countFor('BTCUSDT'), 0);
  });

  test('add and read back a horizontal level', () async {
    await svc.add('BTCUSDT', const ChartDrawing.horizontal(id: 'a', price: 100));
    expect(svc.countFor('BTCUSDT'), 1);
    expect(svc.forSymbol('BTCUSDT').first.price, 100);
  });

  test('drawings are isolated per symbol', () async {
    await svc.add('BTCUSDT', const ChartDrawing.horizontal(id: 'a', price: 100));
    await svc.add('ETHUSDT', const ChartDrawing.horizontal(id: 'b', price: 50));
    expect(svc.countFor('BTCUSDT'), 1);
    expect(svc.countFor('ETHUSDT'), 1);
    expect(svc.forSymbol('ETHUSDT').first.price, 50);
  });

  test('remove by id keeps the rest', () async {
    await svc.add('BTCUSDT', const ChartDrawing.horizontal(id: 'a', price: 100));
    await svc.add('BTCUSDT', const ChartDrawing.horizontal(id: 'b', price: 200));
    await svc.remove('BTCUSDT', 'a');
    final left = svc.forSymbol('BTCUSDT');
    expect(left.length, 1);
    expect(left.first.id, 'b');
  });

  test('clearSymbol empties only that symbol', () async {
    await svc.add('BTCUSDT', const ChartDrawing.horizontal(id: 'a', price: 100));
    await svc.add('ETHUSDT', const ChartDrawing.horizontal(id: 'b', price: 50));
    await svc.clearSymbol('BTCUSDT');
    expect(svc.countFor('BTCUSDT'), 0);
    expect(svc.countFor('ETHUSDT'), 1);
  });

  test('forSymbol returns an unmodifiable view', () {
    expect(
      () => svc
          .forSymbol('BTCUSDT')
          .add(const ChartDrawing.horizontal(id: 'x', price: 1)),
      throwsUnsupportedError,
    );
  });

  test('persists to SharedPreferences', () async {
    await svc.add('BTCUSDT', const ChartDrawing.horizontal(id: 'a', price: 123));
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('chart_drawings_v1');
    expect(raw, isNotNull);
    expect(raw!.contains('BTCUSDT'), isTrue);
    expect(raw.contains('123'), isTrue);
  });

  test('a trendline round-trips through JSON', () {
    const d = ChartDrawing.trendline(
        id: 't', aTimeMs: 1000, aPrice: 10, bTimeMs: 2000, bPrice: 20);
    final back = ChartDrawing.fromJson(d.toJson());
    expect(back.type, ChartDrawingType.trendline);
    expect(back.aTimeMs, 1000);
    expect(back.bPrice, 20);
  });
}
