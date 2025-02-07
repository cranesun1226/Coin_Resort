// import packages
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// import files
import 'package:cr_frontend/layer2/aboutcoin_screen.dart';
import 'package:cr_frontend/etc/chartdata_type.dart';

class CoinThumbnailScreen extends StatefulWidget {
  const CoinThumbnailScreen({super.key});

  @override
  CoinThumbnailScreenState createState() => CoinThumbnailScreenState();
}

class CoinThumbnailScreenState extends State<CoinThumbnailScreen> {
  final List<String> _tickers = [
    'KRW-BTC',
    'KRW-ETH',
    'KRW-XRP',
    'KRW-DOGE',
    'KRW-SOL',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F9FF), // 하늘빛이 도는 배경색
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tickers.length,
              itemBuilder: (context, index) {
                final ticker = _tickers[index];
                return CryptoThumbnailWidget(
                  interval: 15,
                  code: ticker,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CryptoThumbnailWidget extends StatefulWidget {
  final int interval;
  final String code;

  const CryptoThumbnailWidget({
    super.key,
    required this.interval,
    required this.code,
  });

  @override
  CryptoThumbnailWidgetState createState() => CryptoThumbnailWidgetState();
}

class CryptoThumbnailWidgetState extends State<CryptoThumbnailWidget> {
  List<ChartData> chartData = [];
  late int currentInterval;
  bool showIntervalMenu = false;
  late WebSocketChannel _channel;
  late StreamSubscription _channelSubscription;
  int _reconnectAttempts = 0;
  static const int maxReconnectDelay = 300; // 최대 5분

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
    _reconnectAttempts = 0; // 연결 성공시 재시도 카운트 리셋
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
    if (!mounted) return;

    // 재시도 간격을 2의 제곱으로 증가 (5초, 10초, 20초...)
    int delaySeconds =
        min(5 * pow(2, _reconnectAttempts).toInt(), maxReconnectDelay);

    Future.delayed(Duration(seconds: delaySeconds), () {
      if (mounted) {
        _connectWebSocket();
        _reconnectAttempts++;
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
    String getCoinImage(String code) {
      switch (code) {
        case 'KRW-BTC':
          return 'asset/btc_logo.png';
        case 'KRW-ETH':
          return 'asset/eth_logo.png';
        case 'KRW-XRP':
          return 'asset/xrp_logo.png';
        case 'KRW-DOGE':
          return 'asset/doge_logo.png';
        case 'KRW-SOL':
          return 'asset/sol_logo.png';
        default:
          return 'asset/btc_logo.png';
      }
    }

    String getCoinName(String code) {
      final coinCode = code.split('-')[1];
      switch (coinCode) {
        case 'BTC':
          return '비트코인';
        case 'ETH':
          return '이더리움';
        case 'XRP':
          return '리플';
        case 'DOGE':
          return '도지코인';
        case 'SOL':
          return '솔라나';
        default:
          return coinCode;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AboutCoinScreen(
              code: widget.code,
              interval: currentInterval,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
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
            // 기존 컨테이너 내용
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  getCoinImage(widget.code),
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getCoinName(widget.code),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  widget.code.split('-')[1],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  showIntervalMenu = !showIntervalMenu;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2EC4B6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      getIntervalLabel(currentInterval),
                                      style: TextStyle(
                                        color: Color(0xFF2EC4B6),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      showIntervalMenu
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: Color(0xFF2EC4B6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: chartData.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF7F50),
                              ),
                            )
                          : SfCartesianChart(
                              zoomPanBehavior: ZoomPanBehavior(
                                enablePinching: true,
                                enablePanning: true,
                                enableDoubleTapZooming: true,
                                enableMouseWheelZooming: true,
                                zoomMode: ZoomMode.x,
                              ),
                              plotAreaBorderWidth: 0,
                              margin: const EdgeInsets.all(0),
                              primaryXAxis: DateTimeAxis(
                                majorGridLines: const MajorGridLines(width: 0),
                                axisLine: const AxisLine(width: 0),
                                labelStyle:
                                    TextStyle(color: Colors.transparent),
                                majorTickLines: const MajorTickLines(size: 0),
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
                                  xValueMapper: (ChartData data, _) =>
                                      data.time,
                                  lowValueMapper: (ChartData data, _) =>
                                      data.low,
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
            // Interval 선택 메뉴
            if (showIntervalMenu)
              Positioned(
                top: 50,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: intervalOptions.map((option) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            currentInterval = option['value'] as int;
                            showIntervalMenu = false;
                          });
                          fetchChartData();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          width: 100,
                          decoration: BoxDecoration(
                            color: currentInterval == option['value']
                                ? Color(0xFF2EC4B6).withOpacity(0.1)
                                : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            option['label'] as String,
                            style: TextStyle(
                              color: currentInterval == option['value']
                                  ? Color(0xFF2EC4B6)
                                  : Colors.black87,
                              fontWeight: currentInterval == option['value']
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
