import 'subscription_tier.dart';

class SubscriptionStatus {
  final SubscriptionTier tier;
  final bool isActive;
  final DateTime? expiryDate;
  final DateTime? purchaseDate;
  final String? purchaseId;
  final bool isTrialing;
  final int daysRemaining;

  const SubscriptionStatus({
    required this.tier,
    required this.isActive,
    this.expiryDate,
    this.purchaseDate,
    this.purchaseId,
    this.isTrialing = false,
    this.daysRemaining = 0,
  });

  factory SubscriptionStatus.free() => const SubscriptionStatus(
        tier: SubscriptionTier.free,
        isActive: true,
      );

  bool get isPremium => tier == SubscriptionTier.explorerPremium;

  // Legacy getters mapped to premium or removed logic
  bool get isProMode => false;
  bool get canTrade => false; // Live trading disabled for now
  bool get hasUnlimitedSignals => isPremium;

  Map<String, dynamic> toJson() => {
        'tier': tier.toString(),
        'is_active': isActive,
        'expiry_date': expiryDate?.toIso8601String(),
        'purchase_date': purchaseDate?.toIso8601String(),
        'purchase_id': purchaseId,
        'is_trialing': isTrialing,
      };

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final tierString = json['tier'] as String;
    SubscriptionTier tier = SubscriptionTier.free;

    if (tierString.contains('explorerPremium') ||
        tierString.contains('proMode')) {
      tier = SubscriptionTier.explorerPremium;
    }

    return SubscriptionStatus(
      tier: tier,
      isActive: json['is_active'] as bool,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : null,
      purchaseId: json['purchase_id'] as String?,
      isTrialing: json['is_trialing'] as bool? ?? false,
      daysRemaining: 0,
    );
  }
}
