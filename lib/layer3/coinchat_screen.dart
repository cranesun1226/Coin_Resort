// import packages
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
// import files
import 'package:cr_frontend/etc/chartdata_type.dart';

class ChatScreen extends StatefulWidget {
  final String code;
  final int interval;

  const ChatScreen({
    super.key,
    required this.code,
    required this.interval,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChartData> chartData = [];
  Timer? _timer;
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final List<Message> _messages = [];
  late Stream<List<Message>> _messagesStream;
  String? _userName;
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
    _loadUserProfile();
    _startDataRefresh();
  }

  void _startDataRefresh() {
    _timer?.cancel(); // 기존 타이머 취소
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadUserProfile();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final userData =
          await _supabase.from('profiles').select().eq('id', user.id).single();

      if (mounted) {
        setState(() {
          _userName = userData['username'];
          _userAvatar = userData['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint('프로필 로드 실패: $e');
    }
  }

  void _subscribeToMessages() {
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) => maps.map((map) => Message.fromMap(map)).toList());
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('messages').insert({
        'content': text,
        'user_id': user.id,
        'user_name': _userName ?? '익명',
        'user_avatar': _userAvatar,
        'created_at': DateTime.now().toIso8601String(),
      });
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메시지 전송 실패'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFF2EC4B6).withOpacity(0.1),
                child: Text(
                  widget.code.split('-')[1],
                  style: TextStyle(
                    color: Color(0xFF2EC4B6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                '실시간 종목 토론방',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2EC4B6)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Color(0xFF2EC4B6)),
            onPressed: () {
              // 채팅방 정보 표시
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 차트 영역
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: 250,
            child: ChatChartWidget(
              interval: widget.interval,
              code: widget.code,
            ),
          ),
          // 채팅 목록
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '오류가 발생했습니다\n다시 시도해주세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2EC4B6)),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe =
                        message.userId == _supabase.auth.currentUser?.id;
                    final showAvatar = !isMe &&
                        (index == 0 ||
                            messages[index - 1].userId != message.userId);

                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe && showAvatar) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[200],
                              child: Text(
                                message.userName[0],
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          if (!isMe && !showAvatar) SizedBox(width: 40),
                          Flexible(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Color(0xFF2EC4B6) : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                  bottomLeft: Radius.circular(!isMe ? 0 : 20),
                                  bottomRight: Radius.circular(isMe ? 0 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe && showAvatar)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        message.userName,
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color:
                                          isMe ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Align(
                                    alignment: isMe
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: Text(
                                      _formatTime(message.createdAt),
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.black38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // 입력바
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F9FF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: '메시지를 입력하세요',
                          hintStyle: TextStyle(
                            color: Colors.black38,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF2EC4B6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF2EC4B6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: () {
                        if (_messageController.text.trim().isNotEmpty) {
                          _sendMessage(_messageController.text);
                          _messageController.clear();
                        }
                      },
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

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('HH:mm').format(dateTime);
  }
}

class Message {
  final String id;
  final String content;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.content,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '익명',
      userAvatar: map['user_avatar'],
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ChatChartWidget extends StatefulWidget {
  final int interval;
  final String code;

  const ChatChartWidget({
    super.key,
    required this.interval,
    required this.code,
  });

  @override
  ChatChartWidgetState createState() => ChatChartWidgetState();
}

class ChatChartWidgetState extends State<ChatChartWidget> {
  List<ChartData> chartData = [];
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
    fetchChartData();
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
                            primaryXAxis: DateTimeAxis(
                              majorGridLines: const MajorGridLines(width: 0),
                              axisLine: const AxisLine(width: 0),
                              labelStyle: TextStyle(color: Colors.transparent),
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
