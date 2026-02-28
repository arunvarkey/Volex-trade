enum VisualOrderType { limit, stopLoss, takeProfit }

class VisualOrder {
  final String id;
  double price;
  final VisualOrderType type;
  bool isDragging;
  final String label;

  VisualOrder({
    required this.id,
    required this.price,
    required this.type,
    this.isDragging = false,
    this.label = '',
  });

  VisualOrder copyWith({
    double? price,
    bool? isDragging,
  }) {
    return VisualOrder(
      id: id,
      price: price ?? this.price,
      type: type,
      isDragging: isDragging ?? this.isDragging,
      label: label,
    );
  }
}
