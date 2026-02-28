/// Encapsulates the financial state of a trading account.
class VolexAccount {
  double _cashBalance;
  final Map<String, double> _assetBalances = {};

  VolexAccount({double initialBalance = 0.0}) : _cashBalance = initialBalance;

  double get cashBalance => _cashBalance;

  /// Update cash balance (USDT)
  void updateCash(double adjustment) {
    _cashBalance += adjustment;
  }

  /// Update asset holdings (e.g. BTC, ETH)
  void updateAsset(String asset, double adjustment) {
    _assetBalances[asset] = (_assetBalances[asset] ?? 0.0) + adjustment;
  }

  Map<String, double> get assetBalances => Map.unmodifiable(_assetBalances);

  /// Combined map for UI consumption
  Map<String, double> get fullStatement => {
        'USDT': _cashBalance,
        ..._assetBalances,
      };
}
