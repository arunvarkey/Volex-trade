/// User-drawn chart annotations, persisted per symbol.
///
/// Two kinds for v1:
///  - [ChartDrawingType.horizontal] — a price level (support/resistance).
///  - [ChartDrawingType.trendline]  — a segment between two (time, price)
///    anchors.
/// Kept dependency-free (its own JSON) so the chart engine stays decoupled.
enum ChartDrawingType { horizontal, trendline }

class ChartDrawing {
  final String id;
  final ChartDrawingType type;

  /// Horizontal level price (used when [type] is horizontal).
  final double price;

  /// Trendline anchors: (timeMs, price) pairs. Empty for a horizontal line.
  final int aTimeMs;
  final double aPrice;
  final int bTimeMs;
  final double bPrice;

  const ChartDrawing({
    required this.id,
    required this.type,
    this.price = 0,
    this.aTimeMs = 0,
    this.aPrice = 0,
    this.bTimeMs = 0,
    this.bPrice = 0,
  });

  const ChartDrawing.horizontal({required this.id, required this.price})
      : type = ChartDrawingType.horizontal,
        aTimeMs = 0,
        aPrice = 0,
        bTimeMs = 0,
        bPrice = 0;

  const ChartDrawing.trendline({
    required this.id,
    required this.aTimeMs,
    required this.aPrice,
    required this.bTimeMs,
    required this.bPrice,
  })  : type = ChartDrawingType.trendline,
        price = 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'price': price,
        'aTimeMs': aTimeMs,
        'aPrice': aPrice,
        'bTimeMs': bTimeMs,
        'bPrice': bPrice,
      };

  factory ChartDrawing.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final type = ChartDrawingType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => ChartDrawingType.horizontal,
    );
    return ChartDrawing(
      id: json['id'] as String,
      type: type,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      aTimeMs: (json['aTimeMs'] as num?)?.toInt() ?? 0,
      aPrice: (json['aPrice'] as num?)?.toDouble() ?? 0,
      bTimeMs: (json['bTimeMs'] as num?)?.toInt() ?? 0,
      bPrice: (json['bPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}
