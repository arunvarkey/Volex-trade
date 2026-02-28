import 'package:flutter/foundation.dart';

/// Controller for preserving paper trading form state across navigation
class PaperTradingFormController extends ChangeNotifier {
  double _quantity = 0.01;
  double? _limitPrice;
  String _orderType = 'MARKET';
  String _side = 'BUY';

  double get quantity => _quantity;
  double? get limitPrice => _limitPrice;
  String get orderType => _orderType;
  String get side => _side;

  void updateQuantity(double value) {
    _quantity = value;
    notifyListeners();
  }

  void updateLimitPrice(double? value) {
    _limitPrice = value;
    notifyListeners();
  }

  void updateOrderType(String value) {
    _orderType = value;
    notifyListeners();
  }

  void updateSide(String value) {
    _side = value;
    notifyListeners();
  }

  void reset() {
    _quantity = 0.01;
    _limitPrice = null;
    _orderType = 'MARKET';
    _side = 'BUY';
    notifyListeners();
  }
}
