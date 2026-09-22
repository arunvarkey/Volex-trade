// lib/features/simulator/strategy_builder/screens/template_config_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../ui/design_system/vx_colors.dart';
import '../models/strategy_template.dart';
import '../models/template_parameter.dart';
import '../services/strategy_validator.dart';
import '../services/strategy_repository.dart';
import 'package:volex_terminal/features/subscriptions/services/subscription_service.dart';

class TemplateConfigScreen extends StatefulWidget {
  final StrategyTemplate template;

  const TemplateConfigScreen({super.key, required this.template});

  @override
  State<TemplateConfigScreen> createState() => _TemplateConfigScreenState();
}

class _TemplateConfigScreenState extends State<TemplateConfigScreen> {
  late Map<String, dynamic> _values;
  final _nameController = TextEditingController();
  final _validator = StrategyValidator();
  final _repository = GetIt.I<StrategyRepository>();

  @override
  void initState() {
    super.initState();

    // Initialize with default values
    _values = {
      'symbol': 'BTCUSDT',
      'timeframe': '1h',
      for (var param in widget.template.parameters)
        param.id: param.defaultValue,
    };

    _nameController.text = 'My ${widget.template.name}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      appBar: AppBar(
        backgroundColor: VxColors.deepBlack,
        title: Text(
          'Configure ${widget.template.name}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        // Extra bottom inset so the CTA clears the system navigation bar
        // instead of rendering underneath it.
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template info card
            _buildInfoCard(),

            const SizedBox(height: 24),

            // Strategy name
            _buildSectionHeader('STRATEGY NAME'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., BTC Scalper',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                      BorderSide(color: VxColors.neonCyan.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(color: VxColors.neonCyan, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Symbol selection
            _buildSectionHeader('SYMBOL'),
            const SizedBox(height: 8),
            _buildSymbolSelector(),

            const SizedBox(height: 24),

            // Timeframe selection
            _buildSectionHeader('TIMEFRAME'),
            const SizedBox(height: 8),
            _buildTimeframeSelector(),

            const SizedBox(height: 24),

            // Dynamic parameters
            _buildSectionHeader('PARAMETERS'),
            const SizedBox(height: 12),
            ...widget.template.parameters.map((param) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildParameterControl(param),
                )),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _validate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VxColors.neonGreen,
                      foregroundColor: VxColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Validate & Backtest',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VxColors.neonCyan.withValues(alpha: 0.1),
            VxColors.neonCyan.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: VxColors.neonCyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.template.icon, color: VxColors.neonCyan, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.template.name.toUpperCase(),
                  style: const TextStyle(
                    color: VxColors.neonCyan,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.template.description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
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

  Widget _buildSymbolSelector() {
    final symbols = StrategyValidator.allowedSymbols;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symbols.map((symbol) {
        final isSelected = _values['symbol'] == symbol;
        return GestureDetector(
          onTap: () => setState(() => _values['symbol'] = symbol),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? VxColors.neonCyan.withValues(alpha: 0.2)
                  : Colors.grey[900],
              border: Border.all(
                color: isSelected ? VxColors.neonCyan : Colors.grey[800]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              symbol,
              style: TextStyle(
                color: isSelected ? VxColors.neonCyan : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeframeSelector() {
    final timeframes = StrategyValidator.allowedTimeframes;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: timeframes.map((tf) {
        final isSelected = _values['timeframe'] == tf;
        return GestureDetector(
          onTap: () => setState(() => _values['timeframe'] = tf),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? VxColors.neonCyan.withValues(alpha: 0.2)
                  : Colors.grey[900],
              border: Border.all(
                color: isSelected ? VxColors.neonCyan : Colors.grey[800]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tf,
              style: TextStyle(
                color: isSelected ? VxColors.neonCyan : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParameterControl(TemplateParameter param) {
    if (param is NumericParameter) {
      return _buildNumericSlider(param);
    } else if (param is DropdownParameter) {
      return _buildDropdown(param);
    }
    return const SizedBox.shrink();
  }

  Widget _buildNumericSlider(NumericParameter param) {
    final value = _values[param.id] as num;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              param.label.toUpperCase(),
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: VxColors.neonCyan.withValues(alpha: 0.2),
                border: Border.all(color: VxColors.neonCyan),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                param.decimals != null
                    ? value.toStringAsFixed(param.decimals!)
                    : value.toString(),
                style: const TextStyle(
                  color: VxColors.neonCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        if (param.description != null) ...[
          const SizedBox(height: 4),
          Text(
            param.description!,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],

        const SizedBox(height: 8),

        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: VxColors.neonCyan,
            inactiveTrackColor: Colors.grey[800],
            thumbColor: VxColors.neonCyan,
            overlayColor: VxColors.neonCyan.withValues(alpha: 0.2),
            valueIndicatorColor: VxColors.neonCyan,
          ),
          child: Slider(
            value: value.toDouble(),
            min: param.min.toDouble(),
            max: param.max.toDouble(),
            divisions: param.decimals != null
                ? ((param.max - param.min) * 10).toInt()
                : (param.max - param.min).toInt(),
            label: param.decimals != null
                ? value.toStringAsFixed(param.decimals!)
                : value.toString(),
            onChanged: (newValue) {
              setState(() {
                _values[param.id] = param.decimals != null
                    ? double.parse(newValue.toStringAsFixed(param.decimals!))
                    : newValue.toInt();
              });
            },
          ),
        ),

        // Min/Max labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              param.min.toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
            Text(
              param.max.toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown(DropdownParameter param) {
    final value = _values[param.id] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          param.label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        if (param.description != null) ...[
          const SizedBox(height: 4),
          Text(
            param.description!,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border.all(color: Colors.grey[800]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            items: param.options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _values[param.id] = newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  void _validate() async {
    // Create strategy
    final strategy = widget.template.instantiate({
      ..._values,
      'name': _nameController.text.trim(),
    });

    // Validate
    final result = _validator.validate(strategy);

    if (!result.isValid) {
      _showValidationErrors(result.errors);
      return;
    }

    // Check subscription limit (Soft Gate)
    final canGenerate =
        await GetIt.I<SubscriptionService>().checkAndTrackStrategyGeneration();
    if (!canGenerate) {
      if (mounted) {
        _showUpgradeDialog(
            'You\'ve saved your 3 free strategies today. Upgrade to Premium for unlimited strategies.');
      }
      return;
    }

    // Save
    await _repository.save(strategy);

    // Navigate to backtest
    if (mounted) {
      context.push('/lab/backtest/config', extra: strategy);
    }
  }

  void _showValidationErrors(List errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.deepBlack,
        title: const Text(
          'VALIDATION FAILED',
          style: TextStyle(
            color: VxColors.neonRed,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error,
                            color: VxColors.neonRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.message,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
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
            color: VxColors.neonCyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/subscription');
            },
            child: const Text('Unlock Now',
                style: TextStyle(color: VxColors.neonCyan)),
          ),
        ],
      ),
    );
  }
}
