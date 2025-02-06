class ChartData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  ChartData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      time: DateTime.parse(json['candle_date_time_kst']),
      open: json['opening_price'].toDouble(),
      high: json['high_price'].toDouble(),
      low: json['low_price'].toDouble(),
      close: json['trade_price'].toDouble(),
    );
  }
}
