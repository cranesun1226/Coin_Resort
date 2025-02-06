// import packages
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cr_frontend/etc/chartdata_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// import files

class ChartInfoCard extends StatefulWidget {
  final String code;
  final List<ChartData> chartData;
  final Map<String, dynamic> coinInfo;
  final int currentInterval;
  final List<Map<String, dynamic>> intervalOptions;
  final Function(int) onIntervalChanged;

  const ChartInfoCard({
    super.key,
    required this.code,
    required this.chartData,
    required this.coinInfo,
    required this.currentInterval,
    required this.intervalOptions,
    required this.onIntervalChanged,
  });

  @override
  State<ChartInfoCard> createState() => _ChartInfoCardState();
}

class _ChartInfoCardState extends State<ChartInfoCard> {
  bool isChartExpanded = false;
  bool showIntervalMenu = false;
  late WebSocketChannel _channel;
  List<ChartData> localChartData = [];

  late StreamSubscription _channelSubscription;

  @override
  void initState() {
    super.initState();
    localChartData = List.from(widget.chartData);
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

  @override
  void didUpdateWidget(ChartInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chartData != widget.chartData ||
        oldWidget.currentInterval != widget.currentInterval) {
      setState(() {
        localChartData = List.from(widget.chartData);
      });
    }
  }

  void _updateChartData(Map<String, dynamic> data) {
    // 위젯이 아직 마운트되어 있는지 확인
    if (!mounted) return;

    try {
      final now = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
      final tradePrice = (data['trade_price'] is int)
          ? data['trade_price'].toDouble()
          : data['trade_price'];

      if (!mounted) return; // 추가 체크 (선택 사항)

      setState(() {
        if (localChartData.isEmpty) return;

        var latestCandle = localChartData[0];

        // 현재 캔들 업데이트
        if (_isSameInterval(latestCandle.time, now)) {
          localChartData[0] = ChartData(
            time: latestCandle.time,
            open: latestCandle.open,
            high: max(latestCandle.high, tradePrice),
            low: min(latestCandle.low, tradePrice),
            close: tradePrice,
          );
        }
        // 새로운 캔들 생성
        else {
          final newCandle = ChartData(
            time: _normalizeDateTime(now),
            open: tradePrice,
            high: tradePrice,
            low: tradePrice,
            close: tradePrice,
          );
          localChartData.insert(0, newCandle);

          // 최대 200개 캔들 유지
          if (localChartData.length > 200) {
            localChartData.removeLast();
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating chart data: $e');
      }
    }
  }

  @override
  void dispose() {
    _channelSubscription.cancel();
    _channel.sink.close();
    super.dispose();
  }

  DateTime _normalizeDateTime(DateTime time) {
    final interval = widget.currentInterval;

    if (interval >= 1440) {
      // 일봉
      return DateTime(time.year, time.month, time.day);
    } else {
      // 분봉
      final totalMinutes = time.hour * 60 + time.minute;
      final normalizedMinutes = (totalMinutes ~/ interval) * interval;
      final hours = normalizedMinutes ~/ 60;
      final minutes = normalizedMinutes % 60;
      return DateTime(time.year, time.month, time.day, hours, minutes);
    }
  }

  bool _isSameInterval(DateTime existing, DateTime now) {
    final interval = widget.currentInterval;

    if (interval >= 1440) {
      // 일봉
      return existing.year == now.year &&
          existing.month == now.month &&
          existing.day == now.day;
    } else {
      // 분봉
      final existingMinutes = existing.hour * 60 + existing.minute;
      final newMinutes = now.hour * 60 + now.minute;
      return (existingMinutes ~/ interval) == (newMinutes ~/ interval);
    }
  }

  String getIntervalLabel(int interval) {
    return widget.intervalOptions.firstWhere(
      (option) => option['value'] == interval,
      orElse: () => {'label': '$interval분봉'},
    )['label'] as String;
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2EC4B6).withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '차트 분석 ⚡️',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isChartExpanded ? Icons.remove : Icons.add,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            isChartExpanded = !isChartExpanded;
                          });
                        },
                      ),
                      Row(
                        children: [
                          Icon(
                            widget.coinInfo['change'] == 'RISE'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: widget.coinInfo['change'] == 'RISE'
                                ? Color(0xFF2EC4B6)
                                : Color(0xFFFF7F50),
                          ),
                          Text(
                            NumberFormat.decimalPercentPattern(
                              decimalDigits: 2,
                            ).format(widget.coinInfo['change_rate'] ?? 0),
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.coinInfo['change'] == 'RISE'
                                  ? Color(0xFF2EC4B6)
                                  : Color(0xFFFF7F50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showIntervalMenu = !showIntervalMenu;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFF2EC4B6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            getIntervalLabel(widget.currentInterval),
                            style: TextStyle(
                              color: Color(0xFF2EC4B6),
                              fontWeight: FontWeight.w600,
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
              AnimatedCrossFade(
                firstChild: SizedBox.shrink(),
                secondChild: Stack(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: widget.coinInfo.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF7F50),
                              ),
                            )
                          : SfCartesianChart(
                              margin: EdgeInsets.fromLTRB(0, 16, 16, 0),
                              plotAreaBorderWidth: 0,
                              backgroundColor: Colors.white,
                              enableAxisAnimation: true,
                              zoomPanBehavior: ZoomPanBehavior(
                                enablePanning: true,
                                enablePinching: true,
                                zoomMode: ZoomMode.x,
                              ),
                              trackballBehavior: TrackballBehavior(
                                enable: true,
                                activationMode: ActivationMode.longPress,
                                tooltipSettings: InteractiveTooltip(
                                  enable: true,
                                  color: Colors.black.withOpacity(0.8),
                                  textStyle: TextStyle(color: Colors.white),
                                ),
                                lineType: TrackballLineType.vertical,
                                lineColor: Color(0xFF2EC4B6).withOpacity(0.3),
                                lineWidth: 1,
                              ),
                              primaryXAxis: DateTimeAxis(
                                majorGridLines: MajorGridLines(width: 0),
                                axisLine: AxisLine(width: 0),
                                labelStyle:
                                    TextStyle(color: Colors.transparent),
                                minimum: localChartData.isNotEmpty
                                    ? localChartData.last.time
                                    : null,
                                maximum: localChartData.isNotEmpty
                                    ? DateTime.now().add(Duration(
                                        minutes: widget.currentInterval))
                                    : null,
                              ),
                              primaryYAxis: NumericAxis(
                                numberFormat: NumberFormat.compact(
                                  locale: 'ko_KR',
                                ),
                                axisLine: AxisLine(width: 0),
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                majorGridLines: MajorGridLines(
                                  width: 0.5,
                                  color: Colors.grey[300],
                                  dashArray: [5, 5],
                                ),
                                minimum: widget.chartData.isNotEmpty
                                    ? _calculateYAxisMinimum(widget.chartData)
                                    : null,
                                maximum: widget.chartData.isNotEmpty
                                    ? _calculateYAxisMaximum(widget.chartData)
                                    : null,
                                plotBands: [
                                  PlotBand(
                                    isVisible: true,
                                    start: widget.coinInfo['trade_price']
                                            ?.toDouble() ??
                                        0,
                                    end: widget.coinInfo['trade_price']
                                            ?.toDouble() ??
                                        0,
                                    borderWidth: 1,
                                    borderColor: Colors.grey[400]!,
                                    dashArray: [5, 5],
                                  ),
                                ],
                              ),
                              series: <CartesianSeries<ChartData, DateTime>>[
                                CandleSeries<ChartData, DateTime>(
                                  dataSource: localChartData,
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
                                  bullColor: Color(0xFF2EC4B6).withOpacity(0.9),
                                  bearColor: Color(0xFFFF7F50).withOpacity(0.9),
                                  borderWidth: 1,
                                  animationDuration: 0,
                                  showIndicationForSameValues: true,
                                  enableTooltip: true,
                                  name: '${widget.code.split('-')[1]}/KRW',
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                crossFadeState: isChartExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: Duration(milliseconds: 300),
              ),
            ],
          ),
          if (showIntervalMenu)
            Positioned(
              top: 50,
              right: 20,
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
                  children: widget.intervalOptions.map((option) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          showIntervalMenu = false;
                        });
                        widget.onIntervalChanged(option['value'] as int);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        width: 100,
                        decoration: BoxDecoration(
                          color: widget.currentInterval == option['value']
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
                            color: widget.currentInterval == option['value']
                                ? Color(0xFF2EC4B6)
                                : Colors.black87,
                            fontWeight:
                                widget.currentInterval == option['value']
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
    );
  }
}
