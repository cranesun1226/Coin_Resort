// import packages
import 'package:flutter/material.dart';
// import files
import 'package:cr_frontend/layer3/coinchat_screen.dart';

class ChatInfoCard extends StatefulWidget {
  final String code;
  final int interval;

  const ChatInfoCard({
    super.key,
    required this.code,
    required this.interval,
  });

  @override
  State<ChatInfoCard> createState() => _ChatInfoCardState();
}

class _ChatInfoCardState extends State<ChatInfoCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              code: widget.code,
              interval: widget.interval,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Color(0xFF2EC4B6).withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2EC4B6).withOpacity(0.06),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2EC4B6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF2EC4B6),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '실시간 종목 토론방으로 이동',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF2EC4B6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
