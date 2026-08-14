import 'package:flutter/material.dart';
import '../design_system/vx_colors.dart';
import '../../engine/wizard/script_templates.dart';
import '../screens/script_editor_screen.dart';
import 'package:google_fonts/google_fonts.dart';

enum StrategyType { trend, reversion }

class SmartStrategyWizard extends StatefulWidget {
  const SmartStrategyWizard({super.key});

  @override
  State<SmartStrategyWizard> createState() => _SmartStrategyWizardState();
}

class _SmartStrategyWizardState extends State<SmartStrategyWizard> {
  final PageController _pageController = PageController();

  // State
  StrategyType _selectedType = StrategyType.trend;

  // Trend Params
  double _emaPeriod = 20;

  // Reversion Params
  double _rsiPeriod = 14;
  double _rsiBuy = 30;
  double _rsiSell = 70;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: VxColors.deepBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: VxColors.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Smart Builder",
                  style: GoogleFonts.dmSans(
                    color: VxColors.neonCyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white10),

            // Steps
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Type(),
                  _buildStep2Config(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Type() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "How do you want to trade?",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 24),
        _buildOptionCard(
          title: "Follow the Trend",
          subtitle:
              "Buy when price is above average (EMA). Good for crypto bull runs.",
          icon: Icons.trending_up,
          color: VxColors.neonCyan,
          isSelected: _selectedType == StrategyType.trend,
          onTap: () => setState(() => _selectedType = StrategyType.trend),
        ),
        const SizedBox(height: 16),
        _buildOptionCard(
          title: "Buy the Dip",
          subtitle:
              "Buy when RSI is low (Oversold). Good for sideways markets.",
          icon: Icons.waves,
          color: VxColors.neonMagenta,
          isSelected: _selectedType == StrategyType.reversion,
          onTap: () => setState(() => _selectedType = StrategyType.reversion),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: VxColors.neonCyan,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text("NEXT STEP"),
        ),
      ],
    );
  }

  Widget _buildStep2Config() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _selectedType == StrategyType.trend
              ? "Configure Trend"
              : "Configure Reversion",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 32),
        if (_selectedType == StrategyType.trend) ...[
          _buildSlider("EMA Period", _emaPeriod, 10, 200,
              (val) => setState(() => _emaPeriod = val)),
          const Text("Lower = Faster, Higher = Smoother",
              style: TextStyle(color: Colors.grey, fontSize: 10)),
        ] else ...[
          _buildSlider("RSI Period", _rsiPeriod, 2, 30,
              (val) => setState(() => _rsiPeriod = val)),
          _buildSlider("Buy Below", _rsiBuy, 5, 45,
              (val) => setState(() => _rsiBuy = val)),
          _buildSlider("Sell Above", _rsiSell, 55, 95,
              (val) => setState(() => _rsiSell = val)),
        ],
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _generateAndOpen,
          icon: const Icon(Icons.code),
          label: const Text("GENERATE CODE"),
          style: ElevatedButton.styleFrom(
            backgroundColor: VxColors.neonGreen,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
        TextButton(
          onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300), curve: Curves.ease),
          child: const Text("BACK", style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.white10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      Function(double) onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(value.toStringAsFixed(0),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: VxColors.neonCyan,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _nextStep() {
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  void _generateAndOpen() {
    String script = "";
    if (_selectedType == StrategyType.trend) {
      script = ScriptTemplates.generateEmaTrend(
        fastPeriod: _emaPeriod.toInt(),
        slowPeriod: 0, // Unused in this template
      );
    } else {
      script = ScriptTemplates.generateRsiReversion(
        period: _rsiPeriod.toInt(),
        buyThreshold: _rsiBuy,
        sellThreshold: _rsiSell,
      );
    }

    Navigator.pop(context); // Close Wizard

    // Open Editor with Script
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScriptEditorScreen(initialScript: script),
      ),
    );
  }
}
