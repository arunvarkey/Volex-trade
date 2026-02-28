import 'dart:async';
import 'package:volex_terminal/data/market_data_repository.dart';
import '../../ui/design_system/charts/chart_models.dart';

/// Single source of truth for chart data ingestion.
/// Normalizes MarketDataRepository streams into UI-ready points.
class ChartDataPipeline {
  final MarketDataRepository _repository;
  final StreamController<List<PricePoint>> _outputController =
      StreamController.broadcast();

  List<PricePoint> _buffer = [];

  ChartDataPipeline(this._repository);

  Stream<List<PricePoint>> get outputStream => _outputController.stream;

  Future<void> initialize() async {
    // 1. Fetch History
    final candles = await _repository.fetchHistory();
    _buffer = candles
        .map((c) => PricePoint(timestamp: c.date, price: c.close))
        .toList();
    _emit();

    // 2. Listen to Live Updates
    _repository.updatesStream.listen((candle) {
      _buffer.add(PricePoint(timestamp: candle.date, price: candle.close));
      // Keep buffer size manageable (e.g., 1000 candles)
      if (_buffer.length > 2000) {
        _buffer.removeRange(0, _buffer.length - 1000);
      }
      _emit();
    });
  }

  void _emit() {
    _outputController.add(List.from(_buffer));
  }

  void dispose() {
    _outputController.close();
  }
}
