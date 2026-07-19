import 'package:flutter/material.dart';
import '../../engine/parameters/parameter_models.dart';
import '../../engine/parameters/parameter_validator.dart';
import '../design_system/vx_colors.dart';
import '../design_system/vx_typography.dart';

class ParameterEditor extends StatefulWidget {
  final List<StrategyParameterSchema> schemas;
  final Map<String, dynamic> currentValues;
  final bool isEditable;
  final ValueChanged<Map<String, dynamic>> onValuesChanged;

  const ParameterEditor({
    super.key,
    required this.schemas,
    required this.currentValues,
    required this.isEditable,
    required this.onValuesChanged,
  });

  @override
  State<ParameterEditor> createState() => _ParameterEditorState();
}

class _ParameterEditorState extends State<ParameterEditor> {
  late Map<String, dynamic> _values;
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _values = Map.from(widget.currentValues);
  }

  @override
  void didUpdateWidget(ParameterEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValues != widget.currentValues) {
      _values = Map.from(widget.currentValues);
    }
  }

  void _updateValue(String key, dynamic value, StrategyParameterSchema schema) {
    if (!widget.isEditable) return;
    if (schema.isTraderEditable == false) return;

    setState(() {
      _values[key] = value;
      _errors[key] = ParameterValidator.validateValue(schema, value);
    });

    if (_errors[key] == null) {
      widget.onValuesChanged(_values);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.schemas.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("No configurable parameters.",
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ),
        ...widget.schemas.map((schema) => _buildControl(schema)),
      ],
    );
  }

  Widget _buildControl(StrategyParameterSchema schema) {
    final value = _values[schema.name] ?? schema.defaultValue;
    final error = _errors[schema.name];
    final bool canEdit = widget.isEditable && schema.isTraderEditable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: canEdit ? 0.02 : 0.01),
        border: Border.all(
            color: error != null
                ? VxColors.neonRed.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VxText.monoBold(schema.name, color: Colors.white70, fontSize: 11),
              if (!schema.isTraderEditable)
                const Icon(Icons.lock, size: 10, color: Colors.white10),
            ],
          ),
          if (schema.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: VxText.body(schema.description,
                  color: Colors.white24, fontSize: 10),
            ),
          _buildInputForType(schema, value, canEdit),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: VxText.mono(error, color: VxColors.neonRed, fontSize: 9),
            ),
        ],
      ),
    );
  }

  Widget _buildInputForType(
      StrategyParameterSchema schema, dynamic value, bool enabled) {
    switch (schema.type) {
      case ParameterType.integer:
      case ParameterType.double:
        if (schema.min != null && schema.max != null) {
          return Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: VxColors.neonCyan,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                    trackHeight: 1,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 4),
                  ),
                  child: Slider(
                    value: (value as num).toDouble(),
                    min: schema.min!.toDouble(),
                    max: schema.max!.toDouble(),
                    divisions: (schema.type == ParameterType.integer)
                        ? (schema.max! - schema.min!).toInt()
                        : 100,
                    onChanged: enabled
                        ? (v) => _updateValue(
                            schema.name,
                            schema.type == ParameterType.integer
                                ? v.toInt()
                                : v,
                            schema)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              VxText.mono(
                  value.toStringAsFixed(
                      schema.type == ParameterType.integer ? 0 : 2),
                  color: VxColors.neonCyan,
                  fontSize: 11),
            ],
          );
        } else {
          return VxText.mono(value.toString(), color: Colors.white70);
        }
      case ParameterType.boolean:
        return Switch(
          value: value as bool,
          activeThumbColor: VxColors.neonCyan,
          onChanged:
              enabled ? (v) => _updateValue(schema.name, v, schema) : null,
        );
      case ParameterType.enumeration:
        return DropdownButton<String>(
          value: value as String,
          dropdownColor: VxColors.surface,
          isExpanded: true,
          underline: const SizedBox(),
          style: const TextStyle(
              fontFamily: 'RobotoMono', color: Colors.white70, fontSize: 12),
          items: schema.options!
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged:
              enabled ? (v) => _updateValue(schema.name, v, schema) : null,
        );
      case ParameterType.string:
        return VxText.mono(value.toString(), color: Colors.white70);
    }
  }
}
