/// Represents a predictive overlay "Ghost" line.
class GhostModel {
  final double startPrice;
  final double endPrice;
  final int startIndex;
  final int endIndex;
  final double confidence;

  GhostModel({
    required this.startPrice,
    required this.endPrice,
    required this.startIndex,
    required this.endIndex,
    this.confidence = 1.0,
  });

  double get slope {
    final dY = endPrice - startPrice;
    final dX = (endIndex - startIndex).toDouble();
    if (dX == 0) return 0;
    return dY / dX;
  }
}
