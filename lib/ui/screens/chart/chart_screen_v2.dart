import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/engine/chart_controller.dart';
import 'package:volex_terminal/data/market_data_repository.dart';
import 'package:volex_terminal/domain/candle_model.dart';
import 'package:volex_terminal/domain/trade_signal.dart';
import 'package:volex_terminal/engine/execution_manager.dart';
import 'package:volex_terminal/domain/order.dart';
import 'package:volex_terminal/ui/chart_engine/vx_pro_chart.dart';
import 'package:volex_terminal/ui/chart_engine/chart_marker.dart';
import 'package:volex_terminal/ui/screens/chart/components/chart_top_bar.dart';
import 'package:volex_terminal/ui/screens/chart/components/timeframe_selector.dart';
import 'package:volex_terminal/ui/screens/chart/components/chart_stats_overlay.dart';
import 'package:volex_terminal/ui/sheets/smart_order_sheet.dart';
import 'package:volex_terminal/ui/providers/dashboard_provider.dart';
import 'package:volex_terminal/core/app_logger.dart';
// [NEW] Backtesting Imports
import 'package:volex_terminal/engine/replay_controller.dart';
import 'package:volex_terminal/ui/replay_panel.dart';

class ChartScreenV2 extends StatefulWidget {
  final MarketDataRepository? repository;
  final String? symbol; // Added optional symbol

  const ChartScreenV2({super.key, this.repository, this.symbol});

  @override
  State<ChartScreenV2> createState() => _ChartScreenV2State();
}

class _ChartScreenV2State extends State<ChartScreenV2> {
  // Logic mostly ported from TerminalScreen, but simplified for new UI
  late MarketDataRepository _repository;
  late ChartController _chartController;
  // [NEW] Backtesting State
  final ReplayController _replayController = ReplayController();
  bool _isReplayMode = false;

  late String _currentSymbol; // Changed from init assignment
  String _currentTimeframe = '1m';
  List<Candle> _candles = [];
  double _currentPrice = 0.0;
  bool _isLoading = true;

  StreamSubscription<Candle>? _candleSubscription;
  StreamSubscription<Candle>? _replaySubscription;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MarketDataRepository();
    _chartController = ChartController();
    _currentSymbol = widget.symbol ?? 'BTCUSDT'; // Default to BTC if null

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _candleSubscription?.cancel();
    _replaySubscription?.cancel();
    _chartController.dispose();
    _replayController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final history = await _repository.fetchHistory(
          symbol: _currentSymbol, interval: _currentTimeframe);

      if (mounted) {
        setState(() {
          _candles = history;
          if (history.isNotEmpty) {
            _currentPrice = history.last.close;
          }
          _isLoading = false;
        });

        if (!_isReplayMode) {
          _chartController.setData(history);
          _subscribeToLiveUpdates();
        } else {
          // If we initialized data while in replay mode (e.g. symbol change),
          // we should probably reload the replay controller?
          // For now, let's assume symbol change exits replay or re-inits it.
          _toggleReplayMode(); // Reset replay with new data
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      AppLogger.error('Chart Overlay Error', e);
    }
  }

  void _subscribeToLiveUpdates() {
    _candleSubscription?.cancel();
    _repository.connectStream(symbol: _currentSymbol.toLowerCase());
    _candleSubscription = _repository.updatesStream.listen((candle) {
      if (mounted) {
        setState(() {
          _updateCandleList(candle);
          _currentPrice = candle.close;
        });
        _chartController.updateLastCandle(candle);
      }
    });
  }

  // [NEW] Replay Logic
  void _toggleReplayMode() {
    setState(() {
      _isReplayMode = !_isReplayMode;
    });

    if (_isReplayMode) {
      // ENTER REPLAY
      AppLogger.info("Entering Replay Mode");
      _candleSubscription?.cancel(); // Stop live

      // Load current history into replayer
      // We pass the FULL history we have.
      // The replayer will start from index 0 or user seeks.
      // Note: Realistically we might want to fetch a deeper history for backtesting.
      // For MVP, we play back what we have.
      _replayController.loadHistory(List.from(_candles));

      // Clear chart to empty (or start point)
      _candles = [];
      _chartController.setData([]);

      // Listen to Replayer
      _replaySubscription?.cancel();
      _replaySubscription = _replayController.candleStream.listen((candle) {
        if (mounted) {
          setState(() {
            _updateCandleList(candle);
            _currentPrice = candle.close;
          });
          _chartController.updateLastCandle(candle);
        }
      });

      // Auto-play or let user hit play? Let's let user hit play.
    } else {
      // EXIT REPLAY
      AppLogger.info("Exiting Replay Mode");
      _replaySubscription?.cancel();
      _replayController.pause();

      // Reload live data
      _initializeData();
    }
  }

  void _updateCandleList(Candle newCandle) {
    if (_candles.isEmpty) {
      _candles.add(newCandle);
      return;
    }
    final last = _candles.last;
    if (newCandle.time > last.time) {
      _candles.add(newCandle);
    } else if (newCandle.time == last.time) {
      _candles.last = newCandle;
    }
  }

  void _onSymbolChanged(String symbol) {
    if (_currentSymbol == symbol) return;
    setState(() => _currentSymbol = symbol);
    if (_isReplayMode) _toggleReplayMode(); // Exit replay on symbol change
    _initializeData();
  }

  void _onTimeframeChanged(String tf) {
    if (_currentTimeframe == tf) return;
    setState(() => _currentTimeframe = tf);
    if (_isReplayMode) _toggleReplayMode(); // Exit replay on timeframe change
    _initializeData();
  }

  List<TradeSignal> _buildActiveSignals(List<Candle> candles) {
    // [NEW] Use Replay signals if in replay mode?
    // Actually ChartController has signals too.
    // And ScriptEditor pushes to ChartController.
    // So we should merge sources or use ChartController's signals.

    // For now, let's keep the Order-based signals AND merge ChartController signals (from script)
    // The ChartController is passed to ReplayPanel, so simulated signals go there.

    // Let's grab signals from ChartController (which ReplayPanel populates)
    final scriptSignals = _chartController.signals;

    if (candles.isEmpty) return scriptSignals; // Or empty

    // Ensure ExecutionManager is available in context
    final manager = context.watch<ExecutionManager>();
    final filledOrders = manager.orders
        .where((o) =>
            o.symbol == _currentSymbol &&
            o.status == OrderStatus.filled &&
            o.filledAt != null)
        .toList();

    List<TradeSignal> signals = List.from(scriptSignals);

    // Map orders to signals
    for (final order in filledOrders) {
      signals.add(TradeSignal(
        timestamp: order.filledAt!,
        price: order.filledPrice ?? order.price,
        side: order.side,
        strategyName: order.strategyId ?? 'Manual',
        description: order.type == OrderType.market ? 'MKT' : 'LMT',
      ));
    }

    return signals;
  }

  /// The user's own filled orders on the current symbol, as chart markers
  /// (green triangle below the bar for buys, red above for sells).
  List<ChartMarker> _buildTradeMarkers(BuildContext context) {
    final manager = context.watch<ExecutionManager>();
    final marks = <ChartMarker>[];
    for (final o in manager.orders) {
      if (o.symbol != _currentSymbol) continue;
      if (o.status != OrderStatus.filled || o.filledAt == null) continue;
      marks.add(ChartMarker(
        timeMs: o.filledAt!.millisecondsSinceEpoch,
        price: o.filledPrice ?? o.price,
        isBuy: o.side == OrderSide.buy,
      ));
    }
    return marks;
  }

  @override
  Widget build(BuildContext context) {
    // 85% Chart Real Estate Goal
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _chartController),
          ChangeNotifierProvider.value(value: _replayController),
        ],
        child: Scaffold(
          backgroundColor: VxColors.background, // Match theme
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Layer 0: The Chart (Full Screen)
                Positioned.fill(
                  top: 70, // Leave space for top bar
                  bottom: 120, // Leave space for bottom controls + padding
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: VxColors.neonCyan))
                      : VxProChart(
                          candles: _candles,
                          showVolume: true,
                          showIndicators: true,
                          markers: _buildTradeMarkers(context),
                          activeSignals: _buildActiveSignals(_candles),
                        ),
                ),

                // Layer 1: Top Bar (Floating)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  // height: 60, // Managed by safearea inside TopBar
                  child: ChartTopBar(
                    symbol: _currentSymbol,
                    price: _currentPrice,
                    onSymbolTap: () => _onSymbolChanged(_currentSymbol),
                    isReplayMode: _isReplayMode,
                    onReplayTap: _toggleReplayMode,
                  ),
                ),

                // Layer 2: Chart Stats Overlay
                Positioned(
                  top: 100,
                  left: 20,
                  child: Consumer<DashboardProvider>(
                    builder: (context, dashboard, _) {
                      final ticker = dashboard.getTicker(_currentSymbol);
                      return ChartStatsOverlay(
                        symbol: _currentSymbol,
                        currentPrice: _currentPrice,
                        change24h: ticker?.changePercent ?? 0.0,
                        high24h: ticker?.highPrice ?? 0.0,
                        low24h: ticker?.lowPrice ?? 0.0,
                        volume24h: ticker?.quoteVolume ?? 0.0,
                      );
                    },
                  ),
                ),

                // Layer 3: Timeframe Selector (Hide in Replay?)
                if (!_isReplayMode)
                  Positioned(
                    bottom: 60, // Above the bottom nav
                    left: 0,
                    right: 0,
                    height: 44,
                    child: TimeframeSelector(
                      selected: _currentTimeframe,
                      onSelected: _onTimeframeChanged,
                    ),
                  ),

                // [NEW] Layer 3.5: Replay Panel
                if (_isReplayMode) ReplayPanel(controller: _replayController),

                // Layer 4: Trade FAB
                if (!_isReplayMode)
                  Positioned(
                    bottom: 130,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SmartOrderSheet(
                            symbol: _currentSymbol,
                            currentPrice: _currentPrice,
                          ),
                        );
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: VxColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: VxColors.neonCyan.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                          border:
                              Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.bolt,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ));
  }
}
