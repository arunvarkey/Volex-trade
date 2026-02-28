// lib/features/simulator/ai_strategy/models/validation_error.dart
class ValidationError {
  final String field;
  final String code;
  final String message;

  ValidationError({
    required this.field,
    required this.code,
    required this.message,
  });

  @override
  String toString() => '$field: $message';
}

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;

  ValidationResult.success()
      : isValid = true,
        errors = [];

  ValidationResult.failure(this.errors) : isValid = false;

  String get errorMessage => errors.map((e) => e.message).join('\n');
}
