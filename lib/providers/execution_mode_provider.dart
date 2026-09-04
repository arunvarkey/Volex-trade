import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volex_terminal/engine/execution_manager.dart';

/// Execution Mode: Paper Trading vs Live Trading
enum ExecutionMode {
  paper,
  live;

  String get label =>
      this == ExecutionMode.paper ? 'Paper Trading' : 'Live Trading';

  bool get isPaper => this == ExecutionMode.paper;
  bool get isLive => this == ExecutionMode.live;
}

/// Global state manager for Live vs Paper trading mode
class ExecutionModeProvider extends ChangeNotifier {
  final ExecutionManager? _executionManager;
  final ExecutionMode _mode = ExecutionMode.paper; // FORCED PAPER FOR V1

  ExecutionModeProvider([this._executionManager]) {
    _loadPreference();
  }

  ExecutionMode get mode => _mode;
  bool get isPaperMode => _mode == ExecutionMode.paper;
  bool get isLiveMode => _mode == ExecutionMode.live;

  Future<void> _loadPreference() async {
    // For V1, we always default to paper for safety.
    _syncToManager();
    notifyListeners();
  }

  Future<void> setMode(ExecutionMode newMode) async {
    // DISABLED FOR V1 RELEASE
    _syncToManager();
    notifyListeners();
  }

  void _syncToManager() {
    if (_executionManager != null) {
      // FORCED FALSE FOR V1
      _executionManager.enableLiveMode(false);
    }
  }

  Future<void> toggleMode() async {
    // NO-OP FOR V1
  }

  /// Explain why live mode is unavailable.
  ///
  /// This used to claim live trading was "undergoing final safety audits and
  /// will be enabled in a future update" — no such audit exists and nothing
  /// in this app can place a real order. Promising a shipping date the
  /// project does not have is the kind of claim a finance app should not
  /// make, so it now says plainly what the app is.
  Future<bool> requestLiveModeSwitch(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('SIMULATOR ONLY',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Volex is a trading simulator. It trades virtual money against real '
          'market prices and does not connect to a broker or place real '
          'orders, so there is no live mode to switch to.\n\n'
          'Everything you practise here — sizing, stops, journalling, '
          'backtests — carries over to whatever platform you eventually trade '
          'on for real.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00FFAA))),
          ),
        ],
      ),
    );
    return false;
  }
}

/// Extension for easy access in context
extension ExecutionModeContext on BuildContext {
  ExecutionMode get executionMode => read<ExecutionModeProvider>().mode;
  bool get isPaperMode => read<ExecutionModeProvider>().isPaperMode;
  bool get isLiveMode => read<ExecutionModeProvider>().isLiveMode;
}
