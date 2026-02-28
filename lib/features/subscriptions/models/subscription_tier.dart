import 'dart:io';

enum SubscriptionTier {
  free,
  explorerPremium,
}

class SubscriptionProduct {
  final String id;
  final SubscriptionTier tier;
  final String name;
  final String description;
  final double price;
  final List<String> features;
  final String appleProductId;
  final String googleProductId;

  const SubscriptionProduct({
    required this.id,
    required this.tier,
    required this.name,
    required this.description,
    required this.price,
    required this.features,
    required this.appleProductId,
    required this.googleProductId,
  });

  static const free = SubscriptionProduct(
    id: 'free',
    tier: SubscriptionTier.free,
    name: 'Explorer Free',
    description: 'Get started with AI signals',
    price: 0,
    features: [
      '5 signals per day',
      'Paper trading',
      'Community feed',
      'Basic analytics',
      'Market scanner',
    ],
    appleProductId: '',
    googleProductId: '',
  );

  static const explorerPremium = SubscriptionProduct(
    id: 'explorer_premium',
    tier: SubscriptionTier.explorerPremium,
    name: 'Premium',
    description: 'Unlimited AI & Analytics',
    price: 4.99,
    features: [
      'Unlimited AI strategies',
      'Unlimited Backtesting',
      'Unlimited Signals',
      'Advanced indicators',
      'Strategy Optimizer',
      'Performance Analytics',
      'Export History (CSV)',
      'Priority Support',
    ],
    appleProductId: 'com.antigravity.volextrade.premium_monthly',
    googleProductId: 'premium_monthly',
  );

  static const premiumYearly = SubscriptionProduct(
    id: 'premium_yearly',
    tier: SubscriptionTier.explorerPremium,
    name: 'Premium Yearly',
    description: 'Save 33%',
    price: 39.99,
    features: [
      'Everything in Monthly',
      '2 months free',
    ],
    appleProductId: 'com.antigravity.volextrade.premium_yearly',
    googleProductId: 'premium_yearly',
  );

  static List<SubscriptionProduct> get allTiers => [
        free,
        explorerPremium,
        premiumYearly,
      ];

  String get platformProductId {
    if (Platform.isIOS) return appleProductId;
    if (Platform.isAndroid) return googleProductId;
    return id;
  }
}
