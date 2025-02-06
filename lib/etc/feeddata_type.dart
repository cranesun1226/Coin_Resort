class Feed {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final double entryPrice;
  final double targetPrice;
  final String reason;
  final DateTime createdAt;

  Feed({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.entryPrice,
    required this.targetPrice,
    required this.reason,
    required this.createdAt,
  });

  factory Feed.fromMap(Map<String, dynamic> map) {
    return Feed(
      id: map['id'],
      userId: map['user_id'],
      userName: map['profiles']['username'] ?? '익명',
      title: map['title'],
      entryPrice: map['entry_price'].toDouble(),
      targetPrice: map['target_price'].toDouble(),
      reason: map['reason'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
