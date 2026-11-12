import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LecturesPlaceholderScreen extends StatelessWidget {
  const LecturesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Lectures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Lecture'),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lecture creation module ready to be implemented.')),
          );
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filter Tabs
          Row(
            children: [
              _buildFilterChip('All (14)', isSelected: true),
              const SizedBox(width: 8),
              _buildFilterChip('Active (2)', isSelected: false),
              const SizedBox(width: 8),
              _buildFilterChip('Closed (12)', isSelected: false),
            ],
          ),
          const SizedBox(height: 16),

          // Sample Lecture Cards
          _buildLectureCard(
            title: 'Modern Generative AI Architecture & LLM Ops',
            speaker: 'Dr. Rajesh Kumar (Class of 2015)',
            company: 'Principal AI Scientist, Google Cloud',
            department: 'MCA / Computer Science',
            status: 'active',
            responses: 84,
            date: 'Today, 10:30 AM',
          ),
          const SizedBox(height: 12),
          _buildLectureCard(
            title: 'Scalable Microservices with Flutter & Firebase',
            speaker: 'Priya Sundaram (Class of 2018)',
            company: 'Senior Mobile Lead, Atlassian',
            department: 'B.Sc. Computer Systems & Design',
            status: 'active',
            responses: 64,
            date: 'Today, 02:00 PM',
          ),
          const SizedBox(height: 12),
          _buildLectureCard(
            title: 'Navigating Campus Placements to Global Tech Careers',
            speaker: 'Arun Varma (Class of 2020)',
            company: 'Software Engineer, Microsoft',
            department: 'BCA / All Streams',
            status: 'closed',
            responses: 112,
            date: 'Nov 04, 2026',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryNavy : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primaryNavy : AppColors.cardBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLectureCard({
    required String title,
    required String speaker,
    required String company,
    required String department,
    required String status,
    required int responses,
    required String date,
  }) {
    final isActive = status == 'active';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.textTertiary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: isActive ? AppColors.success : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_pin, size: 16, color: AppColors.secondaryBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$speaker • $company',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$responses Student Responses',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentBlue,
                  ),
                ),
                Row(
                  children: const [
                    Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.primaryNavy),
                    SizedBox(width: 4),
                    Text(
                      'QR Form',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
