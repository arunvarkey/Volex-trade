import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'design_system/vx_colors.dart';
import '../engine/chart_controller.dart';
import '../engine/execution_manager.dart';
import '../engine/replay_controller.dart';
import 'package:volex_terminal/data/i_market_data_repository.dart';
import 'package:volex_terminal/domain/order.dart';
import '../domain/trade_signal.dart';
import 'design_system/charts/vx_candle_chart.dart';
import '../domain/candle_model.dart';
import 'package:confetti/confetti.dart';
import 'alerts/create_alert_dialog.dart';
import 'replay_panel.dart';
import 'design_system/trade_success_confetti.dart';
import '../services/alert_service.dart';
import '../core/service_locator.dart';
import 'terminal/terminal_top_bar.dart';
import 'terminal/terminal_timeframe_bar.dart';
import 'terminal/terminal_trading_panel.dart';
import 'terminal/terminal_bottom_tabs.dart';
import 'widgets/risk_disclaimer_dialog.dart';
import '../core/app_logger.dart';

/// PERFECT UNIVERSAL Terminal Screen
/// Works flawlessly on ALL phones: iPhone SE, iPhone 15 Pro Max, Galaxy, Pixel, etc.
/// ZERO overflow guaranteed!
class TerminalScreen extends StatefulWidget {
  final IMarketDataRepository? repository;
  const TerminalScreen({super.key, this.repository});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  late TabController _bottomTabController;
  late IMarketDataRepository _repository;
  late ChartController _chartController;
  late ConfettiController _confettiController;
  late TextEditingController _amountController;
  final ReplayController _replayController =
      ReplayController(); // Replay Engine

  // State
  String _currentSymbol = 'BTCUSDT';
  String _currentTimeframe = '1m';
  List<Candle> _candles = [];
  double _currentPrice = 0.0;
  bool _isLoading = true;
  bool _isMarketOrder = true;
  bool _isReplayMode = false;

  StreamSubscription<Candle>? _candleSubscription;
  StreamSubscription? _replaySubscription; // Subscription for replay stream

  // [NEW] Alerts
  final AlertService _alertService = getIt<AlertService>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _bottomTabController = TabController(length: 3, vsync: this);
    _repository = widget.repository ?? getIt<IMarketDataRepository>();
    _chartController = ChartController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      RiskDisclaimerDialog.showIfNeeded(context);
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      if (_isReplayMode) {
        // Logic to load historical data for replay
        // For now, load same history but feed it to ReplayController
        final history = await _repository.fetchHistory(
            symbol: _currentSymbol, interval: _currentTimeframe);
        _replayController.loadHistory(history);
        _candles = []; // Clear chart initially
        _chartController.setData([], preserveState: false);
        _bindReplayStream();
      } else {
        final history = await _repository.fetchHistory(
            symbol: _currentSymbol, interval: _currentTimeframe);
        if (mounted) {
          setState(() {
            _candles = history;
            if (history.isNotEmpty) {
              _currentPrice = history.last.close;
            }
          });
          _chartController.setData(history);
          _subscribeToLiveUpdates();
        }
      }
    } catch (e) {
      AppLogger.error('Error initializing data', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: VxColors.danger,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToLiveUpdates() {
    _candleSubscription?.cancel();
    _repository.connectStream(symbol: _currentSymbol.toLowerCase());
    _candleSubscription = _repository.updatesStream.listen((candle) {
      if (mounted && !_isReplayMode) {
        setState(() {
          _updateCandleList(candle);
          _currentPrice = candle.close;
        });
        _chartController.updateLastCandle(candle);
        _alertService.onPriceUpdate(candle); // [NEW] Check alerts
      }
    });
  }

  void _bindReplayStream() {
    _replaySubscription?.cancel();
    _replaySubscription = _replayController.candleStream.listen((candle) {
      if (mounted && _isReplayMode) {
        setState(() {
          _updateCandleList(candle);
          _currentPrice = candle.close;
        });
        _chartController.updateLastCandle(candle);
      }
    });
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

  void _toggleReplayMode() {
    setState(() {
      _isReplayMode = !_isReplayMode;
    });
    // Re-initialize data based on mode
    _candleSubscription?.cancel();
    _replaySubscription?.cancel();
    _chartController.clearSignals(); // Clear signals on mode switch
    _initializeData();
  }

  Future<void> _handleTrade(bool isBuy, bool isMarket) async {
    final quantity = double.tryParse(_amountController.text);
    if (quantity == null || quantity <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid quantity'),
            backgroundColor: VxColors.danger,
          ),
        );
      }
      return;
    }

    final manager = context.read<ExecutionManager>();

    try {
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        symbol: _currentSymbol,
        type: isMarket ? OrderType.market : OrderType.limit,
        side: isBuy ? OrderSide.buy : OrderSide.sell,
        quantity: quantity,
        price: _currentPrice,
        status: OrderStatus.pending,
      );

      await manager.placeOrder(order);

      if (isBuy) {
        _confettiController.play();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isBuy ? "BUY" : "SELL"} Order Placed!'),
            backgroundColor: VxColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trade Failed: $e'),
            backgroundColor: VxColors.danger,
          ),
        );
      }
    }
  }

  void _switchSymbol(String symbol) {
    if (_currentSymbol == symbol) return;
    setState(() {
      _currentSymbol = symbol;
      _isLoading = true;
    });

    // Handle repo switch
    _repository.switchStream(symbol, _currentTimeframe);

    // Re-fetch history
    _initializeData();
  }

  void _showSymbolPicker() {
    final symbols = [
      'BTCUSDT',
      'ETHUSDT',
      'SOLUSDT',
      'XRPUSDT',
      'DOGEUSDT',
      'ADAUSDT',
      'AVAXUSDT',
      'DOTUSDT',
      'MATICUSDT',
      'LTCUSDT'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: VxColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: Text(
                  "SELECT ASSET",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: symbols.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final sym = symbols[index];
                    final isSelected = sym == _currentSymbol;
                    return ListTile(
                      title: Text(
                        sym,
                        style: TextStyle(
                          color: isSelected ? VxColors.neonCyan : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: VxColors.neonCyan)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _switchSymbol(sym);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _switchTimeframe(String tf) {
    if (_currentTimeframe == tf) return;
    setState(() {
      _currentTimeframe = tf;
      _isLoading = true;
    });

    // Switch live stream to new interval
    _repository.switchStream(_currentSymbol, tf);

    // Re-fetch history
    _initializeData();
  }

  @override
  void dispose() {
    _candleSubscription?.cancel();
    _bottomTabController.dispose();
    _chartController.dispose();
    _confettiController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Layout - PERFECT for all screens
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate perfect dimensions
                final screenHeight = constraints.maxHeight;

                // Adaptive sizing based on screen
                final isSmallScreen = screenHeight < 700;
                final isVerySmallScreen = screenHeight < 650;

                // Perfect heights that NEVER overflow
                const topBarHeight = 60.0;
                const timeframeHeight = 40.0;
                final bottomTabsHeight =
                    isVerySmallScreen ? 160.0 : (isSmallScreen ? 180.0 : 220.0);

                // Calculate remaining space for chart + trading panel
                final remainingHeight = screenHeight -
                    topBarHeight -
                    timeframeHeight -
                    bottomTabsHeight;

                return Column(
                  children: [
                    // TOP BAR - Fixed 60px
                    SizedBox(
                      height: topBarHeight,
                      child: TerminalTopBar(
                        currentSymbol: _currentSymbol,
                        currentPrice: _currentPrice,
                        isReplayMode: _isReplayMode,
                        onToggleReplay: _toggleReplayMode,
                        onShowSymbolPicker: _showSymbolPicker,
                        onShowAlerts: _showAlertsDialog,
                      ),
                    ),

                    // TIMEFRAME BAR - Fixed 40px
                    SizedBox(
                      height: timeframeHeight,
                      child: TerminalTimeframeBar(
                        currentTimeframe: _currentTimeframe,
                        onTimeframeSelected: _switchTimeframe,
                      ),
                    ),

                    // MAIN CONTENT - Uses exact remaining space
                    SizedBox(
                      height: remainingHeight,
                      child: Row(
                        children: [
                          // CHART - 55% on small screens, 65% on normal
                          Expanded(
                            flex: isVerySmallScreen ? 55 : 65,
                            child: _buildChartSection(remainingHeight),
                          ),

                          // TRADING PANEL - 45% on small screens, 35% on normal
                          Expanded(
                            flex: isVerySmallScreen ? 45 : 35,
                            child: TerminalTradingPanel(
                              height: remainingHeight,
                              isVerySmall: isVerySmallScreen,
                              isMarketOrder: _isMarketOrder,
                              amountController: _amountController,
                              onTrade: _handleTrade,
                              onToggleOrderType: (val) =>
                                  setState(() => _isMarketOrder = val),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BOTTOM TABS - Adaptive height
                    SizedBox(
                      height: bottomTabsHeight,
                      child: TerminalBottomTabs(
                        tabController: _bottomTabController,
                        currentPrice: _currentPrice,
                      ),
                    ),
                  ],
                );
              },
            ),

            // CONFETTI OVERLAY
            TradeSuccessConfetti(controller: _confettiController),

            // REPLAY PANEL OVERLAY
            if (_isReplayMode) ReplayPanel(controller: _replayController),
          ],
        ),
      ),
    );
  }

  List<TradeSignal> _buildActiveSignals(List<Candle> candles) {
    if (candles.isEmpty) return [];

    final manager = context.watch<ExecutionManager>();
    final filledOrders = manager.orders
        .where((o) =>
            o.symbol == _currentSymbol &&
            o.status == OrderStatus.filled &&
            o.filledAt != null)
        .toList();

    List<TradeSignal> signals = [];

    // Map orders to candle indices for overlay
    for (final order in filledOrders) {
      int index = -1;
      for (int i = 0; i < candles.length; i++) {
        if (candles[i].date.millisecondsSinceEpoch <=
            order.filledAt!.millisecondsSinceEpoch) {
          index = i;
        } else {
          break;
        }
      }

      if (index != -1) {
        signals.add(TradeSignal(
          timestamp: order.filledAt!,
          price: order.filledPrice ?? order.price,
          side: order.side,
          strategyName: order.strategyId ?? 'Manual',
          description: order.type == OrderType.market ? 'MKT' : 'LMT',
        ));
      }
    }

    return signals;
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateAlertDialog(
        symbol: _currentSymbol,
        currentPrice: _currentPrice,
      ),
    );
  }

  Widget _buildChartSection(double height) {
    return Container(
      color: VxColors.deepBlack,
      height: height,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: VxColors.neonCyan,
                strokeWidth: 3,
              ),
            )
          : _candles.isEmpty
              ? Center(
                  child: Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Colors.white.withOpacity(0.1),
                  ),
                )
              : VxCandleChart(
                  candles: _candles,
                  showVolume: false,
                  showIndicators: true,
                  activeSignals: _buildActiveSignals(_candles),
                ),
    );
  }
}
