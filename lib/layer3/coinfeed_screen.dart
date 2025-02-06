// dart
import 'package:cr_frontend/etc/feeddata_type.dart';
import 'package:cr_frontend/layer4/feeddetail_screen.dart';
import 'package:cr_frontend/layer4/feedmake_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoinFeedScreen extends StatefulWidget {
  final String code;

  const CoinFeedScreen({super.key, required this.code});

  @override
  State<CoinFeedScreen> createState() => _CoinFeedScreenState();
}

class _CoinFeedScreenState extends State<CoinFeedScreen> {
  final supabase = Supabase.instance.client;
  late Future<List<Feed>> _feedsFuture;

  @override
  void initState() {
    super.initState();
    _feedsFuture = _fetchFeeds();
  }

  Future<List<Feed>> _fetchFeeds() async {
    try {
      final List<dynamic> response = await supabase
          .from('${widget.code.split('-')[1].toLowerCase()}_feed')
          .select(
              'id, user_id, title, entry_price, target_price, reason, created_at, profiles:user_id (username)')
          .order('created_at', ascending: false);

      return response
          .map((e) => Feed.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('피드를 불러오는데 실패했습니다: $e');
    }
  }

  void _onFeedTap(Feed feed) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedDetailScreen(feed: feed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '코인 피드',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2EC4B6)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF2EC4B6)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateFeedScreen(code: widget.code),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Feed>>(
        future: _feedsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2EC4B6)),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('에러 발생: ${snapshot.error}'));
          }

          final feeds = snapshot.data ?? [];

          if (feeds.isEmpty) {
            return const Center(child: Text('등록된 피드가 없습니다.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: feeds.length,
            itemBuilder: (context, index) {
              final feed = feeds[index];
              return GestureDetector(
                onTap: () => _onFeedTap(feed),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              const Color(0xFF2EC4B6).withOpacity(0.1),
                          child: Text(
                            feed.userName.isNotEmpty
                                ? feed.userName[0].toUpperCase()
                                : '',
                            style: const TextStyle(color: Color(0xFF2EC4B6)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feed.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2EC4B6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '목표가: ${feed.targetPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                feed.userName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
