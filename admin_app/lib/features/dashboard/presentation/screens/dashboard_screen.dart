import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../lectures/data/lecture_export_service.dart';
import '../../../lectures/data/lecture_repository.dart';
import '../../../lectures/domain/feedback_response_model.dart';
import '../../../lectures/domain/lecture_analytics_model.dart';
import '../../../lectures/domain/lecture_model.dart';
import '../../../lectures/presentation/controllers/lecture_controller.dart';

/// Comprehensive Executive Dashboard for Alumni Lecture Feedback System.
///
/// Features:
/// - Academic Year filter
/// - Summary cards: Total lectures, Active lectures, Total responses, Overall average satisfaction
/// - Line Graph 1: Average satisfaction across lectures in date order
/// - Line Graph 2: Average relevance & usefulness across lectures (two lines)
/// - Bar Chart: Number of responses per lecture
/// - Pie Chart: Programme/Department distribution across all lectures
/// - Bar Chart: Most requested future topics across all lectures
/// - Top-rated and lowest-rated lectures ranking
/// - Recent activity timeline
/// - Quick Compare Lectures navigation
/// - Consolidated Academic Year Multi-Sheet Excel Export
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAdminAsync = ref.watch(currentAdminProvider);
    final dashboardDataAsync = ref.watch(dashboardAnalyticsProvider);
    final academicYearFilter = ref.watch(dashboardAcademicYearProvider);
    final availableYears = ref.watch(availableAcademicYearsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          // Export Academic Year .xlsx
          IconButton(
            tooltip: 'Export Academic Year (.xlsx)',
            icon: const Icon(Icons.download_for_offline_rounded),
            onPressed: () => _exportAcademicYearBundle(context, ref, academicYearFilter),
          ),
          // Compare Screen Quick Action
          IconButton(
            tooltip: 'Compare Lectures',
            icon: const Icon(Icons.compare_arrows_rounded),
            onPressed: () => context.push('/lectures/compare'),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryNavy,
        onRefresh: () async {
          ref.invalidate(lecturesStreamProvider);
          ref.invalidate(allResponsesStreamProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // -----------------------------------------------------------------
            // 1. WELCOME BANNER & ACADEMIC YEAR FILTER
            // -----------------------------------------------------------------
            _buildWelcomeBanner(context, ref, currentAdminAsync, academicYearFilter, availableYears),
            const SizedBox(height: 16),

            dashboardDataAsync.when(
              loading: () => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, __) => const CardSkeletonWidget(),
              ),
              error: (err, _) => AppErrorWidget(
                title: 'Unable to Load Dashboard Analytics',
                message: err.toString(),
                onRetry: () {
                  ref.invalidate(lecturesStreamProvider);
                  ref.invalidate(allResponsesStreamProvider);
                },
              ),
              data: (data) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---------------------------------------------------------
                    // 2. SUMMARY METRIC CARDS (4 CARDS)
                    // ---------------------------------------------------------
                    _buildSummaryCards(data),
                    const SizedBox(height: 16),

                    // ---------------------------------------------------------
                    // QUICK ACTION: COMPARE LECTURES BANNER
                    // ---------------------------------------------------------
                    _buildCompareBanner(context),
                    const SizedBox(height: 16),

                    // ---------------------------------------------------------
                    // CONSOLIDATED ACADEMIC YEAR EXCEL EXPORT BANNER
                    // ---------------------------------------------------------
                    _buildAcademicYearExportBanner(context, ref, academicYearFilter),
                    const SizedBox(height: 16),

                    // ---------------------------------------------------------
                    // 3. LINE GRAPH 1: SATISFACTION TREND ACROSS ACADEMIC YEAR
                    // ---------------------------------------------------------
                    _buildSatisfactionTrendCard(data),
                    const SizedBox(height: 16),

                    // ---------------------------------------------------------
                    // 4. LINE GRAPH 2: RELEVANCE & USEFULNESS (TWO LINES)
                    // ---------------------------------------------------------
                    _buildRelevanceUsefulnessTrendCard(data),
                    const SizedBox(height: 16),

                    // ---------------------------------------------------------
                    // 5. BAR CHART: RESPONSES PER LECTURE
                    // ---------------------------------------------------------
                    _buildResponsesPerLectureCard(data),
                    const SizedBox(height: 16),

                    // ---------------------------------------------------------
                    // 6. PIE CHART: PROGRAMME / DEPARTMENT DISTRIBUTION
                    // ---------------------------------------------------------
                    _buildProgrammePieCard(data),
                    const SizedBox(height: 16),

                    // ---------------------------------------------------------
                    // 7. BAR CHART: MOST REQUESTED FUTURE TOPICS
                    // ---------------------------------------------------------
                    _buildMostRequestedTopicsCard(data),
                    const SizedBox(height: 16),

                    // ---------------------------------------------------------
                    // 8. TOP-RATED & LOWEST-RATED LECTURES
                    // ---------------------------------------------------------
                    _buildRatingsRankingsCard(context, data),
                    const SizedBox(height: 16),

                    // ---------------------------------------------------------
                    // 9. RECENT ACTIVITY LIST
                    // ---------------------------------------------------------
                    _buildRecentActivityCard(data),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. WELCOME BANNER WITH ACADEMIC YEAR FILTER
  // ---------------------------------------------------------------------------

  Widget _buildWelcomeBanner(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> currentAdminAsync,
    String academicYearFilter,
    List<String> availableYears,
  ) {
    final admin = currentAdminAsync.value;
    final adminName = admin?.name.isNotEmpty == true ? admin.name : 'Administrator';
    final adminRole = admin?.role.toUpperCase() ?? 'ADMIN';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  adminRole,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // Academic Year Dropdown Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school, size: 14, color: AppColors.primaryNavy),
                    const SizedBox(width: 6),
                    DropdownButton<String>(
                      value: academicYearFilter,
                      underline: const SizedBox(),
                      isDense: true,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      items: availableYears.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year == 'All' ? 'All Academic Years' : 'AY: $year'),
                        );
                      }).toList(),
                      onChanged: (newYear) {
                        if (newYear != null) {
                          ref.read(dashboardAcademicYearProvider.notifier).state = newYear;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome back, $adminName',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          const Text(
            'Executive Overview & Longitudinal Feedback Analytics',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SUMMARY METRIC CARDS (4 CARDS)
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCards(DashboardAnalyticsSummary data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Total Lectures',
                value: '${data.totalLectures}',
                subtitle: 'Registered sessions',
                icon: Icons.event_available_rounded,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Active Lectures',
                value: '${data.activeLectures}',
                subtitle: 'Accepting submissions',
                icon: Icons.play_circle_fill_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Total Responses',
                value: '${data.totalResponses}',
                subtitle: 'Verified students',
                icon: Icons.groups_rounded,
                color: AppColors.secondaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Overall Satisfaction',
                value: '${data.overallAverageSatisfaction.toStringAsFixed(2)} ★',
                subtitle: 'Average across all lectures',
                icon: Icons.star_rounded,
                color: Colors.amber.shade700,
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
            const SizedBox(height: 8),
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

  Widget _buildCompareBanner(BuildContext context) {
    return Card(
      color: AppColors.lightBlueTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.compare_arrows_rounded, color: AppColors.primaryNavy),
        ),
        title: const Text('Compare Lectures Side-by-Side', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
        subtitle: const Text('Analyze grouped bar charts and comparative ratings across sessions', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryNavy),
        onTap: () => context.push('/lectures/compare'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. LINE GRAPH 1: SATISFACTION TREND ACROSS ACADEMIC YEAR
  // ---------------------------------------------------------------------------

  Widget _buildSatisfactionTrendCard(DashboardAnalyticsSummary data) {
    final points = data.satisfactionTrend;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Average Satisfaction Across Academic Year',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 2),
            const Text(
              'Chronological progression of overall student satisfaction per lecture (1.0 - 5.0 scale)',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            if (points.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No lectures available in selected academic year.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: 1.0,
                    maxY: 5.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          interval: 1,
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
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < points.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormat('MM/dd').format(points[idx].dateTime),
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
                            final pt = points[idx];
                            return LineTooltipItem(
                              '${pt.title}\n${pt.averageSatisfaction.toStringAsFixed(2)} ★ (${pt.responseCount} resp)',
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
                            FlSpot(i.toDouble(), points[i].averageSatisfaction.clamp(1.0, 5.0)),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: Colors.amber.shade700,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeColor: Colors.amber.shade700,
                            strokeWidth: 2,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade700.withOpacity(0.2),
                              Colors.amber.shade700.withOpacity(0.0),
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
  // 4. LINE GRAPH 2: RELEVANCE & USEFULNESS (TWO LINES)
  // ---------------------------------------------------------------------------

  Widget _buildRelevanceUsefulnessTrendCard(DashboardAnalyticsSummary data) {
    final points = data.relevanceUsefulnessTrend;
    const colorRelevance = AppColors.secondaryBlue;
    const colorUsefulness = Color(0xFF0284C7);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relevance vs Usefulness Trend',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Curriculum alignment vs practical industry value',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                // Legend
                Row(
                  children: [
                    _buildLegendDot('Relevance', colorRelevance),
                    const SizedBox(width: 10),
                    _buildLegendDot('Usefulness', colorUsefulness),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (points.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No lectures available in selected academic year.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: 1.0,
                    maxY: 5.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          interval: 1,
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
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < points.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormat('MM/dd').format(points[idx].dateTime),
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
                          if (touchedSpots.isEmpty) return [];
                          final idx = touchedSpots.first.spotIndex;
                          final pt = points[idx];
                          return [
                            LineTooltipItem(
                              '${pt.title}\nRelevance: ${pt.averageRelevance.toStringAsFixed(2)}\nUsefulness: ${pt.averageUsefulness.toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ];
                        },
                      ),
                    ),
                    lineBarsData: [
                      // Relevance Line
                      LineChartBarData(
                        spots: [
                          for (int i = 0; i < points.length; i++)
                            FlSpot(i.toDouble(), points[i].averageRelevance.clamp(1.0, 5.0)),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: colorRelevance,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: true),
                      ),
                      // Usefulness Line
                      LineChartBarData(
                        spots: [
                          for (int i = 0; i < points.length; i++)
                            FlSpot(i.toDouble(), points[i].averageUsefulness.clamp(1.0, 5.0)),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: colorUsefulness,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: true),
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
  // 5. BAR CHART: NUMBER OF RESPONSES PER LECTURE
  // ---------------------------------------------------------------------------

  Widget _buildResponsesPerLectureCard(DashboardAnalyticsSummary data) {
    final list = data.responsesPerLecture;
    int maxCount = 0;
    for (final item in list) {
      if (item.value > maxCount) maxCount = item.value;
    }
    if (maxCount == 0) maxCount = 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Responses per Lecture',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 2),
            const Text(
              'Total verified student attendance and submissions per lecture',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            if (list.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No response records found.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    maxY: (maxCount * 1.25).ceilToDouble(),
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                    ),
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
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < list.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'L${idx + 1}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final item = list[group.x.toInt()];
                          return BarTooltipItem(
                            '${item.key}\n${item.value} student submissions',
                            const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < list.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: list[i].value.toDouble(),
                              color: AppColors.primaryNavy,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
  // 6. PIE CHART: PROGRAMME / DEPARTMENT ACROSS ALL LECTURES
  // ---------------------------------------------------------------------------

  Widget _buildProgrammePieCard(DashboardAnalyticsSummary data) {
    final dist = data.programmeDistribution;
    final total = data.totalResponses;
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
            const Text(
              'Responses by Programme / Department',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 2),
            const Text(
              'Cumulative academic representation across all lecture sessions',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            if (dist.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No programme data recorded.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ),
              )
            else
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                        sections: [
                          for (int i = 0; i < entries.length; i++)
                            PieChartSectionData(
                              value: entries[i].value.toDouble(),
                              color: colors[i % colors.length],
                              radius: 38,
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
                        for (int i = 0; i < entries.length; i++) ...[
                          Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entries[i].key,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${total > 0 ? ((entries[i].value / total) * 100).toStringAsFixed(1) : 0}%',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                              ),
                            ],
                          ),
                          if (i < entries.length - 1) const SizedBox(height: 5),
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
  // 7. BAR CHART: MOST REQUESTED FUTURE TOPICS ACROSS ALL LECTURES
  // ---------------------------------------------------------------------------

  Widget _buildMostRequestedTopicsCard(DashboardAnalyticsSummary data) {
    final topics = data.mostRequestedTopics;
    final total = data.totalResponses;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Requested Future Topics (All Lectures)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 2),
            const Text(
              'Overall student demand across the curriculum for future alumni sessions',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            if (topics.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No topic preferences recorded.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ),
              )
            else
              Column(
                children: [
                  for (final item in topics.take(6)) ...[
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
                                '${item.value} requests (${total > 0 ? ((item.value / total) * 100).toStringAsFixed(1) : 0}%)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total > 0 ? (item.value / total).clamp(0.0, 1.0) : 0,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. TOP-RATED & LOWEST-RATED LECTURES
  // ---------------------------------------------------------------------------

  Widget _buildRatingsRankingsCard(BuildContext context, DashboardAnalyticsSummary data) {
    final top = data.topRatedLectures;
    final lowest = data.lowestRatedLectures;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lecture Ratings Spotlight',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 2),
            const Text(
              'Top and lowest rated lectures by average student satisfaction score',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Top Rated Spotlight
            const Row(
              children: [
                Icon(Icons.emoji_events_rounded, size: 16, color: Colors.amber),
                SizedBox(width: 6),
                Text('Top-Rated Lectures', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
              ],
            ),
            const SizedBox(height: 8),

            if (top.isEmpty)
              const Text('No rated lectures yet.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary))
            else
              ...top.map((lec) => _buildRankedItem(context, lec, isTop: true)),

            const Divider(height: 24),

            // Lowest Rated Spotlight
            const Row(
              children: [
                Icon(Icons.priority_high_rounded, size: 16, color: AppColors.error),
                SizedBox(width: 6),
                Text('Opportunities for Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
              ],
            ),
            const SizedBox(height: 8),

            if (lowest.isEmpty)
              const Text('No rated lectures yet.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary))
            else
              ...lowest.map((lec) => _buildRankedItem(context, lec, isTop: false)),
          ],
        ),
      ),
    );
  }

  Widget _buildRankedItem(BuildContext context, LectureRatingTrendPoint lec, {required bool isTop}) {
    return InkWell(
      onTap: () => context.push('/lectures/${lec.lectureId}?tab=analytics'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lec.title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${lec.speakerName} • ${lec.responseCount} responses',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isTop ? AppColors.lightBlueTint : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isTop ? AppColors.primaryNavy.withOpacity(0.2) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    lec.averageSatisfaction.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isTop ? AppColors.primaryNavy : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: isTop ? Colors.amber.shade700 : AppColors.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. RECENT ACTIVITY LIST
  // ---------------------------------------------------------------------------

  Widget _buildRecentActivityCard(DashboardAnalyticsSummary data) {
    final activities = data.recentActivities;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent System Activity',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 2),
            const Text('Latest lectures and event milestones', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 14),

            if (activities.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No recent activity recorded.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, idx) {
                  final act = activities[idx];
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlueTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(act.icon, size: 16, color: act.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.title,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(act.subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM').format(act.timestamp),
                        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontFamily: 'monospace'),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
      ],
    );
  }

  Widget _buildAcademicYearExportBanner(BuildContext context, WidgetRef ref, String academicYear) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF107C41).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.table_view_rounded, color: Color(0xFF107C41), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Year Report ($academicYear)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Export consolidated multi-sheet workbook with summary & all responses',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF107C41),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Export .xlsx', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _exportAcademicYearBundle(context, ref, academicYear),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAcademicYearBundle(BuildContext context, WidgetRef ref, String academicYear) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing Academic Year ($academicYear) Excel bundle...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final allLectures = ref.read(allLecturesStreamProvider).value ?? [];
      final lectures = academicYear == 'All'
          ? allLectures
          : allLectures.where((l) => l.academicYear == academicYear).toList();

      if (lectures.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No lectures found for this academic year to export.')),
          );
        }
        return;
      }

      final repo = ref.read(lectureRepositoryProvider);
      final responsesByLectureId = <String, List<FeedbackResponse>>{};

      for (final lecture in lectures) {
        final resps = await repo.getResponses(lecture.id);
        responsesByLectureId[lecture.id] = resps;
      }

      await LectureExportService.exportAcademicYearToExcel(
        academicYear: academicYear,
        lectures: lectures,
        responsesByLectureId: responsesByLectureId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export bundle: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showSignOutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Confirm Sign Out',
      message: 'Are you sure you want to log out of the administrator portal?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );

    if (confirmed) {
      ref.read(authControllerProvider.notifier).logout();
    }
  }
}
