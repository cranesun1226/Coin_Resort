// import packages
import 'dart:async';
import 'package:cr_frontend/layer3/smallchart_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
          _userAvatar = userData['profile_img'];
        });
      }
    } catch (e) {
      debugPrint('프로필 로드 실패: $e');
    }
  }

  void _subscribeToMessages() {
    _messagesStream = _supabase
        .from('${widget.code.split('-')[1].toLowerCase()}_message')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) => maps.map((map) => Message.fromMap(map)).toList());
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('${widget.code.split('-')[1].toLowerCase()}_message')
          .insert({
        'content': text,
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      });
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메시지 전송 실패: $e'),
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
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2EC4B6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.code.split('-')[1],
                style: const TextStyle(
                  color: Color(0xFF2EC4B6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '실시간 종목 토론방',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2EC4B6)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 차트 영역
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: 250,
            child: SmallChartWidget(
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
