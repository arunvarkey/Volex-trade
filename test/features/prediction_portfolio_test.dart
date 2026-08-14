import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volex_terminal/features/predictions/data/prediction_data.dart';
import 'package:volex_terminal/features/predictions/models/prediction_models.dart';
import 'package:volex_terminal/features/predictions/services/prediction_portfolio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = PredictionPortfolioService.instance;
  final market = PredictionData.markets.first; // m_fed_cut, yes=58 no=42

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await service.ensureLoaded();
    await service.resetPortfolio();
  });

  test('seed data is coherent', () {
    expect(PredictionData.markets, isNotEmpty);
    for (final m in PredictionData.markets) {
      expect(m.yesPrice, inInclusiveRange(1, 99));
      expect(m.yesPrice + m.noPrice, 100);
    }
    // Every buzz item that links a market links a real one.
    for (final b in PredictionData.buzz) {
      if (b.marketId != null) {
        expect(PredictionData.marketById(b.marketId!), isNotNull);
      }
    }
  });

  test('fresh portfolio: \$10k balance, no positions', () {
    expect(service.balance, 10000.0);
    expect(service.hasPositions, isFalse);
    expect(service.netWorth, 10000.0);
    expect(service.totalPnl, 0.0);
  });

  test('buy YES: cost deducted, position priced correctly', () async {
    final result = await service.buy(market, ContractSide.yes, 10);
    expect(result.ok, isTrue);

    final cost = 10 * market.yesPrice / 100.0;
    expect(service.balance, closeTo(10000.0 - cost, 1e-9));

    final pos = service.positionFor(market.id, ContractSide.yes);
    expect(pos, isNotNull);
    expect(pos!.contracts, 10);
    expect(pos.avgPriceCents, market.yesPrice);
    // Value at unchanged market price equals cost → zero P/L.
    expect(pos.pnl(market), closeTo(0, 1e-9));
    expect(service.netWorth, closeTo(10000.0, 1e-9));
  });

  test('buying again blends into one position', () async {
    await service.buy(market, ContractSide.yes, 10);
    await service.buy(market, ContractSide.yes, 30);
    final pos = service.positionFor(market.id, ContractSide.yes)!;
    expect(pos.contracts, 40);
    expect(pos.avgPriceCents, market.yesPrice); // same price → same avg
  });

  test('YES and NO are separate positions', () async {
    await service.buy(market, ContractSide.yes, 5);
    await service.buy(market, ContractSide.no, 7);
    expect(service.positions.length, 2);
    expect(service.positionFor(market.id, ContractSide.no)!.avgPriceCents,
        market.noPrice);
  });

  test('close returns proceeds to balance and removes position', () async {
    await service.buy(market, ContractSide.yes, 10);
    final result = await service.close(market, ContractSide.yes);
    expect(result.ok, isTrue);
    expect(service.balance, closeTo(10000.0, 1e-9));
    expect(service.hasPositions, isFalse);
  });

  test('rejects zero contracts and over-balance orders', () async {
    expect((await service.buy(market, ContractSide.yes, 0)).ok, isFalse);
    // 1000 contracts ≤ allowed by clamp in UI, so exceed via cost:
    // balance 10000 → need cost > 10000: contracts > 10000/(price/100)
    final tooMany = (10000 / (market.yesPrice / 100)).ceil() + 1;
    expect((await service.buy(market, ContractSide.yes, tooMany)).ok, isFalse);
    expect(service.balance, 10000.0); // unchanged after rejections
  });

  test('positions survive JSON round-trip', () {
    const pos = PredictionPosition(
      marketId: 'm_btc_100k',
      side: ContractSide.no,
      contracts: 12,
      avgPriceCents: 59,
    );
    final restored = PredictionPosition.fromJson(pos.toJson());
    expect(restored, isNotNull);
    expect(restored!.marketId, pos.marketId);
    expect(restored.side, pos.side);
    expect(restored.contracts, pos.contracts);
    expect(restored.avgPriceCents, pos.avgPriceCents);
    expect(PredictionPosition.fromJson({'bad': 'data'}), isNull);
  });
}
