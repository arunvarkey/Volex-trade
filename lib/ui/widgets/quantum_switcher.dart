import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/widgets/vx_holographic_card.dart';
import 'package:volex_terminal/services/haptic_service.dart';

/// QuantumSwitcher - A high-performance command palette for symbol switching.
class QuantumSwitcher extends StatefulWidget {
  final Function(String) onSymbolSelected;

  const QuantumSwitcher({
    super.key,
    required this.onSymbolSelected,
  });

  static void show(BuildContext context, Function(String) onSymbolSelected) {
    HapticService.instance.medium();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => QuantumSwitcher(onSymbolSelected: onSymbolSelected),
    );
  }

  @override
  State<QuantumSwitcher> createState() => _QuantumSwitcherState();
}

class _QuantumSwitcherState extends State<QuantumSwitcher> {
  final _searchController = TextEditingController();
  final List<String> _allSymbols = [
    'BTCUSDT',
    'ETHUSDT',
    'SOLUSDT',
    'BNBUSDT',
    'ADAUSDT',
    'XRPUSDT',
    'DOTUSDT',
    'LINKUSDT',
    'AVAXUSDT',
    'MATICUSDT'
  ];
  List<String> _filteredSymbols = [];

  @override
  void initState() {
    super.initState();
    _filteredSymbols = _allSymbols;
  }

  void _filterSymbols(String query) {
    setState(() {
      _filteredSymbols = _allSymbols
          .where((s) => s.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: VxHolographicCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              autofocus: true,
              style: VxTypography.body.copyWith(color: Colors.white),
              cursorColor: VxColors.neonCyan,
              onChanged: _filterSymbols,
              decoration: InputDecoration(
                hintText: 'COMMAND: SEARCH_SYMBOL...',
                hintStyle: VxTypography.body.copyWith(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: VxColors.neonCyan),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const Divider(color: Colors.white10),

            // Symbol List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredSymbols.length,
                itemBuilder: (context, index) {
                  final symbol = _filteredSymbols[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading:
                        const Icon(Icons.token_outlined, color: Colors.white38),
                    title: Text(
                      symbol,
                      style: VxTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.white12),
                    onTap: () {
                      HapticService.instance.selection();
                      widget.onSymbolSelected(symbol);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),

            if (_filteredSymbols.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'NO_MATCH_FOUND',
                  style: VxTypography.caption.copyWith(color: Colors.white24),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
