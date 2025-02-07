// import packages
import 'package:cr_frontend/layer4/feeddetail_screen.dart';
import 'package:cr_frontend/layer4/feedmake_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cr_frontend/etc/feeddata_type.dart';
// import files

class FeedScreen extends StatefulWidget {
  final String code;
  final Feed? feed;

  const FeedScreen({
    super.key,
    required this.code,
    this.feed,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final supabase = Supabase.instance.client;
  late String _selectedTicker;
  final List<String> _tickers = [
    'KRW-BTC',
    'KRW-ETH',
    'KRW-XRP',
    'KRW-DOGE',
    'KRW-SOL',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTicker = widget.code;
  }

  Future<List<Feed>> _getFeeds(String ticker) async {
    final response = await supabase
        .from('${ticker.split('-')[1].toLowerCase()}_feed')
        .select('''
          *,
          profiles (
            username
          )
        ''').order('created_at', ascending: false);

    return (response as List).map((feed) => Feed.fromMap(feed)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F9FF),
      body: Column(
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF2EC4B6).withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF2EC4B6)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreateFeedScreen(code: widget.code),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: _tickers.map((ticker) {
                      bool isSelected = ticker == _selectedTicker;
                      return Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTicker = ticker;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        Color(0xFF2EC4B6),
                                        Color(0xFFFF7F50)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Color(0xFF2EC4B6).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              ticker.split('-')[1],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Color(0xFF2EC4B6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Feed>>(
              future: _getFeeds(_selectedTicker),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final feeds = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: feeds.length,
                  itemBuilder: (context, index) {
                    final feed = feeds[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedDetailScreen(feed: feed),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2EC4B6).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF2EC4B6)
                                        .withOpacity(0.1),
                                    child: Text(
                                      feed.userName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF2EC4B6),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        feed.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        feed.createdAt
                                            .toString()
                                            .substring(0, 16),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                feed.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '진입가: ${feed.entryPrice}',
                                    style: const TextStyle(
                                        color: Color(0xFF2EC4B6)),
                                  ),
                                  Text(
                                    '목표가: ${feed.targetPrice}',
                                    style: const TextStyle(
                                        color: Color(0xFF2EC4B6)),
                                  ),
                                ],
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
          )
        ],
      ),
    );
  }
}
