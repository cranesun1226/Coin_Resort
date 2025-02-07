import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cr_frontend/etc/chartdata_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SmallChartWidget extends StatefulWidget {
  final int interval;
  final String code;

  const SmallChartWidget({
    super.key,
    required this.interval,
    required this.code,
  });

  @override
  SmallChartWidgetState createState() => SmallChartWidgetState();
}

class SmallChartWidgetState extends State<SmallChartWidget> {
  List<ChartData> chartData = [];
  late int currentInterval;
  late WebSocketChannel _channel;
  late StreamSubscription _channelSubscription;

  final List<Map<String, dynamic>> intervalOptions = [
    {'label': '1분봉', 'value': 1, 'endpoint': 'minutes/1'},
    {'label': '15분봉', 'value': 15, 'endpoint': 'minutes/15'},
    {'label': '1시간봉', 'value': 60, 'endpoint': 'minutes/60'},
    {'label': '4시간봉', 'value': 240, 'endpoint': 'minutes/240'},
    {'label': '1일봉', 'value': 1440, 'endpoint': 'days'},
  ];

  @override
  void initState() {
    super.initState();
    currentInterval = widget.interval;
    fetchChartData();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _channel = IOWebSocketChannel.connect("wss://api.upbit.com/websocket/v1");

    _channel.sink.add(jsonEncode([
      {"ticket": "test"},
      {
        "type": "ticker",
        "codes": [widget.code]
      }
    ]));

    _channelSubscription = _channel.stream.listen(
      (message) {
        final decoded = utf8.decode(message);
        final data = jsonDecode(decoded);
        _updateChartData(data);
      },
      onError: (error) {
        if (kDebugMode) {
          print("WebSocket Error: $error");
        }
        _reconnectWebSocket();
      },
      onDone: () {
        if (kDebugMode) {
          print("WebSocket Closed");
        }
        _reconnectWebSocket();
      },
    );
  }

  void _reconnectWebSocket() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        _connectWebSocket();
      }
    });
  }

  void _updateChartData(Map<String, dynamic> data) {
    if (!mounted) return;

    try {
      final now = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
      final tradePrice = (data['trade_price'] is int)
          ? data['trade_price'].toDouble()
          : data['trade_price'];

      setState(() {
        if (chartData.isEmpty) return;

        var latestCandle = chartData[0];

        if (_isSameInterval(latestCandle.time, now)) {
          chartData[0] = ChartData(
            time: latestCandle.time,
            open: latestCandle.open,
            high: max(latestCandle.high, tradePrice),
            low: min(latestCandle.low, tradePrice),
            close: tradePrice,
          );
        } else {
          final newCandle = ChartData(
            time: _normalizeDateTime(now),
            open: tradePrice,
            high: tradePrice,
            low: tradePrice,
            close: tradePrice,
          );
          chartData.insert(0, newCandle);

          if (chartData.length > 100) {
            chartData.removeLast();
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating chart data: $e');
      }
    }
  }

  DateTime _normalizeDateTime(DateTime time) {
    if (currentInterval >= 1440) {
      return DateTime(time.year, time.month, time.day);
    } else {
      final totalMinutes = time.hour * 60 + time.minute;
      final normalizedMinutes =
          (totalMinutes ~/ currentInterval) * currentInterval;
      final hours = normalizedMinutes ~/ 60;
      final minutes = normalizedMinutes % 60;
      return DateTime(time.year, time.month, time.day, hours, minutes);
    }
  }

  bool _isSameInterval(DateTime existing, DateTime now) {
    if (currentInterval >= 1440) {
      return existing.year == now.year &&
          existing.month == now.month &&
          existing.day == now.day;
    } else {
      final existingMinutes = existing.hour * 60 + existing.minute;
      final newMinutes = now.hour * 60 + now.minute;
      return (existingMinutes ~/ currentInterval) ==
          (newMinutes ~/ currentInterval);
    }
  }

  @override
  void dispose() {
    _channelSubscription.cancel();
    _channel.sink.close();
    super.dispose();
  }

  String getIntervalLabel(int interval) {
    return intervalOptions.firstWhere(
      (option) => option['value'] == interval,
      orElse: () => {'label': '$interval분봉'},
    )['label'] as String;
  }

  String getEndpoint(int interval) {
    return intervalOptions.firstWhere(
      (option) => option['value'] == interval,
      orElse: () => {'endpoint': 'minutes/$interval'},
    )['endpoint'] as String;
  }

  Future<void> fetchChartData() async {
    final endpoint = getEndpoint(currentInterval);
    final url = Uri.parse(
        'https://api.upbit.com/v1/candles/$endpoint?market=${widget.code}&count=100');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        if (mounted) {
          setState(() {
            chartData = jsonData.map((e) => ChartData.fromJson(e)).toList();
          });
        }
      } else {
        throw Exception('Failed to load chart data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching chart data: $e');
      }
    }
  }

  double _calculateYAxisMinimum(List<ChartData> data) {
    double minPrice = double.infinity;
    for (var item in data) {
      if (item.low < minPrice) {
        minPrice = item.low;
      }
    }
    return minPrice;
  }

  double _calculateYAxisMaximum(List<ChartData> data) {
    double maxPrice = double.negativeInfinity;
    for (var item in data) {
      if (item.high > maxPrice) {
        maxPrice = item.high;
      }
    }
    return maxPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2EC4B6).withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Color(0xFF2EC4B6).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFF2EC4B6).withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: intervalOptions.map((option) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                currentInterval = option['value'] as int;
                              });
                              fetchChartData();
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: currentInterval == option['value']
                                    ? Color(0xFF2EC4B6).withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: currentInterval == option['value']
                                      ? Color(0xFF2EC4B6)
                                      : Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                option['label'] as String,
                                style: TextStyle(
                                  color: currentInterval == option['value']
                                      ? Color(0xFF2EC4B6)
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: chartData.isEmpty
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF7F50),
                            ),
                          )
                        : SfCartesianChart(
                            plotAreaBorderWidth: 0,
                            margin: const EdgeInsets.all(0),
                            zoomPanBehavior: ZoomPanBehavior(
                              enablePinching: true,
                              enablePanning: true,
                              enableDoubleTapZooming: true,
                              enableMouseWheelZooming: true,
                              zoomMode: ZoomMode.xy,
                            ),
                            primaryXAxis: DateTimeAxis(
                              majorGridLines: const MajorGridLines(width: 0),
                              axisLine: const AxisLine(width: 0),
                              labelStyle: TextStyle(color: Colors.transparent),
                              majorTickLines: const MajorTickLines(size: 0),
                              enableAutoIntervalOnZooming: true,
                            ),
                            primaryYAxis: NumericAxis(
                              isVisible: true,
                              axisLine: const AxisLine(width: 0),
                              majorGridLines: MajorGridLines(
                                width: 0.5,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                              labelStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                              numberFormat: NumberFormat.compact(),
                              majorTickLines: const MajorTickLines(size: 0),
                              minimum: _calculateYAxisMinimum(chartData),
                              maximum: _calculateYAxisMaximum(chartData),
                            ),
                            series: <CartesianSeries<ChartData, DateTime>>[
                              CandleSeries<ChartData, DateTime>(
                                dataSource: chartData,
                                xValueMapper: (ChartData data, _) => data.time,
                                lowValueMapper: (ChartData data, _) => data.low,
                                highValueMapper: (ChartData data, _) =>
                                    data.high,
                                openValueMapper: (ChartData data, _) =>
                                    data.open,
                                closeValueMapper: (ChartData data, _) =>
                                    data.close,
                                enableSolidCandles: true,
                                bullColor: Color(0xFF2EC4B6),
                                bearColor: Color(0xFFFF7F50),
                                borderWidth: 1,
                                animationDuration: 500,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
