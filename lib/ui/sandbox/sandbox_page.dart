import 'package:flutter/material.dart';
import '../../engine/sandbox/sandbox_data_feed.dart';
import '../../engine/sandbox/sandbox_execution_engine.dart';
import '../../engine/strategy/strategy_metadata.dart';
import '../design_system/vx_colors.dart';
import '../design_system/vx_typography.dart';
import '../design_system/vx_spacing.dart';
import '../design_system/vx_card.dart';

import '../parameters/parameter_editor.dart';
import '../../engine/parameters/parameter_models.dart';

class SandboxPage extends StatefulWidget {
  const SandboxPage({super.key});

  @override
  State<SandboxPage> createState() => _SandboxPageState();
}

class _SandboxPageState extends State<SandboxPage> {
  final SandboxExecutionEngine _engine = SandboxExecutionEngine();

  List<StrategyMetadata> _strategies = [];
  StrategyMetadata? _selectedStrategy;
  final DataFeedType _selectedFeedType = DataFeedType.synthetic;
  bool _isRunning = false;
  SandboxSessionResult? _lastResult;

  Map<String, dynamic> _currentParameters = {};

  @override
  void initState() {
    super.initState();
    _loadStrategies();
  }

  void _loadStrategies() {
    _strategies = [
      StrategyMetadata(
          id: 's1',
          name: 'Momentum Scalper',
          description: 'Quick trades',
          author: 'me',
          version: '1.0',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: [],
          riskProfile: RiskProfile.medium,
          timeframe: StrategyTimeframe.scalping,
          supportedSymbols: ['BTC'],
          parameters: [
            const StrategyParameterSchema(
                name: 'Lookback Period',
                type: ParameterType.integer,
                min: 5,
                max: 100,
                defaultValue: 14,
                isTraderEditable: true),
            const StrategyParameterSchema(
                name: 'Stop Loss %',
                type: ParameterType.double,
                min: 0.1,
                max: 5.0,
                defaultValue: 1.0,
                isTraderEditable: true),
            const StrategyParameterSchema(
                name: 'Take Profit %',
                type: ParameterType.double,
                min: 0.1,
                max: 10.0,
                defaultValue: 2.0,
                isTraderEditable: true),
          ],
          monthlyPrice: 0),
      StrategyMetadata(
          id: 's2',
          name: 'Safe Holder',
          description: 'Long term',
          author: 'me',
          version: '1.0',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: [],
          riskProfile: RiskProfile.low,
          timeframe: StrategyTimeframe.dayTrading,
          supportedSymbols: ['ETH'],
          parameters: [
            const StrategyParameterSchema(
                name: 'Buy Dip %',
                type: ParameterType.double,
                min: 1.0,
                max: 20.0,
                defaultValue: 5.0,
                isTraderEditable: true),
          ],
          monthlyPrice: 0),
    ];
    _selectStrategy(_strategies.first);
  }

  void _selectStrategy(StrategyMetadata strategy) {
    setState(() {
      _selectedStrategy = strategy;
      _currentParameters = {
        for (var p in strategy.parameters) p.name: p.defaultValue
      };
      _lastResult = null;
    });
  }

  bool _isCancelled = false;

  Future<void> _runSandbox() async {
    if (_selectedStrategy == null) return;

    setState(() {
      _isRunning = true;
      _isCancelled = false;
      _lastResult = null;
    });

    SandboxDataFeed feed = _selectedFeedType == DataFeedType.synthetic
        ? SyntheticDataFeed()
        : HistoricalDataFeed(symbol: "BTC-USD");

    final paramSet = StrategyParameterSet(
        strategyId: _selectedStrategy!.id,
        userId: 'current_user',
        values: _currentParameters,
        version: 1,
        updatedAt: DateTime.now());

    final result = await _engine.run(
      _selectedStrategy!,
      feed,
      parameters: paramSet,
      isCancelled: () => _isCancelled,
    );

    if (mounted) {
      setState(() {
        _isRunning = false;
        _lastResult = result;
      });
    }
  }

  void _stopSandbox() {
    setState(() => _isCancelled = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      body: Padding(
        padding: const EdgeInsets.all(VxSpacing.lg),
        child: Column(
          children: [
            // Header / Strategy Selector
            _buildHeader(),
            const SizedBox(height: VxSpacing.lg),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Panel: Configuration
                  SizedBox(
                    width: 350,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VxCard(
                          title: VxText.subtitle("CONFIGURATION"),
                          child: Column(
                            children: [
                              if (_selectedStrategy != null)
                                ParameterEditor(
                                  schemas: _selectedStrategy!.parameters,
                                  currentValues: _currentParameters,
                                  isEditable: true,
                                  onValuesChanged: (values) {
                                    setState(() {
                                      _currentParameters.addAll(values);
                                    });
                                  },
                                ),
                              const SizedBox(height: VxSpacing.xl),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isRunning
                                        ? VxColors.neonRed.withValues(alpha: 0.8)
                                        : VxColors.neonCyan.withValues(alpha: 0.8),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.all(22),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: _isRunning
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black))
                                      : const Icon(Icons.bolt),
                                  label: VxText.bodyBold(_isRunning
                                      ? "STOP_SIMULATION"
                                      : "RUN_SIMULATION"),
                                  onPressed:
                                      _isRunning ? _stopSandbox : _runSandbox,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Panel: Results
                  const SizedBox(width: VxSpacing.lg),
                  Expanded(
                    child: VxCard(
                      title: VxText.subtitle("RESULTS"),
                      child: _lastResult == null && !_isRunning
                          ? Center(
                              child: VxText.body(
                                  "AWAITING_SIMULATION_PARAMETERS",
                                  color: Colors.white10))
                          : _isRunning
                              ? Center(
                                  child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                        color: VxColors.neonCyan,
                                        strokeWidth: 2),
                                    const SizedBox(height: 24),
                                    VxText.mono(
                                        "SIMULATING_REALTIME_MARKET_FLOW...",
                                        color: VxColors.neonCyan,
                                        fontSize: 12),
                                  ],
                                ))
                              : _buildResultsView(_lastResult!),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        VxText.heading3("ALGO SANDBOX", color: Colors.white),
        const Spacer(),
        DropdownButton<StrategyMetadata>(
          value: _selectedStrategy,
          dropdownColor: VxColors.surface,
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, color: VxColors.neonCyan),
          items: _strategies.map((s) {
            return DropdownMenuItem(
              value: s,
              child: VxText.bodyBold(s.name, color: Colors.white),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) _selectStrategy(val);
          },
        ),
      ],
    );
  }

  Widget _buildResultsView(SandboxSessionResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: result.success
                ? VxColors.neonGreen.withValues(alpha: 0.05)
                : VxColors.neonRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: result.success
                    ? VxColors.neonGreen.withValues(alpha: 0.2)
                    : VxColors.neonRed.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric("STATUS", result.success ? "PASSED" : "FAILED",
                  result.success ? VxColors.neonGreen : VxColors.neonRed),
              _buildMetric(
                  "TRADES", "${result.metrics.tradesExecuted}", Colors.white70),
              _buildMetric(
                  "WIN_RATE",
                  "${(result.metrics.winRate * 100).toStringAsFixed(1)}%",
                  VxColors.neonCyan),
              _buildMetric(
                  "SHARPE",
                  result.metrics.sharpeEstimate.toStringAsFixed(2),
                  Colors.purpleAccent),
            ],
          ),
        ),
        const SizedBox(height: 32),
        VxText.heading3("DEBUG_STREAM // SESSION_LOGS", color: Colors.white),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: ListView.builder(
              itemCount: result.logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: VxText.mono(
                    "> ${result.logs[index]}",
                    color: Colors.white24,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
        if (result.success) ...[
          const SizedBox(height: 24),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: VxColors.neonGreen.withValues(alpha: 0.8),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text("Strategy version committed to registry.")));
                  },
                  child: VxText.bodyBold("COMMIT_TO_REGISTRY")))
        ]
      ],
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        VxText.monoBold(value, fontSize: 24, color: color),
        const SizedBox(height: 4),
        VxText.mono(label, color: Colors.white24, fontSize: 10),
      ],
    );
  }
}
