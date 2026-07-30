import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../sheets/vx_trade_sheet.dart';
import '../navigation/vx_navigation_helper.dart';
import '../screens/strategies/ai_strategy_generator_screen.dart';
import 'package:volex_terminal/ui/providers/dashboard_provider.dart';
import 'package:volex_terminal/engine/strategy/strategy_engine.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import '../../core/app_router.dart';
import 'package:volex_terminal/engine/alerts/alert_engine.dart';
import 'package:volex_terminal/engine/alerts/alert_models.dart';
import '../../engine/strategy/built_in_strategies.dart';

/// The Central Floating Action Button - "Command Palette"
class VxActionCenter extends StatefulWidget {
  const VxActionCenter({super.key});

  @override
  State<VxActionCenter> createState() => _VxActionCenterState();
}

class _VxActionCenterState extends State<VxActionCenter>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: VxColors.neonCyan
                    .withValues(alpha: 0.3 + _pulseController.value * 0.2),
                blurRadius: 20 + _pulseController.value * 10,
                spreadRadius: 2 + _pulseController.value * 3,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _showCommandPalette(context),
            backgroundColor: VxColors.surface,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: VxColors.neonCyan,
                  width: 2,
                ),
                gradient: RadialGradient(
                  colors: [
                    VxColors.neonCyan.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: VxColors.neonCyan,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCommandPalette(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const VxCommandPalette(),
    );
  }
}

/// Command Palette - Quick Actions Sheet
class VxCommandPalette extends StatefulWidget {
  const VxCommandPalette({super.key});

  @override
  State<VxCommandPalette> createState() => _VxCommandPaletteState();
}

class _VxCommandPaletteState extends State<VxCommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<_Command> _getCommands(StrategyEngine engine) {
    // Find any enabled strategy
    final activeStrategy = engine.allStrategies.firstWhere((s) => s.isEnabled,
        orElse: () => GhostTrendStrategy()..isEnabled = false);

    final isRunning = activeStrategy.isEnabled;

    return [
      _Command(
        icon: Icons.trending_up,
        label: 'Quick Buy',
        description: 'Execute market buy order',
        color: VxColors.neonGreen,
        action: _handleQuickBuy,
      ),
      _Command(
        icon: Icons.trending_down,
        label: 'Quick Sell',
        description: 'Execute market sell order',
        color: VxColors.neonRed,
        action: _handleQuickSell,
      ),
      _Command(
        icon: Icons.auto_awesome,
        label: 'AI Strategy Gen',
        description: 'Describe and build strategy',
        color: VxColors.neonCyan,
        action: _handleAiStrategy,
      ),
      _Command(
        icon: isRunning ? Icons.auto_mode : Icons.auto_graph,
        label: isRunning ? 'Manage Strategy' : 'Start Strategy',
        description: isRunning
            ? 'Active: ${activeStrategy.name}'
            : 'Deploy automated trading',
        color: isRunning ? VxColors.neonGreen : VxColors.neonPurple,
        action: _handleStartStrategy,
      ),
      _Command(
        icon: Icons.search,
        label: 'Find Symbol',
        description: 'Search markets',
        color: VxColors.neonCyan,
        action: _handleFindSymbol,
      ),
      _Command(
        icon: Icons.notifications_active,
        label: 'Set Alert',
        description: 'Price or condition alert',
        color: VxColors.warning,
        action: _handleSetAlert,
      ),
      _Command(
        icon: Icons.show_chart,
        label: 'Open Terminal',
        description: 'Direct chart view',
        color: VxColors.neonCyan,
        action: _handleOpenTerminal,
      ),
    ];
  }

  List<_Command> _filteredCommands(List<_Command> allCommands) {
    if (_searchQuery.isEmpty) return allCommands;
    return allCommands
        .where((cmd) =>
            cmd.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            cmd.description.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch engine for updates
    final engine = context.watch<StrategyEngine>();
    final commands = _getCommands(engine);
    final filtered = _filteredCommands(commands);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: VxColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Icon(Icons.bolt, color: VxColors.neonCyan, size: 24),
                SizedBox(width: 8),
                Text(
                  'COMMAND CENTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search commands...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: VxColors.neonCyan),
                filled: true,
                fillColor: VxColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Commands List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final command = filtered[index];
                return _CommandTile(
                  command: command,
                  onTap: () {
                    Navigator.pop(context);
                    command.action();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Command Handlers
  void _handleQuickBuy() {
    final dashboard = context.read<DashboardProvider>();
    final ticker = dashboard.getTicker('BTCUSDT');
    final price = ticker?.closePrice ?? 43250.50;

    VxTradeSheet.show(
      context,
      symbol: 'BTC/USDT',
      currentPrice: price,
      candles: [],
      initialMode: TradeMode.buy,
      onNavigateToTab: (index) => _navigateToTab(index),
    );
  }

  void _handleQuickSell() {
    final dashboard = context.read<DashboardProvider>();
    final ticker = dashboard.getTicker('BTCUSDT');
    final price = ticker?.closePrice ?? 43250.50;

    VxTradeSheet.show(
      context,
      symbol: 'BTC/USDT',
      currentPrice: price,
      candles: [],
      initialMode: TradeMode.sell,
      onNavigateToTab: (index) => _navigateToTab(index),
    );
  }

  void _handleStartStrategy() {
    // Check if any strategy is running
    final engine = context.read<StrategyEngine>();
    final activeStrategy = engine.allStrategies.firstWhere((s) => s.isEnabled,
        orElse: () => GhostTrendStrategy()..isEnabled = false);

    Navigator.pop(context);

    if (activeStrategy.isEnabled) {
      // Show Dashboard Sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _StrategyDashboardSheet(
          strategyName: activeStrategy.name,
          currentPnL: 124.50, // Mock PnL
          onStop: () {
            // Stop logic
            final engine = context.read<StrategyEngine>();
            engine.toggleStrategy(activeStrategy.id, false);
          },
        ),
      );
    } else {
      Navigator.pop(context);
      _navigateToTab(0); // Lab tab
    }
  }

  void _handleAiStrategy() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIStrategyGeneratorScreen()),
    );
  }

  void _handleFindSymbol() {
    showSearch(
      context: context,
      delegate: _VxSymbolSearchDelegate(),
    );
  }

  void _handleSetAlert() {
    final dashboard = context.read<DashboardProvider>();
    final ticker = dashboard.getTicker('BTCUSDT');
    final price = ticker?.closePrice ?? 43250.50;

    showDialog(
      context: context,
      builder: (context) => _SetAlertDialog(
        symbol: 'BTC/USDT',
        currentPrice: price,
      ),
    );
  }

  void _handleOpenTerminal() {
    Navigator.pop(context);
    _navigateToTab(1); // Terminal tab
  }

  void _navigateToTab(int index) {
    VxNavigationHelper.switchTab(index);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _CommandTile extends StatelessWidget {
  final _Command command;
  final VoidCallback onTap;

  const _CommandTile({required this.command, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: command.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: command.color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(command.icon, color: command.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            command.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (command.proOnly) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: VxColors.neonPurple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: VxColors.neonPurple,
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: VxColors.neonPurple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        command.description,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Command {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback action;
  final bool proOnly = false; // or remove this line if unused

  _Command({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.action,
  });
}

// --- Helper Classes (Strategy Dashboard, Alerts, Pro, Search) ---

/// Strategy Dashboard Mini-Sheet (when strategy is running)
class _StrategyDashboardSheet extends StatelessWidget {
  final String strategyName;
  final double currentPnL;
  final VoidCallback onStop;

  const _StrategyDashboardSheet({
    required this.strategyName,
    required this.currentPnL,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isProfitable = currentPnL >= 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: VxColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: VxColors.neonGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: VxColors.neonGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VxColors.neonGreen.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strategyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'LIVE SESSION',
                        style: TextStyle(
                          color: VxColors.neonGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // PnL Display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isProfitable ? VxColors.neonGreen : VxColors.neonRed)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isProfitable ? VxColors.neonGreen : VxColors.neonRed)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'SESSION P&L',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${isProfitable ? '+' : ''}\$${currentPnL.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isProfitable ? VxColors.neonGreen : VxColors.neonRed,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: VxTypography.monoFamily,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Controls
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Pause Toggle (simulated)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'PAUSE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: false,
                      onChanged: (_) {},
                      activeThumbColor: VxColors.warning,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Emergency Stop Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      _showStopConfirmation(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VxColors.neonRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_circle, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'EMERGENCY STOP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStopConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: VxColors.neonRed, size: 24),
            SizedBox(width: 12),
            Text('Stop Strategy?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will immediately halt all automated trading. Open positions will remain.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onStop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: VxColors.neonRed),
            child: const Text('STOP NOW'),
          ),
        ],
      ),
    );
  }
}

/// Set Alert Dialog with auto-fill and one-tap presets
class _SetAlertDialog extends StatefulWidget {
  final String symbol;
  final double currentPrice;

  const _SetAlertDialog({
    required this.symbol,
    required this.currentPrice,
  });

  @override
  State<_SetAlertDialog> createState() => _SetAlertDialogState();
}

class _SetAlertDialogState extends State<_SetAlertDialog> {
  late TextEditingController _priceController;
  String _condition = 'above';

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.currentPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: VxColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.notifications_active, color: VxColors.warning, size: 24),
          SizedBox(width: 12),
          Text('Set Price Alert', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Symbol display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VxColors.neonCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  'Symbol:',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.symbol,
                  style: TextStyle(
                    color: VxColors.neonCyan,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: VxTypography.monoFamily,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Condition selector
          Row(
            children: [
              Expanded(
                child: _buildConditionChip('above', 'Above'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildConditionChip('below', 'Below'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Price input
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: VxTypography.monoFamily,
            ),
            decoration: InputDecoration(
              labelText: 'Target Price',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixText: '\$ ',
              prefixStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: VxColors.warning.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: VxColors.warning),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick presets
          const Text(
            'QUICK PRESETS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPresetButton('+5%', () {
                  final p = double.tryParse(_priceController.text) ??
                      widget.currentPrice;
                  _priceController.text = (p * 1.05).toStringAsFixed(2);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton('-5%', () {
                  final p = double.tryParse(_priceController.text) ??
                      widget.currentPrice;
                  _priceController.text = (p * 0.95).toStringAsFixed(2);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton('+10%', () {
                  final p = double.tryParse(_priceController.text) ??
                      widget.currentPrice;
                  _priceController.text = (p * 1.10).toStringAsFixed(2);
                }),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
            _createAlert();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: VxColors.warning,
            foregroundColor: Colors.black,
          ),
          child: const Text('SET ALERT',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildConditionChip(String value, String label) {
    final isSelected = _condition == value;
    return GestureDetector(
      onTap: () => setState(() => _condition = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? VxColors.warning.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? VxColors.warning : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? VxColors.warning : Colors.white54,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: VxColors.warning.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: VxColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _createAlert() async {
    final price = double.tryParse(_priceController.text) ?? widget.currentPrice;

    final alert = PriceAlert(
      symbol: widget.symbol.replaceAll('/', '').toUpperCase(),
      targetPrice: price,
      condition:
          _condition == 'above' ? AlertCondition.above : AlertCondition.below,
    );

    await context.read<AlertEngine>().createAlert(alert);

    // Notification is handled by the engine, so we don't need to show snackbar here manually.
    // engine calls _notifications.showSuccess(...)
  }
}

/// Pro Upgrade Interstitial (Paywall Simulation)
class _ProUpgradeDialog extends StatefulWidget {
  @override
  State<_ProUpgradeDialog> createState() => _ProUpgradeDialogState();
}

class _ProUpgradeDialogState extends State<_ProUpgradeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeController.forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = _shakeController.value < 0.5
            ? _shakeController.value * 20
            : (1 - _shakeController.value) * 20;

        return Transform.translate(
          offset: Offset(shake - 10, 0),
          child: child,
        );
      },
      child: AlertDialog(
        backgroundColor: VxColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock icon with gold shimmer
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade300,
                    Colors.amber.shade600,
                  ],
                ),
              ),
              child: const Icon(Icons.lock, color: Colors.black, size: 40),
            ),

            const SizedBox(height: 24),

            const Text(
              'Unlock Pro Features',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Access the full Analyst Workspace with advanced charting, raw logs, and strategy parameters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Features list
            _buildFeature(Icons.analytics, 'Advanced Charts & Indicators'),
            _buildFeature(Icons.code, 'Raw Execution Logs'),
            _buildFeature(Icons.tune, 'Custom Strategy Parameters'),

            const SizedBox(height: 24),

            // Upgrade button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  appRouter.push('/subscription');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.neonPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'UPGRADE TO PRO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: VxColors.neonPurple, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Symbol Search Delegate with Recent & Trending
class _VxSymbolSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> _allSymbols = [
    {'symbol': 'BTC/USDT', 'name': 'Bitcoin', 'price': 43250.50, 'change': 2.4},
    {
      'symbol': 'ETH/USDT',
      'name': 'Ethereum',
      'price': 2280.75,
      'change': -1.2
    },
    {'symbol': 'SOL/USDT', 'name': 'Solana', 'price': 98.30, 'change': 5.7},
    {'symbol': 'AAPL', 'name': 'Apple Inc.', 'price': 178.45, 'change': 0.8},
    {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'price': 245.32, 'change': -2.1},
  ];

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VxColors.background,
      appBarTheme:
          const AppBarTheme(backgroundColor: VxColors.surface, elevation: 0),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = query.isEmpty
        ? _allSymbols
        : _allSymbols
            .where((m) =>
                m['symbol'].toLowerCase().contains(query.toLowerCase()) ||
                m['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();

    return Container(
      color: VxColors.background,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final market = results[index];
          final isPositive = market['change'] >= 0;

          return ListTile(
            leading: const Icon(
              Icons.currency_bitcoin,
              color: VxColors.neonCyan,
            ),
            title: Text(
              market['symbol'],
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              market['name'],
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${market['price']}',
                  style: TextStyle(
                      color: Colors.white70, fontFamily: VxTypography.monoFamily),
                ),
                Text(
                  '${isPositive ? '+' : ''}${market['change']}%',
                  style: TextStyle(
                    color: isPositive ? VxColors.neonGreen : VxColors.neonRed,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onTap: () {
              close(context, market['symbol']);
              VxTradeSheet.show(
                context,
                symbol: market['symbol'],
                currentPrice: market['price'],
                candles: [],
              );
            },
          );
        },
      ),
    );
  }
}
