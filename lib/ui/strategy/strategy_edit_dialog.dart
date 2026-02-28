import 'package:flutter/material.dart';
import '../../engine/parameters/parameter_validator.dart';
import '../../engine/strategy/strategy_engine.dart';
import '../parameters/parameter_editor.dart';
import '../design_system/vx_colors.dart';
import '../design_system/vx_typography.dart';
import '../design_system/vx_spacing.dart';
import '../../engine/access_control_service.dart';
import 'dart:ui';

class StrategyEditDialog extends StatefulWidget {
  final Strategy strategy;
  final Function(Map<String, dynamic>) onSave;

  const StrategyEditDialog(
      {super.key, required this.strategy, required this.onSave});

  @override
  State<StrategyEditDialog> createState() => _StrategyEditDialogState();
}

class _StrategyEditDialogState extends State<StrategyEditDialog> {
  late Map<String, dynamic> _currentValues;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    _currentValues = {
      for (var p in widget.strategy.currentParameterValues.entries)
        p.key: p.value
    };

    for (var s in widget.strategy.parameters) {
      if (!_currentValues.containsKey(s.name)) {
        _currentValues[s.name] = s.defaultValue;
      }
    }
  }

  void _validate() {
    final errors = ParameterValidator.validateSet(
        schemas: widget.strategy.parameters,
        newValues: _currentValues,
        userRole: UserRole.operator);
    setState(() {
      _errors = errors;
    });
  }

  void _onSave() {
    _validate();
    if (_errors.isEmpty) {
      widget.onSave(_currentValues);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
                color: VxColors.surface.withOpacity(0.9),
                border: Border.all(color: VxColors.neonCyan.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: VxColors.neonCyan.withOpacity(0.1), blurRadius: 30)
                ]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(VxSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      VxText.monoBold(
                        "CONFIGURE // ${widget.strategy.name.toUpperCase()}",
                        color: VxColors.neonCyan,
                        fontSize: 14,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white38, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(VxSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errors.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                                color: VxColors.neonRed.withOpacity(0.1),
                                border: Border.all(
                                    color: VxColors.neonRed.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _errors
                                  .map((e) => VxText.mono(
                                        "• $e",
                                        color: VxColors.neonRed,
                                        fontSize: 11,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ParameterEditor(
                          schemas: widget.strategy.parameters,
                          currentValues: _currentValues,
                          isEditable: true,
                          onValuesChanged: (val) {
                            setState(() {
                              _currentValues = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                const Divider(color: Colors.white10, height: 1),
                Padding(
                  padding: const EdgeInsets.all(VxSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: VxText.monoBold("CANCEL", color: Colors.white38),
                      ),
                      const SizedBox(width: 8),
                      Theme(
                        data: ThemeData(
                          elevatedButtonTheme: ElevatedButtonThemeData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VxColors.neonCyan,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _onSave,
                          icon: const Icon(Icons.save, size: 16),
                          label: VxText.monoBold("APPLY CHANGES", fontSize: 12),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VxColors.neonCyan,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
