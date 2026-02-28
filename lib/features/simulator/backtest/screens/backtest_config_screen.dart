// lib/features/simulator/backtesting/screens/backtest_config_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../ui/design_system/vx_colors.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import '../models/backtest_request.dart';
import '../backtest_engine.dart';
import 'package:volex_terminal/features/subscriptions/services/subscription_service.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:provider/provider.dart';

class BacktestConfigScreen extends StatefulWidget {
  final GeneratedStrategy? strategy;

  const BacktestConfigScreen({super.key, this.strategy});

  @override
  State<BacktestConfigScreen> createState() => _BacktestConfigScreenState();
}

class _BacktestConfigScreenState extends State<BacktestConfigScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _endDate = DateTime.now();
  double _initialEquity = 10000.0;
  bool _isRunning = false;

  final _engine = GetIt.I<BacktestEngine>();

  // Strategy Selection
  dynamic _selectedStrategy; // GeneratedStrategy or Strategy (runtime)

  @override
  void initState() {
    super.initState();
    _selectedStrategy = widget.strategy;
  }

  @override
  Widget build(BuildContext context) {
    // If no strategy passed and none selected, show selector
    final strategies = context.watch<StrategyEngine?>()?.allStrategies ?? [];

    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      appBar: AppBar(
        backgroundColor: VxColors.deepBlack,
        title: const Text(
          'BACKTEST CONFIGURATION',
          style: TextStyle(
            fontFamily: 'Courier',
            color: VxColors.neonCyan,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Strategy Selection
            _buildSectionHeader('STRATEGY'),
            const SizedBox(height: 12),
            _buildStrategySelector(strategies),

            const SizedBox(height: 24),

            // Date range
            _buildSectionHeader('BACKTEST PERIOD'),
            const SizedBox(height: 12),
            _buildDateRangePicker(),

            const SizedBox(height: 24),

            // Initial equity
            _buildSectionHeader('INITIAL CAPITAL'),
            const SizedBox(height: 12),
            _buildEquitySlider(),

            const SizedBox(height: 32),

            // Run button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isRunning || _selectedStrategy == null)
                    ? null
                    : _runBacktest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.neonGreen,
                  foregroundColor: VxColors.deepBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: _isRunning
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(VxColors.deepBlack),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('RUNNING BACKTEST...'),
                        ],
                      )
                    : const Text(
                        'RUN BACKTEST',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategySelector(List<dynamic> runtimeStrategies) {
    if (_selectedStrategy != null) {
      return _buildStrategyCard(_selectedStrategy);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: Colors.grey[900],
          hint: Text('Select a Strategy',
              style: TextStyle(color: Colors.grey[400])),
          items: runtimeStrategies.map((s) {
            return DropdownMenuItem<String>(
              value: s.id,
              child: Text(s.name, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (val) {
            final s =
                runtimeStrategies.firstWhere((element) => element.id == val);
            setState(() {
              _selectedStrategy = s;
            });
          },
        ),
      ),
    );
  }

  Widget _buildStrategyCard(dynamic strategy) {
    // Handle both GeneratedStrategy and Strategy
    final name = strategy is GeneratedStrategy ? strategy.name : strategy.name;
    final symbol = strategy is GeneratedStrategy
        ? strategy.symbol
        : 'BTCUSDT'; // Runtime strategy might not have fixed symbol yet?
    final timeframe = strategy is GeneratedStrategy ? strategy.timeframe : '1h';

    return InkWell(
      onTap: widget.strategy == null
          ? () {
              setState(() {
                _selectedStrategy = null;
              });
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VxColors.neonCyan.withOpacity(0.1),
          border: Border.all(color: VxColors.neonCyan.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toUpperCase(),
                    style: const TextStyle(
                      color: VxColors.neonCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(symbol, VxColors.neonPurple),
                      const SizedBox(width: 8),
                      _buildInfoChip(timeframe, VxColors.neonGreen),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.strategy == null)
              const Icon(Icons.close, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: VxColors.neonCyan,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('From:', style: TextStyle(color: Colors.grey[400])),
              TextButton(
                onPressed: () => _selectDate(context, true),
                child: Text(
                  _formatDate(_startDate),
                  style: const TextStyle(color: VxColors.neonCyan),
                ),
              ),
            ],
          ),
          Divider(color: Colors.grey[800]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('To:', style: TextStyle(color: Colors.grey[400])),
              TextButton(
                onPressed: () => _selectDate(context, false),
                child: Text(
                  _formatDate(_endDate),
                  style: const TextStyle(color: VxColors.neonCyan),
                ),
              ),
            ],
          ),
          Divider(color: Colors.grey[800]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duration:', style: TextStyle(color: Colors.grey[400])),
              Text(
                '${_endDate.difference(_startDate).inDays} days',
                style: const TextStyle(
                    color: VxColors.neonGreen, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquitySlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Starting Balance:',
                style: TextStyle(color: Colors.grey[400])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: VxColors.neonGreen.withOpacity(0.2),
                border: Border.all(color: VxColors.neonGreen),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '\$${_initialEquity.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: VxColors.neonGreen,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: VxColors.neonGreen,
            inactiveTrackColor: Colors.grey[800],
            thumbColor: VxColors.neonGreen,
            overlayColor: VxColors.neonGreen.withOpacity(0.2),
          ),
          child: Slider(
            value: _initialEquity,
            min: 1000,
            max: 100000,
            divisions: 99,
            onChanged: (value) => setState(() => _initialEquity = value),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$1,000',
                style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            Text('\$100,000',
                style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: VxColors.neonCyan,
              onPrimary: VxColors.deepBlack,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 30));
          }
        }
      });
    }
  }

  Future<void> _runBacktest() async {
    setState(() => _isRunning = true);

    // Check subscription limit (Soft Gate)
    final canRun = await GetIt.I<SubscriptionService>().checkAndTrackBacktest();
    if (!canRun) {
      setState(() => _isRunning = false);
      if (mounted) {
        _showUpgradeDialog(
            "Free accounts get 1 backtest per day. Want to test this strategy now? Premium gives you unlimited backtests.");
      }
      return;
    }

    try {
      final isGenerated = _selectedStrategy is GeneratedStrategy;

      final request = BacktestRequest(
        strategy: isGenerated ? _selectedStrategy : null,
        runtimeStrategy: isGenerated ? null : _selectedStrategy,
        startDate: _startDate,
        endDate: _endDate,
        initialEquity: _initialEquity,
      );

      final result = await _engine.run(request);

      if (mounted) {
        setState(() => _isRunning = false);

        if (result.isSuccess) {
          context.push('/simulator/backtest-results', extra: result);
        } else {
          _showError(result.error!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRunning = false);
        _showError('Backtest failed: $e');
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.deepBlack,
        title: const Text(
          'ERROR',
          style: TextStyle(color: VxColors.neonRed, letterSpacing: 1.5),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: VxColors.neonCyan)),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.deepBlack,
        title: const Text(
          'UPGRADE TO PREMIUM',
          style: TextStyle(
            color: VxColors.neonPurple,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/subscription');
            },
            child: const Text('Start Free Trial',
                style: TextStyle(color: VxColors.neonCyan)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Wait Until Tomorrow',
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
