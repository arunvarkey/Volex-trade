// lib/core/config/app_mode.dart
import 'package:flutter/material.dart';
import '../../ui/design_system/vx_colors.dart';

enum AppMode {
  backtest, // Historical simulation
  paper, // Real-time paper trading (NEW)
  testnet, // Live execution on Binance testnet
  live, // Real money (requires extreme caution)
}

extension AppModeExtension on AppMode {
  String get displayName {
    switch (this) {
      case AppMode.backtest:
        return 'Backtest';
      case AppMode.paper:
        return 'Paper Trading';
      case AppMode.testnet:
        return 'Testnet';
      case AppMode.live:
        return 'LIVE';
    }
  }

  Color get themeColor {
    switch (this) {
      case AppMode.backtest:
        return VxColors.neonPurple;
      case AppMode.paper:
        return VxColors.neonCyan;
      case AppMode.testnet:
        return VxColors.neonGreen;
      case AppMode.live:
        return VxColors.neonRed;
    }
  }

  bool get isSimulated => this == AppMode.backtest || this == AppMode.paper;
  bool get requiresApiKeys => this == AppMode.testnet || this == AppMode.live;
}
