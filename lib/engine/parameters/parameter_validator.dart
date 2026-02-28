import 'parameter_models.dart';
import '../access_control_service.dart';

class ParameterValidator {
  /// Validates a specific value against a schema.
  static String? validateValue(StrategyParameterSchema schema, dynamic value) {
    if (value == null) {
      return "Value cannot be null";
    }

    switch (schema.type) {
      case ParameterType.integer:
        if (value is! int) return "Value must be an integer";
        if (schema.min != null && value < schema.min!) {
          return "Value must be >= ${schema.min}";
        }
        if (schema.max != null && value > schema.max!) {
          return "Value must be <= ${schema.max}";
        }
        break;
      case ParameterType.double:
        if (value is! num) {
          return "Value must be a number";
        }
        if (schema.min != null && value < schema.min!) {
          return "Value must be >= ${schema.min}";
        }
        if (schema.max != null && value > schema.max!) {
          return "Value must be <= ${schema.max}";
        }
        break;
      case ParameterType.boolean:
        if (value is! bool) {
          return "Value must be a boolean";
        }
        break;
      case ParameterType.enumeration:
        if (schema.options != null && !schema.options!.contains(value)) {
          return "Value must be one of: ${schema.options!.join(', ')}";
        }
        break;
      case ParameterType.string:
        if (value is! String) {
          return "Value must be a string";
        }
        break;
    }
    return null; // Valid
  }

  /// Validates a full set of parameters changes for a user role.
  static List<String> validateSet({
    required List<StrategyParameterSchema> schemas,
    required Map<String, dynamic> newValues,
    required UserRole userRole,
  }) {
    List<String> errors = [];

    for (var schema in schemas) {
      if (newValues.containsKey(schema.name)) {
        // 1. Check Permissions
        if (userRole == UserRole.trader && !schema.isTraderEditable) {
          errors.add("Parameter '${schema.name}' is not editable by Traders.");
          continue;
        }

        // 2. Check Type/Bounds
        final error = validateValue(schema, newValues[schema.name]);
        if (error != null) {
          errors.add("Parameter '${schema.name}': $error");
        }
      }
    }

    return errors;
  }
}
