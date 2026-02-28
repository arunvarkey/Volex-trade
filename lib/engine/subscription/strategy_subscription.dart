enum SubscriptionStatus { active, expired, cancelled }

enum AccessLevel { basic, pro, premium }

class StrategySubscription {
  final String strategyId;
  final String subscriberUserId;
  final DateTime startDate;
  final DateTime renewalDate;
  final SubscriptionStatus status;
  final AccessLevel accessLevel;
  final double price;

  const StrategySubscription({
    required this.strategyId,
    required this.subscriberUserId,
    required this.startDate,
    required this.renewalDate,
    required this.status,
    this.accessLevel = AccessLevel.basic,
    required this.price,
  });

  bool get isActive =>
      status == SubscriptionStatus.active &&
      DateTime.now().isBefore(renewalDate);

  Map<String, dynamic> toJson() {
    return {
      'strategyId': strategyId,
      'subscriberUserId': subscriberUserId,
      'startDate': startDate.toIso8601String(),
      'renewalDate': renewalDate.toIso8601String(),
      'status': status.index,
      'accessLevel': accessLevel.index,
      'price': price,
    };
  }

  factory StrategySubscription.fromJson(Map<String, dynamic> json) {
    return StrategySubscription(
      strategyId: json['strategyId'],
      subscriberUserId: json['subscriberUserId'],
      startDate: DateTime.parse(json['startDate']),
      renewalDate: DateTime.parse(json['renewalDate']),
      status: SubscriptionStatus.values[json['status']],
      accessLevel: AccessLevel.values[json['accessLevel'] ?? 0],
      price: (json['price'] as num).toDouble(),
    );
  }
}
