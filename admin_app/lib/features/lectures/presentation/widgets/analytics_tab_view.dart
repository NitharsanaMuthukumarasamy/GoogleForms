import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/feedback_response_model.dart';
import '../../domain/lecture_analytics_model.dart';
import '../../domain/lecture_model.dart';
import '../controllers/lecture_controller.dart';

/// Google Forms-style analytics dashboard for a single lecture.
class AnalyticsTabView extends ConsumerStatefulWidget {
  final Lecture lecture;

  const AnalyticsTabView({
    super.key,
    required this.lecture,
  });

  @override
  ConsumerState<AnalyticsTabView> createState() => _AnalyticsTabViewState();
}

class _AnalyticsTabViewState extends ConsumerState<AnalyticsTabView> {
  final TextEditingController _takeawaySearchController = TextEditingController();
  final TextEditingController _suggestionSearchController = TextEditingController();

  String _takeawaySearch = '';
  String _suggestionSearch = '';
  int? _touchedPieIndex;

  @override
  void dispose() {
    _takeawaySearchController.dispose();
    _suggestionSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lectureId = widget.lecture.id;
    final analyticsAsync = ref.watch(singleLectureAnalyticsProvider(lectureId));
    final timePeriod = ref.watch(timeSeriesPeriodProvider);

    return RefreshIndicator(
      color: AppColors.primaryNavy,
      onRefresh: () async {
        ref.invalidate(lectureResponsesStreamProvider(lectureId));
      },
      child: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Error loading analytics: $err', style: const TextStyle(color: AppColors.error)),
          ),
        ),
        data: (summary) {
          if (summary.totalResponses == 0) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              children: [
                const SizedBox(height: 60),
                const Icon(Icons.analytics_outlined, size: 64, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                const Text(
                  'No Analytics Available Yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Student feedback responses will automatically generate charts and score summaries here in real time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Center(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    onPressed: () => ref.invalidate(lectureResponsesStreamProvider(lectureId)),
                  ),
                ),
              ],
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              // ---------------------------------------------------------------
              // 1. TOP SUMMARY METRIC CARDS
              // ---------------------------------------------------------------
              _buildTopSummaryCards(summary),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 2. LINE GRAPH: RESPONSES OVER TIME (HOURLY / DAILY SWITCHABLE)
              // ---------------------------------------------------------------
              _buildResponsesOverTimeCard(summary, timePeriod),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 3. PROGRAMME / DEPARTMENT PIE CHART
              // ---------------------------------------------------------------
              _buildProgrammePieCard(summary),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 4. YEAR OF STUDY BAR CHART (I TO V YEAR)
              // ---------------------------------------------------------------
              _buildYearOfStudyBarCard(summary),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 5. RATING SCALES: RELEVANCE (1-5)
              // ---------------------------------------------------------------
              _buildRatingCard(
                title: 'Relevance to Course & Curriculum',
                subtitle: 'How closely the content aligned with academic syllabus',
                average: summary.averageRelevance,
                distribution: summary.relevanceDistribution,
                total: summary.totalResponses,
                barColor: AppColors.secondaryBlue,
              ),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 6. RATING SCALES: USEFULNESS (1-5)
              // ---------------------------------------------------------------
              _buildRatingCard(
                title: 'Practical Usefulness of Content',
                subtitle: 'Applicability to industry, career, and practical skills',
                average: summary.averageUsefulness,
                distribution: summary.usefulnessDistribution,
                total: summary.totalResponses,
                barColor: const Color(0xFF0284C7),
              ),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 7. UNDERSTANDING IMPROVED (PIE CHART - 4 OPTIONS)
              // ---------------------------------------------------------------
              _buildUnderstandingPieCard(summary),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 8. WOULD YOU ATTEND MORE LECTURES (PIE CHART)
              // ---------------------------------------------------------------
              _buildAttendMorePieCard(summary),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 9. FUTURE TOPICS (SORTED HORIZONTAL BARS WITH % PER RESPONDENT)
              // ---------------------------------------------------------------
              _buildFutureTopicsCard(summary),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 10. OVERALL SATISFACTION (1-5)
              // ---------------------------------------------------------------
              _buildRatingCard(
                title: 'Overall Session Satisfaction',
                subtitle: 'Overall student experience and lecture effectiveness',
                average: summary.averageSatisfaction,
                distribution: summary.satisfactionDistribution,
                total: summary.totalResponses,
                barColor: AppColors.primaryNavy,
                isHighlight: true,
              ),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 11. MAIN TAKEAWAYS (COMMENTS + KEYWORD CHIPS)
              // ---------------------------------------------------------------
              _buildQualitativeSection(
                title: 'Key Student Takeaways',
                subtitle: '${summary.mainTakeaways.length} written responses received',
                icon: Icons.lightbulb_outline,
                comments: summary.mainTakeaways,
                topWords: summary.commonTakeawayWords,
                searchController: _takeawaySearchController,
                currentSearch: _takeawaySearch,
                onSearchChanged: (val) => setState(() => _takeawaySearch = val),
              ),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 12. SUGGESTIONS (COMMENTS + KEYWORD CHIPS)
              // ---------------------------------------------------------------
              _buildQualitativeSection(
                title: 'Student Suggestions for Improvement',
                subtitle: '${summary.suggestions.length} suggestions received',
                icon: Icons.rate_review_outlined,
                comments: summary.suggestions,
                topWords: summary.commonSuggestionWords,
                searchController: _suggestionSearchController,
                currentSearch: _suggestionSearch,
                onSearchChanged: (val) => setState(() => _suggestionSearch = val),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP SUMMARY CARDS
  // ---------------------------------------------------------------------------

  Widget _buildTopSummaryCards(LectureAnalyticsSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Total Responses',
                value: '${summary.totalResponses}',
                subtitle: 'Verified submissions',
                icon: Icons.groups_rounded,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Overall Satisfaction',
                value: '${summary.averageSatisfaction.toStringAsFixed(2)} ★',
                subtitle: 'Out of 5.0 scale',
                icon: Icons.star_rounded,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Avg Relevance',
                value: '${summary.averageRelevance.toStringAsFixed(2)} / 5',
                subtitle: 'Curriculum alignment',
                icon: Icons.verified_outlined,
                color: AppColors.secondaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Avg Usefulness',
                value: '${summary.averageUsefulness.toStringAsFixed(2)} / 5',
                subtitle: 'Practical value',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. LINE GRAPH: RESPONSES OVER TIME
  // ---------------------------------------------------------------------------

  Widget _buildResponsesOverTimeCard(LectureAnalyticsSummary summary, String timePeriod) {
    final points = timePeriod == 'hour' ? summary.hourlyTimeSeries : summary.dailyTimeSeries;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Responses Over Time',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Submission velocity (${timePeriod == 'hour' ? 'Per Hour' : 'Per Day'})',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'hour', label: Text('Hour', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'day', label: Text('Day', style: TextStyle(fontSize: 11))),
                  ],
                  selected: {timePeriod},
                  onSelectionChanged: (val) {
                    ref.read(timeSeriesPeriodProvider.notifier).state = val.first;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (points.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Not enough submissions to plot timeline.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (val, _) => Text(
                            val.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: (points.length / 4).ceilToDouble().clamp(1.0, 999.0),
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < points.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  points[idx].label,
                                  style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.spotIndex;
                            final point = points[idx];
                            return LineTooltipItem(
                              '${point.label}\n${point.count} responses',
                              const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (int i = 0; i < points.length; i++)
                            FlSpot(i.toDouble(), points[i].count.toDouble()),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: AppColors.secondaryBlue,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: points.length <= 15,
                          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeColor: AppColors.secondaryBlue,
                            strokeWidth: 2,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondaryBlue.withOpacity(0.25),
                              AppColors.secondaryBlue.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. PROGRAMME PIE CHART
  // ---------------------------------------------------------------------------

  Widget _buildProgrammePieCard(LectureAnalyticsSummary summary) {
    final dist = summary.programmeDistribution;
    final total = summary.totalResponses;
    const colors = [
      Color(0xFF0B2545),
      Color(0xFF134074),
      Color(0xFF0284C7),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
    ];

    final entries = dist.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionHeader(
              questionNumber: 'Question 1',
              title: 'Programme / Department',
              totalAnswered: total,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Pie Chart Donut
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedPieIndex = null;
                              return;
                            }
                            _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: [
                        for (int i = 0; i < entries.length; i++)
                          PieChartSectionData(
                            value: entries[i].value.toDouble(),
                            color: colors[i % colors.length],
                            radius: _touchedPieIndex == i ? 46 : 40,
                            title: '',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Legend with percentages
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < entries.length; i++) ...[
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entries[i].key,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${((entries[i].value / total) * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                            ),
                          ],
                        ),
                        if (i < entries.length - 1) const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. YEAR OF STUDY BAR CHART
  // ---------------------------------------------------------------------------

  Widget _buildYearOfStudyBarCard(LectureAnalyticsSummary summary) {
    final dist = summary.yearDistribution;
    final total = summary.totalResponses;
    final years = FeedbackConstants.yearsOfStudy;

    int maxCount = 0;
    for (final y in years) {
      if ((dist[y] ?? 0) > maxCount) maxCount = dist[y] ?? 0;
    }
    if (maxCount == 0) maxCount = 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionHeader(
              questionNumber: 'Question 2',
              title: 'Year of Study',
              totalAnswered: total,
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxCount * 1.2).ceilToDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (val, _) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < years.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                years[idx].replaceAll(' Year', ''),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final yr = years[group.x.toInt()];
                        final count = dist[yr] ?? 0;
                        final pct = total > 0 ? ((count / total) * 100).toStringAsFixed(1) : '0';
                        return BarTooltipItem(
                          '$yr\n$count students ($pct%)',
                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < years.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (dist[years[i]] ?? 0).toDouble(),
                            color: AppColors.secondaryBlue,
                            width: 18,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5, 6, 10: RATING SCALE CARDS (RELEVANCE, USEFULNESS, SATISFACTION)
  // ---------------------------------------------------------------------------

  Widget _buildRatingCard({
    required String title,
    required String subtitle,
    required double average,
    required Map<int, int> distribution,
    required int total,
    required Color barColor,
    bool isHighlight = false,
  }) {
    int maxCount = 0;
    for (int r = 1; r <= 5; r++) {
      if ((distribution[r] ?? 0) > maxCount) maxCount = distribution[r] ?? 0;
    }
    if (maxCount == 0) maxCount = 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlueTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$total answered',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Large Average Score Display + Distribution Bars
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Big Average Score Box
                Container(
                  width: 95,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isHighlight ? AppColors.lightBlueTint : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        average.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isHighlight ? AppColors.primaryNavy : barColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          const Text(
                            'out of 5',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // 1 to 5 Score Distribution Bars
                Expanded(
                  child: Column(
                    children: [
                      for (int score = 5; score >= 1; score--) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '$score ★',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: total > 0 ? (distribution[score] ?? 0) / total : 0,
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${distribution[score] ?? 0}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        if (score > 1) const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. UNDERSTANDING IMPROVED PIE CHART
  // ---------------------------------------------------------------------------

  Widget _buildUnderstandingPieCard(LectureAnalyticsSummary summary) {
    final dist = summary.understandingDistribution;
    final total = summary.totalResponses;
    const colors = {
      'Yes, significantly': Color(0xFF10B981),
      'Yes, to some extent': Color(0xFF0284C7),
      'Not much': Color(0xFFF59E0B),
      'No': Color(0xFFEF4444),
    };

    final entries = dist.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionHeader(
              questionNumber: 'Question 5',
              title: 'Did the lecture improve your understanding?',
              totalAnswered: total,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: [
                        for (final e in entries)
                          PieChartSectionData(
                            value: e.value.toDouble(),
                            color: colors[e.key] ?? AppColors.textTertiary,
                            radius: 40,
                            title: '',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in entries) ...[
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[e.key] ?? AppColors.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${total > 0 ? ((e.value / total) * 100).toStringAsFixed(1) : 0}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. WOULD YOU ATTEND MORE LECTURES PIE CHART
  // ---------------------------------------------------------------------------

  Widget _buildAttendMorePieCard(LectureAnalyticsSummary summary) {
    final dist = summary.attendMoreDistribution;
    final total = summary.totalResponses;
    const colors = {
      'Definitely': Color(0xFF10B981),
      'Probably': Color(0xFF0284C7),
      'Maybe': Color(0xFFF59E0B),
      'No': Color(0xFFEF4444),
    };

    final entries = dist.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionHeader(
              questionNumber: 'Question 7',
              title: 'Would you like to attend more lectures by alumni?',
              totalAnswered: total,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: [
                        for (final e in entries)
                          PieChartSectionData(
                            value: e.value.toDouble(),
                            color: colors[e.key] ?? AppColors.textTertiary,
                            radius: 40,
                            title: '',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in entries) ...[
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[e.key] ?? AppColors.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${total > 0 ? ((e.value / total) * 100).toStringAsFixed(1) : 0}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. FUTURE TOPICS (SORTED HORIZONTAL BARS WITH % PER RESPONDENT)
  // ---------------------------------------------------------------------------

  Widget _buildFutureTopicsCard(LectureAnalyticsSummary summary) {
    final topics = summary.sortedTopics;
    final total = summary.totalResponses;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionHeader(
              questionNumber: 'Question 8',
              title: 'Which topics would you like in future sessions?',
              totalAnswered: total,
            ),
            const SizedBox(height: 4),
            const Text(
              'Multi-select checkboxes. Percentages show proportion of respondents who selected each topic.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            if (topics.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No topic preferences recorded.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ),
              )
            else
              Column(
                children: [
                  for (final item in topics) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.key,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                                ),
                              ),
                              Text(
                                '${item.value} (${total > 0 ? ((item.value / total) * 100).toStringAsFixed(1) : 0}%)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total > 0 ? (item.value / total).clamp(0.0, 1.0) : 0,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 11 & 12. QUALITATIVE SECTION: COMMENTS & KEYWORDS
  // ---------------------------------------------------------------------------

  Widget _buildQualitativeSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> comments,
    required List<MapEntry<String, int>> topWords,
    required TextEditingController searchController,
    required String currentSearch,
    required ValueChanged<String> onSearchChanged,
  }) {
    final filtered = currentSearch.isEmpty
        ? comments
        : comments.where((c) => c.toLowerCase().contains(currentSearch.toLowerCase())).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryNavy),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Top Keywords Chips
            if (topWords.isNotEmpty) ...[
              const Text(
                'Most frequent keywords:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: topWords.map((entry) {
                  return InkWell(
                    onTap: () {
                      searchController.text = entry.key;
                      onSearchChanged(entry.key);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlueTint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        '${entry.key} (${entry.value})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Search Filter
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search within responses...',
                  hintStyle: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                  suffixIcon: currentSearch.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(height: 12),

            // Scrollable Comments List
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No comments match your search.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 14),
                  itemBuilder: (context, idx) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.format_quote_rounded, size: 14, color: AppColors.secondaryBlue),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            filtered[idx],
                            style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader({
    required String questionNumber,
    required String title,
    required int totalAnswered,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                questionNumber.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.lightBlueTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$totalAnswered responses',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
          ),
        ),
      ],
    );
  }
}
