enum ParameterType { integer, double, boolean, enumeration, string }

class StrategyParameterSchema {
  final String name;
  final ParameterType type;
  final num? min;
  final num? max;
  final List<String>? options; // For enumeration
  final dynamic defaultValue;
  final String description;
  final bool isTraderEditable;

  const StrategyParameterSchema({
    required this.name,
    required this.type,
    this.min,
    this.max,
    this.options,
    required this.defaultValue,
    this.description = '',
    this.isTraderEditable = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.toString(),
      'min': min,
      'max': max,
      'options': options,
      'defaultValue': defaultValue,
      'description': description,
      'isTraderEditable': isTraderEditable,
    };
  }
}

class StrategyParameterSet {
  final String strategyId;
  final String userId;
  final Map<String, dynamic> values;
  final int version;
  final DateTime updatedAt;

  const StrategyParameterSet({
    required this.strategyId,
    required this.userId,
    required this.values,
    required this.version,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'strategyId': strategyId,
      'userId': userId,
      'values': values,
      'version': version,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StrategyParameterSet.fromJson(Map<String, dynamic> json) {
    return StrategyParameterSet(
      strategyId: json['strategyId'],
      userId: json['userId'],
      values: Map<String, dynamic>.from(json['values']),
      version: json['version'],
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Helper to get value with fallback
  dynamic getValue(String key, dynamic fallback) => values[key] ?? fallback;
}
