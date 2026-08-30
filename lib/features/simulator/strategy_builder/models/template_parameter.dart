// lib/features/simulator/strategy_builder/models/template_parameter.dart
abstract class TemplateParameter {
  final String id;
  final String label;
  final String? description;
  final dynamic defaultValue;

  TemplateParameter({
    required this.id,
    required this.label,
    this.description,
    required this.defaultValue,
  });

  List<String> validate(dynamic value);
}

class NumericParameter extends TemplateParameter {
  final num min;
  final num max;
  final int? decimals;

  NumericParameter({
    required super.id,
    required super.label,
    super.description,
    required num super.defaultValue,
    required this.min,
    required this.max,
    this.decimals,
  });

  @override
  List<String> validate(dynamic value) {
    final errors = <String>[];

    if (value is! num) {
      errors.add('$label must be a number');
      return errors;
    }

    if (value < min || value > max) {
      errors.add('$label must be between $min and $max');
    }

    return errors;
  }
}

class DropdownParameter extends TemplateParameter {
  final List<String> options;

  DropdownParameter({
    required super.id,
    required super.label,
    super.description,
    required String super.defaultValue,
    required this.options,
  });

  @override
  List<String> validate(dynamic value) {
    final errors = <String>[];

    if (value is! String) {
      errors.add('$label must be a string');
      return errors;
    }

    if (!options.contains(value)) {
      errors.add('$label must be one of: ${options.join(", ")}');
    }

    return errors;
  }
}
