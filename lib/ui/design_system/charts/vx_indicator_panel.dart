import 'package:flutter/material.dart';
import '../vx_colors.dart';

/// Model for a technical indicator
class TechnicalIndicator {
  final String id;
  final String name;
  final String shortName;
  final Color color;
  final IconData icon;
  final List<IndicatorParam> params;
  bool isEnabled;

  TechnicalIndicator({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.icon,
    this.params = const [],
    this.isEnabled = false,
  });

  TechnicalIndicator copyWith({bool? isEnabled, List<IndicatorParam>? params}) {
    return TechnicalIndicator(
      id: id,
      name: name,
      shortName: shortName,
      color: color,
      icon: icon,
      params: params ?? this.params,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class IndicatorParam {
  final String name;
  final int value;
  final int min;
  final int max;

  IndicatorParam({
    required this.name,
    required this.value,
    this.min = 1,
    this.max = 200,
  });

  IndicatorParam copyWith({int? value}) {
    return IndicatorParam(
      name: name,
      value: value ?? this.value,
      min: min,
      max: max,
    );
  }
}

/// Predefined indicators
class TechnicalIndicators {
  static final List<TechnicalIndicator> defaults = [
    TechnicalIndicator(
      id: 'sma',
      name: 'Simple Moving Average',
      shortName: 'SMA',
      color: VxColors.neonCyan,
      icon: Icons.show_chart,
      params: [IndicatorParam(name: 'Period', value: 20, min: 5, max: 200)],
    ),
    TechnicalIndicator(
      id: 'ema',
      name: 'Exponential Moving Average',
      shortName: 'EMA',
      color: VxColors.neonPurple,
      icon: Icons.trending_up,
      params: [IndicatorParam(name: 'Period', value: 50, min: 5, max: 200)],
    ),
    TechnicalIndicator(
      id: 'bb',
      name: 'Bollinger Bands',
      shortName: 'BB',
      color: const Color(0xFFFFAA00),
      icon: Icons.show_chart,
      params: [
        IndicatorParam(name: 'Period', value: 20, min: 5, max: 100),
        IndicatorParam(name: 'Std Dev', value: 2, min: 1, max: 5),
      ],
    ),
    TechnicalIndicator(
      id: 'rsi',
      name: 'Relative Strength Index',
      shortName: 'RSI',
      color: VxColors.neonPurple,
      icon: Icons.insights,
      params: [IndicatorParam(name: 'Period', value: 14, min: 5, max: 50)],
    ),
    TechnicalIndicator(
      id: 'macd',
      name: 'MACD',
      shortName: 'MACD',
      color: VxColors.neonGreen,
      icon: Icons.area_chart,
      params: [
        IndicatorParam(name: 'Fast', value: 12, min: 5, max: 50),
        IndicatorParam(name: 'Slow', value: 26, min: 10, max: 100),
        IndicatorParam(name: 'Signal', value: 9, min: 5, max: 30),
      ],
    ),
  ];
}

/// Indicator Control Panel - Floating overlay on chart
class VxIndicatorPanel extends StatefulWidget {
  final List<TechnicalIndicator> indicators;
  final Function(List<TechnicalIndicator>) onIndicatorsChanged;

  const VxIndicatorPanel({
    super.key,
    required this.indicators,
    required this.onIndicatorsChanged,
  });

  @override
  State<VxIndicatorPanel> createState() => _VxIndicatorPanelState();
}

class _VxIndicatorPanelState extends State<VxIndicatorPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final activeIndicators =
        widget.indicators.where((i) => i.isEnabled).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Compact view showing active indicators
        if (!_isExpanded && activeIndicators.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: VxColors.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Wrap(
              spacing: 8,
              children: activeIndicators.map((indicator) {
                return GestureDetector(
                  onTap: () => _showIndicatorSettings(indicator),
                  child: Chip(
                    label: Text(
                      indicator.shortName,
                      style: TextStyle(
                        color: indicator.color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: indicator.color.withOpacity(0.1),
                    deleteIcon:
                        Icon(Icons.close, size: 14, color: indicator.color),
                    onDeleted: () => _toggleIndicator(indicator),
                    side: BorderSide(color: indicator.color.withOpacity(0.3)),
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 8),

        // Add indicator button
        FloatingActionButton.small(
          heroTag: 'indicators',
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          backgroundColor: VxColors.surface,
          child: Icon(
            _isExpanded ? Icons.close : Icons.add_chart,
            color: VxColors.neonCyan,
          ),
        ),

        // Expanded indicator selector
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 280,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  0.5, // Dynamic height limit
            ),
            decoration: BoxDecoration(
              color: VxColors.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VxColors.neonCyan.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.show_chart,
                          color: VxColors.neonCyan, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'INDICATORS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicator list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.indicators.length,
                    itemBuilder: (context, index) {
                      final indicator = widget.indicators[index];
                      return _IndicatorTile(
                        indicator: indicator,
                        onToggle: () => _toggleIndicator(indicator),
                        onSettings: () => _showIndicatorSettings(indicator),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _toggleIndicator(TechnicalIndicator indicator) {
    final updatedIndicators = widget.indicators.map((i) {
      if (i.id == indicator.id) {
        return i.copyWith(isEnabled: !i.isEnabled);
      }
      return i;
    }).toList();
    widget.onIndicatorsChanged(updatedIndicators);
  }

  void _showIndicatorSettings(TechnicalIndicator indicator) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _IndicatorSettingsSheet(
        indicator: indicator,
        onSave: (updated) {
          final updatedIndicators = widget.indicators.map((i) {
            return i.id == updated.id ? updated : i;
          }).toList();
          widget.onIndicatorsChanged(updatedIndicators);
        },
      ),
    );
  }
}

class _IndicatorTile extends StatelessWidget {
  final TechnicalIndicator indicator;
  final VoidCallback onToggle;
  final VoidCallback onSettings;

  const _IndicatorTile({
    required this.indicator,
    required this.onToggle,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: indicator.isEnabled
            ? indicator.color.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: indicator.isEnabled
              ? indicator.color.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  indicator.icon,
                  color: indicator.color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        indicator.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (indicator.params.isNotEmpty)
                        Text(
                          indicator.params
                              .map((p) => '${p.name}: ${p.value}')
                              .join(', '),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                if (indicator.isEnabled)
                  IconButton(
                    icon: const Icon(Icons.settings, size: 16),
                    color: Colors.white38,
                    onPressed: onSettings,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                Switch(
                  value: indicator.isEnabled,
                  onChanged: (_) => onToggle(),
                  activeColor: indicator.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndicatorSettingsSheet extends StatefulWidget {
  final TechnicalIndicator indicator;
  final Function(TechnicalIndicator) onSave;

  const _IndicatorSettingsSheet({
    required this.indicator,
    required this.onSave,
  });

  @override
  State<_IndicatorSettingsSheet> createState() =>
      _IndicatorSettingsSheetState();
}

class _IndicatorSettingsSheetState extends State<_IndicatorSettingsSheet> {
  late List<IndicatorParam> _params;

  @override
  void initState() {
    super.initState();
    _params = widget.indicator.params.map((p) => p).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: VxColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: widget.indicator.color.withOpacity(0.3)),
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
                Icon(widget.indicator.icon, color: widget.indicator.color),
                const SizedBox(width: 12),
                Text(
                  widget.indicator.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Parameters
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _params.length,
              itemBuilder: (context, index) {
                final param = _params[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          param.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          param.value.toString(),
                          style: TextStyle(
                            color: widget.indicator.color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: widget.indicator.color,
                        inactiveTrackColor: Colors.white10,
                        thumbColor: widget.indicator.color,
                        overlayColor: widget.indicator.color.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: param.value.toDouble(),
                        min: param.min.toDouble(),
                        max: param.max.toDouble(),
                        divisions: param.max - param.min,
                        onChanged: (value) {
                          setState(() {
                            _params[index] =
                                param.copyWith(value: value.toInt());
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final updated = widget.indicator.copyWith(params: _params);
                  widget.onSave(updated);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.indicator.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'APPLY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
