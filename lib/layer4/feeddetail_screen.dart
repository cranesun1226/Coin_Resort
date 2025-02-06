import 'package:cr_frontend/etc/feeddata_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedDetailScreen extends StatelessWidget {
  final Feed feed;

  const FeedDetailScreen({super.key, required this.feed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '피드 상세',
          style: TextStyle(
            color: Color(0xFF2D3436),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2EC4B6)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserProfile(),
                    const Divider(height: 40, thickness: 1),
                    _buildTitle(),
                    const SizedBox(height: 24),
                    _buildPriceSection(),
                    const SizedBox(height: 32),
                    _buildReasonSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2EC4B6).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF2EC4B6).withOpacity(0.1),
            child: Text(
              feed.userName.isNotEmpty ? feed.userName[0].toUpperCase() : '',
              style: const TextStyle(
                color: Color(0xFF2EC4B6),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feed.userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(feed.createdAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      feed.title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3436),
        height: 1.3,
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2EC4B6).withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildPriceRow('진입가', feed.entryPrice.toString()),
          const SizedBox(height: 12),
          _buildPriceRow('목표가', feed.targetPrice.toString()),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2D3436),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF2EC4B6),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '매매 이유',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            feed.reason,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF2D3436),
            ),
          ),
        ),
      ],
    );
  }
}
