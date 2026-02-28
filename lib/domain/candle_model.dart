class Candle {
  final int time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Candle.fromJson(List<dynamic> json) {
    return Candle(
      time: json[0] as int,
      open: double.parse(json[1].toString()),
      high: double.parse(json[2].toString()),
      low: double.parse(json[3].toString()),
      close: double.parse(json[4].toString()),
      volume: double.tryParse(json[5].toString()) ?? 0.0,
    );
  }

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(time);

  bool get isGreen => close >= open;
}
