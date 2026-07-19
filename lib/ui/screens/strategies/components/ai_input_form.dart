import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';

class AIInputForm extends StatelessWidget {
  final TextEditingController descriptionController;
  final TextEditingController symbolController;
  final String timeframe;
  final double riskTolerance;
  final bool isGenerating;
  final Function(String) onTimeframeChanged;
  final Function(double) onRiskRiskToleranceChanged;
  final bool canUseCompanyKey;
  final bool useCompanyKey;
  final ValueChanged<bool> onUseCompanyKeyChanged;
  final VoidCallback onGenerate;

  const AIInputForm({
    super.key,
    required this.descriptionController,
    required this.symbolController,
    required this.timeframe,
    required this.riskTolerance,
    required this.isGenerating,
    required this.onTimeframeChanged,
    required this.onRiskRiskToleranceChanged,
    this.canUseCompanyKey = false,
    this.useCompanyKey = false,
    required this.onUseCompanyKeyChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(),
          const SizedBox(height: 32),
          _buildDescriptionInput(),
          const SizedBox(height: 24),
          _buildSymbolInput(),
          const SizedBox(height: 24),
          _buildTimeframeSelector(),
          const SizedBox(height: 24),
          _buildRiskToleranceSlider(),
          const SizedBox(height: 24),
          if (canUseCompanyKey) _buildProModeToggle(),
          const SizedBox(height: 32),
          _buildGenerateButton(),
          const SizedBox(height: 24),
          _buildExamplesSection(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: VxColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Describe Your Strategy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Our AI will transform your trading idea into a complete, backtested strategy in seconds.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STRATEGY DESCRIPTION',
          style: TextStyle(
            color: VxColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText:
                'Example: Buy when RSI is oversold and price breaks above 20-day moving average with high volume',
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
            filled: true,
            fillColor: VxColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: VxColors.neonCyan, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSymbolInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRADING PAIR',
          style: TextStyle(
            color: VxColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: symbolController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'BTCUSDT',
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.white54),
            filled: true,
            fillColor: VxColors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    final timeframes = ['1m', '5m', '15m', '1h', '4h', '1d'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIMEFRAME',
          style: TextStyle(
            color: VxColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: timeframes.map((tf) {
            final isSelected = timeframe == tf;
            return InkWell(
              onTap: () => onTimeframeChanged(tf),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? VxColors.neonCyan.withValues(alpha: 0.2)
                      : VxColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? VxColors.neonCyan : Colors.white10,
                  ),
                ),
                child: Text(
                  tf,
                  style: TextStyle(
                    color: isSelected ? VxColors.neonCyan : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRiskToleranceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RISK TOLERANCE',
              style: TextStyle(
                color: VxColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            Text(
              _getRiskLabel(riskTolerance),
              style: TextStyle(
                color: _getRiskColor(riskTolerance),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _getRiskColor(riskTolerance),
            inactiveTrackColor: VxColors.surface,
            thumbColor: _getRiskColor(riskTolerance),
            overlayColor: _getRiskColor(riskTolerance).withValues(alpha: 0.2),
          ),
          child: Slider(
            value: riskTolerance,
            onChanged: (value) => onRiskRiskToleranceChanged(value),
            min: 0,
            max: 1,
            divisions: 4,
          ),
        ),
      ],
    );
  }

  String _getRiskLabel(double value) {
    if (value < 0.2) return 'VERY LOW';
    if (value < 0.4) return 'LOW';
    if (value < 0.6) return 'MODERATE';
    if (value < 0.8) return 'HIGH';
    return 'VERY HIGH';
  }

  Color _getRiskColor(double value) {
    if (value < 0.4) return VxColors.neonGreen;
    if (value < 0.7) return VxColors.warning;
    return VxColors.neonRed;
  }

  Widget _buildProModeToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VxColors.neonCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: VxColors.neonCyan),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRO MODE ENABLED',
                  style: TextStyle(
                    color: VxColors.neonCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Use Volex key (Unlimited)',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: useCompanyKey,
            onChanged: onUseCompanyKeyChanged,
            activeColor: VxColors.neonCyan,
            activeTrackColor: VxColors.neonCyan.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isGenerating ? null : onGenerate,
        style: ElevatedButton.styleFrom(
          backgroundColor: VxColors.neonCyan,
          foregroundColor: VxColors.deepBlack,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isGenerating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VxColors.deepBlack,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('GENERATING...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'GENERATE STRATEGY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildExamplesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXAMPLE STRATEGIES',
          style: TextStyle(
            color: VxColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildExampleCard(
          'RSI Reversal',
          'Buy when RSI drops below 30 and starts climbing',
        ),
        const SizedBox(height: 8),
        _buildExampleCard(
          'Breakout Trading',
          'Buy when price breaks above 50-day high with volume',
        ),
        const SizedBox(height: 8),
        _buildExampleCard(
          'Mean Reversion',
          'Buy when price is 2 standard deviations below moving average',
        ),
      ],
    );
  }

  Widget _buildExampleCard(String title, String description) {
    return InkWell(
      onTap: () => descriptionController.text = description,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VxColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline,
                color: VxColors.neonCyan, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }
}
