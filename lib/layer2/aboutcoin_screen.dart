// import packages
import 'dart:async';
import 'dart:convert';
import 'package:cr_frontend/etc/chartdata_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import files
import 'package:cr_frontend/layer2/priceinfo_widget.dart';
import 'package:cr_frontend/layer2/chartinfo_widget.dart';
import 'package:cr_frontend/layer2/chatinfo_widget.dart';
import 'package:cr_frontend/layer2/feedinfo_widget.dart';

class AboutCoinScreen extends StatefulWidget {
  final String code;
  final int interval;

  const AboutCoinScreen({
    super.key,
    required this.code,
    required this.interval,
  });

  @override
  State<AboutCoinScreen> createState() => _AboutCoinScreenState();
}

class _AboutCoinScreenState extends State<AboutCoinScreen> {
  List<ChartData> chartData = [];
  Map<String, dynamic> coinInfo = {};
  Timer? _timer;
  late int currentInterval;

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
    _fetchData();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String getEndpoint(int interval) {
    return intervalOptions.firstWhere(
      (option) => option['value'] == interval,
      orElse: () => {'endpoint': 'minutes/$interval'},
    )['endpoint'] as String;
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchChartData(),
      _fetchCoinInfo(),
    ]);
  }

  Future<void> _fetchChartData() async {
    final endpoint = getEndpoint(currentInterval);
    final url = Uri.parse(
      'https://api.upbit.com/v1/candles/$endpoint?market=${widget.code}&count=200',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          chartData = jsonData.map((e) => ChartData.fromJson(e)).toList();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching chart data: $e');
      }
    }
  }

  Future<void> _fetchCoinInfo() async {
    final url = Uri.parse(
      'https://api.upbit.com/v1/ticker?markets=${widget.code}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          coinInfo = jsonData[0];
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching coin info: $e');
      }
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          padding: EdgeInsets.only(left: 16),
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2EC4B6)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2EC4B6), Color(0xFFFF7F50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${widget.code.split('-')[1]} 라운지 🌴',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              PriceInfoCard(coinInfo: coinInfo, formatPrice: _formatPrice),
              SizedBox(height: 24),
              ChartInfoCard(
                code: widget.code,
                chartData: chartData,
                coinInfo: coinInfo,
                currentInterval: currentInterval,
                intervalOptions: intervalOptions,
                onIntervalChanged: (int newInterval) {
                  setState(() {
                    currentInterval = newInterval;
                  });
                  _fetchChartData();
                },
              ),
              SizedBox(height: 24),
              ChatInfoCard(code: widget.code, interval: currentInterval),
              SizedBox(height: 24),
              FeedInfoCard(code: widget.code),
            ],
          ),
        ),
      ),
    );
  }
}
