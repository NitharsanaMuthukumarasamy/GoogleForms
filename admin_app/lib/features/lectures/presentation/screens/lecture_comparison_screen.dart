import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/lecture_analytics_model.dart';
import '../../domain/lecture_model.dart';
import '../controllers/lecture_controller.dart';

/// Screen allowing administrators to select 2 or more lectures
/// and view side-by-side grouped bar charts and comparison tables.
class LectureComparisonScreen extends ConsumerStatefulWidget {
  const LectureComparisonScreen({super.key});

  @override
  ConsumerState<LectureComparisonScreen> createState() => _LectureComparisonScreenState();
}

class _LectureComparisonScreenState extends ConsumerState<LectureComparisonScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lecturesAsync = ref.watch(lecturesStreamProvider);
    final selectedIds = ref.watch(selectedCompareLectureIdsProvider);
    final comparisonItems = ref.watch(lectureComparisonDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Lectures'),
        actions: [
          if (selectedIds.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(selectedCompareLectureIdsProvider.notifier).state = {};
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: lecturesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading lectures: $err')),
        data: (allLectures) {
          final filteredLectures = _searchQuery.isEmpty
              ? allLectures
              : allLectures.where((l) {
                  final q = _searchQuery.toLowerCase();
                  return l.title.toLowerCase().contains(q) ||
                      l.speakerName.toLowerCase().contains(q) ||
                      l.academicYear.toLowerCase().contains(q);
                }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---------------------------------------------------------------
              // 1. LECTURE PICKER CARD (MULTI-SELECT)
              // ---------------------------------------------------------------
              Card(
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
                                'Select Lectures to Compare',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Choose 2 or more lectures for side-by-side analytics',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: selectedIds.length >= 2 ? AppColors.success.withOpacity(0.12) : AppColors.lightBlueTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${selectedIds.length} Selected',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: selectedIds.length >= 2 ? AppColors.success : AppColors.primaryNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Search Box for Lectures
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Search lectures by title, speaker, or year...',
                            hintStyle: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 14),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Selectable Lecture Chips
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: filteredLectures.map((lec) {
                              final isSelected = selectedIds.contains(lec.id);
                              return FilterChip(
                                selected: isSelected,
                                selectedColor: AppColors.lightBlueTint,
                                checkmarkColor: AppColors.primaryNavy,
                                side: BorderSide(
                                  color: isSelected ? AppColors.secondaryBlue : AppColors.cardBorder,
                                ),
                                label: Text(
                                  '${lec.title} (${lec.speakerName})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primaryNavy : AppColors.textPrimary,
                                  ),
                                ),
                                onSelected: (selected) {
                                  final newSet = Set<String>.from(selectedIds);
                                  if (selected) {
                                    newSet.add(lec.id);
                                  } else {
                                    newSet.remove(lec.id);
                                  }
                                  ref.read(selectedCompareLectureIdsProvider.notifier).state = newSet;
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // 2. COMPARISON VIEW (REQUIRES >= 2 LECTURES)
              // ---------------------------------------------------------------
              if (selectedIds.length < 2) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.compare_arrows_rounded, size: 48, color: AppColors.textTertiary),
                        SizedBox(height: 12),
                        Text(
                          'Select at least 2 lectures',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Choose two or more lectures from the selector above to compare student ratings, satisfaction, and feedback side-by-side.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // -------------------------------------------------------------
                // A. GROUPED BAR CHART
                // -------------------------------------------------------------
                _buildGroupedBarChartCard(comparisonItems),
                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // B. DETAILED COMPARISON TABLE
                // -------------------------------------------------------------
                _buildComparisonTableCard(comparisonItems),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GROUPED BAR CHART CARD
  // ---------------------------------------------------------------------------

  Widget _buildGroupedBarChartCard(List<LectureComparisonItem> items) {
    const colorRelevance = AppColors.secondaryBlue;
    const colorUsefulness = Color(0xFF0284C7);
    const colorSatisfaction = AppColors.primaryNavy;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ratings Comparison (1 - 5 Scale)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 4),
            const Text(
              'Side-by-side grouped bars for average Relevance, Usefulness, and Overall Satisfaction',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Color Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Relevance', colorRelevance),
                const SizedBox(width: 14),
                _buildLegendItem('Usefulness', colorUsefulness),
                const SizedBox(width: 14),
                _buildLegendItem('Satisfaction', colorSatisfaction),
              ],
            ),
            const SizedBox(height: 20),

            // Grouped Bar Chart
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: 5.2,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
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
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < items.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'L${idx + 1}',
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
                        final item = items[group.x.toInt()];
                        final metric = rodIndex == 0
                            ? 'Relevance'
                            : rodIndex == 1
                                ? 'Usefulness'
                                : 'Satisfaction';
                        final score = rod.toY.toStringAsFixed(2);
                        return BarTooltipItem(
                          '${item.lecture.title}\n$metric: $score / 5.0',
                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < items.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: items[i].averageRelevance,
                            color: colorRelevance,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: items[i].averageUsefulness,
                            color: colorUsefulness,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: items[i].averageSatisfaction,
                            color: colorSatisfaction,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Lecture Index Key (L1, L2, etc.)
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (int i = 0; i < items.length; i++)
                  Text(
                    'L${i + 1}: ${items[i].lecture.title}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMPARISON TABLE CARD
  // ---------------------------------------------------------------------------

  Widget _buildComparisonTableCard(List<LectureComparisonItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparative Performance Table',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 2),
            const Text(
              'Metrics include overall satisfaction, relevance, usefulness, and repeat attendance intent',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Horizontally Scrollable Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                columnSpacing: 18,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Lecture & Speaker',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Responses',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Relevance (1-5)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Usefulness (1-5)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Satisfaction (1-5)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '"Definitely" Attend %',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                  ),
                ],
                rows: items.map((item) {
                  return DataRow(
                    cells: [
                      // Lecture Title & Speaker
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.lecture.title,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                            ),
                            Text(
                              '${item.lecture.speakerName} • ${DateFormat('dd MMM yy').format(item.lecture.dateTime)}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),

                      // Responses
                      DataCell(
                        Text(
                          '${item.totalResponses}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),

                      // Relevance
                      DataCell(
                        _buildMetricCell(item.averageRelevance, AppColors.secondaryBlue),
                      ),

                      // Usefulness
                      DataCell(
                        _buildMetricCell(item.averageUsefulness, const Color(0xFF0284C7)),
                      ),

                      // Satisfaction
                      DataCell(
                        _buildMetricCell(item.averageSatisfaction, AppColors.primaryNavy, isPrimary: true),
                      ),

                      // Definitely Attend More %
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.definitelyAttendPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCell(double score, Color color, {bool isPrimary = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          score.toStringAsFixed(2),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(width: 3),
        Icon(Icons.star_rounded, size: 14, color: isPrimary ? AppColors.secondaryBlue : Colors.amber.shade700),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
