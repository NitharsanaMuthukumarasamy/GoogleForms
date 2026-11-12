import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsPlaceholderScreen extends StatelessWidget {
  const AnalyticsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Analytics'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback export feature will be enabled.')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Feedback Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Aggregated scores across all active and completed sessions',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  _buildRatingBar('Relevance of Topic', 4.8),
                  const SizedBox(height: 12),
                  _buildRatingBar('Practical Usefulness', 4.6),
                  const SizedBox(height: 12),
                  _buildRatingBar('Overall Satisfaction', 4.9),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Top Requested Future Topics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  SizedBox(height: 14),
                  _TopicRow(topic: 'Artificial Intelligence & Machine Learning', count: 96, pct: '65%'),
                  _TopicRow(topic: 'Career Guidance & Placements', count: 82, pct: '55%'),
                  _TopicRow(topic: 'Software Development & Architecture', count: 70, pct: '47%'),
                  _TopicRow(topic: 'Higher Studies & Research Opportunities', count: 45, pct: '30%'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, double rating) {
    final percentage = (rating / 5.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('$rating / 5.0', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: AppColors.lightBlueTint,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryBlue),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String topic;
  final int count;
  final String pct;

  const _TopicRow({required this.topic, required this.count, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(topic, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
          Text('$count votes ($pct)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryBlue)),
        ],
      ),
    );
  }
}
