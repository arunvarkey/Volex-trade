// lib/features/simulator/strategy_builder/models/strategy_template.dart
import 'package:flutter/material.dart';
import '../../../subscriptions/models/subscription_tier.dart';
import 'template_parameter.dart';
import 'package:volex_terminal/features/simulator/strategy_builder/models/generated_strategy.dart';

abstract class StrategyTemplate {
  String get id;
  String get name;
  String get description;
  String get category;
  IconData get icon;
  SubscriptionTier get requiredTier;

  List<TemplateParameter> get parameters;

  GeneratedStrategy instantiate(Map<String, dynamic> values);

  // Validation rules specific to this template
  List<String> validate(Map<String, dynamic> values) {
    final errors = <String>[];

    for (final param in parameters) {
      if (!values.containsKey(param.id)) {
        errors.add('Missing parameter: ${param.label}');
      }

      final paramErrors = param.validate(values[param.id]);
      errors.addAll(paramErrors);
    }

    return errors;
  }
}
