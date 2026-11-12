import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/feedback_response_model.dart';

/// Full-detail viewer for an individual student feedback submission.
class IndividualResponseSheet extends StatelessWidget {
  final FeedbackResponse response;

  const IndividualResponseSheet({
    super.key,
    required this.response,
  });

  static void show(BuildContext context, FeedbackResponse response) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IndividualResponseSheet(response: response),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEEE, MMM dd, yyyy • hh:mm a').format(response.submittedAt);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            response.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${response.registerNumber} • ${response.programme} (${response.yearOfStudy})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),

              // Question-by-Question Response Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Submission Meta Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlueTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available, color: AppColors.primaryNavy, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Submission Timestamp',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                Text(formattedDate,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16, color: AppColors.primaryNavy),
                            tooltip: 'Copy Register Number',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: response.registerNumber));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Register Number copied'), duration: Duration(seconds: 2)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Email & Identity
                    _buildSectionCard(
                      title: 'Student Details',
                      children: [
                        _buildDetailItem('Full Name', response.name),
                        _buildDetailItem('Register Number', response.registerNumber),
                        _buildDetailItem('Email Address', response.email),
                        _buildDetailItem('Programme / Department', response.programme),
                        _buildDetailItem('Year of Study', response.yearOfStudy),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 2. Session Context
                    _buildSectionCard(
                      title: 'Session Verification',
                      children: [
                        _buildDetailItem('Lecture Title', response.lectureTitle),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. Ratings (1 to 5)
                    _buildSectionCard(
                      title: 'Lecture Ratings',
                      children: [
                        _buildRatingRow('Relevance to Course & Studies', response.relevanceRating),
                        const SizedBox(height: 10),
                        _buildRatingRow('Practical Usefulness of Content', response.usefulnessRating),
                        const SizedBox(height: 10),
                        _buildRatingRow('Overall Session Satisfaction', response.satisfactionRating),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 4. Qualitative Feedback & Takeaways
                    _buildSectionCard(
                      title: 'Student Takeaway & Understanding',
                      children: [
                        _buildDetailItem(
                          'Did the lecture improve understanding?',
                          response.understandingImproved,
                          isHighlight: true,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Main Takeaway from Lecture:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            response.mainTakeaway.isNotEmpty ? response.mainTakeaway : 'No takeaway provided.',
                            style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 5. Future Sessions & Topics
                    _buildSectionCard(
                      title: 'Future Alumni Sessions',
                      children: [
                        _buildDetailItem(
                          'Attend more lectures by alumni?',
                          response.attendMore,
                          isHighlight: true,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Requested Future Topics:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: response.futureTopics.map((topic) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlueTint,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Text(
                                topic,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Suggestions for Improvement:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            response.suggestions.isNotEmpty ? response.suggestions : 'None provided.',
                            style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight ? AppColors.secondaryBlue : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String label, int rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text('$rating / 5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            final isFilled = index < rating;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 20,
                color: isFilled ? Colors.amber.shade700 : AppColors.cardBorder,
              ),
            );
          }),
        ),
      ],
    );
  }
}
