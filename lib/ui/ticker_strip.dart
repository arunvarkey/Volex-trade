import 'package:flutter/material.dart';
import '../engine/chart_controller.dart';
import '../domain/symbol_info.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';

class TickerStrip extends StatelessWidget {
  final ChartController controller;
  final String activeSymbol;
  final Function(SymbolInfo) onSymbolChanged;

  const TickerStrip({
    super.key,
    required this.controller,
    required this.activeSymbol,
    required this.onSymbolChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final candle = controller.allCandles.isNotEmpty
            ? controller.allCandles.last
            : null;
        final price = candle?.close.toStringAsFixed(2) ?? "---";
        final open = candle?.open ?? 0;
        final close = candle?.close ?? 0;

        final change = close - open;
        final percent = open != 0 ? (change / open) * 100 : 0.0;
        final isUp = change >= 0;
        final color = isUp ? VxColors.neonGreen : VxColors.neonRed;

        return Container(
          height: 32,
          color: VxColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              DropdownButton<String>(
                value: activeSymbol.toUpperCase(),
                dropdownColor: VxColors.surface,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down,
                    color: Colors.white24, size: 14),
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    final info = SymbolRegistry.supportedSymbols
                        .firstWhere((s) => s.symbol == newValue);
                    onSymbolChanged(info);
                  }
                },
                items: SymbolRegistry.supportedSymbols
                    .map<DropdownMenuItem<String>>((SymbolInfo info) {
                  return DropdownMenuItem<String>(
                    value: info.symbol,
                    child: VxText.monoBold(info.displayName, fontSize: 12),
                  );
                }).toList(),
              ),
              const SizedBox(width: 16),
              VxText.monoBold(price, fontSize: 13),
              const SizedBox(width: 8),
              Icon(isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: color, size: 14),
              VxText.mono(
                "${change.toStringAsFixed(2)} (${percent.toStringAsFixed(2)}%)",
                color: color,
                fontSize: 11,
              ),
              const Spacer(),
              VxText.mono("VOL 249M", color: Colors.white24, fontSize: 10),
            ],
          ),
        );
      },
    );
  }
}
