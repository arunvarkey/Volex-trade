import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/engine/chart_enums.dart'; // ChartMode
import 'package:volex_terminal/ui/design_system/charts/vx_line_chart.dart';
import 'package:volex_terminal/ui/design_system/charts/vx_candle_chart.dart';
import 'package:volex_terminal/ui/design_system/charts/chart_models.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/data/market_data_repository.dart';
import 'package:volex_terminal/domain/candle_model.dart';

class FullScreenChartScreen extends StatefulWidget {
  const FullScreenChartScreen({super.key});

  @override
  State<FullScreenChartScreen> createState() => _FullScreenChartScreenState();
}

class _FullScreenChartScreenState extends State<FullScreenChartScreen> {
  // Local controller for this view?
  // Ideally share the main one, but simpler to just stream data here independently?
  // Let's reuse the MarketStream directly for simplicity and robustness.

  ChartMode _currentMode = ChartMode.area;
  List<Candle> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Fetch History
    final history = await MarketDataRepository().fetchHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: VxText.subtitle("BTC/USDT FULL VIEW"),
        actions: [
          // Toggle
          Row(
            children: [
              _buildToggleBtn(ChartMode.area, Icons.show_chart),
              const SizedBox(width: 8),
              _buildToggleBtn(ChartMode.candle, Icons.bar_chart),
              const SizedBox(width: 16),
            ],
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: VxColors.neonCyan))
          : StreamBuilder<Candle>(
              stream: MarketDataRepository().updatesStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _history.add(snapshot.data!);
                  // Keep buffer safe
                  if (_history.length > 2000) _history.removeAt(0);
                }

                // DATA PREP
                // Convert Candles -> PricePoint (if Area) or pass Candles (if Candle)
                // Since VxCandleChart accepts PricePoint currently (draft), let's hack it for now
                // OR FIX VxCandleChart to accept Candles.
                // Let's pass PricePoints for now to utilize existing widgets safely.

                final points = _history
                    .map((c) => PricePoint(timestamp: c.date, price: c.close))
                    .toList();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _currentMode == ChartMode.area
                      ? VxLineChart(
                          points: points, isProMode: true, showGrid: true)
                      : VxCandleChart(
                          candles: _history), // This is the bar-chart sim
                );
              }),
    );
  }

  Widget _buildToggleBtn(ChartMode mode, IconData icon) {
    final isSelected = _currentMode == mode;
    return IconButton(
      icon: Icon(icon, color: isSelected ? VxColors.neonCyan : Colors.white24),
      onPressed: () => setState(() => _currentMode = mode),
    );
  }
}
