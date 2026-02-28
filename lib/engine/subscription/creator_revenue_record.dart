enum RevenueStatus { pending, paid }

class CreatorRevenueRecord {
  final String strategyId;
  final String creatorUserId;
  final String subscriberUserId;
  final DateTime period; // Month/Year
  final double amount;
  final RevenueStatus status;

  const CreatorRevenueRecord({
    required this.strategyId,
    required this.creatorUserId,
    required this.subscriberUserId,
    required this.period,
    required this.amount,
    this.status = RevenueStatus.pending,
  });

  Map<String, dynamic> toJson() {
    return {
      'strategyId': strategyId,
      'creatorUserId': creatorUserId,
      'subscriberUserId': subscriberUserId,
      'period': period.toIso8601String(),
      'amount': amount,
      'status': status.index,
    };
  }

  factory CreatorRevenueRecord.fromJson(Map<String, dynamic> json) {
    return CreatorRevenueRecord(
      strategyId: json['strategyId'],
      creatorUserId: json['creatorUserId'],
      subscriberUserId: json['subscriberUserId'],
      period: DateTime.parse(json['period']),
      amount: (json['amount'] as num).toDouble(),
      status: RevenueStatus.values[json['status'] ?? 0],
    );
  }
}
