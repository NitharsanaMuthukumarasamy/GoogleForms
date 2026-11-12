import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/feedback_response_model.dart';
import '../../domain/lecture_model.dart';
import '../controllers/lecture_controller.dart';
import 'individual_response_sheet.dart';

/// An Excel-style spreadsheet responses viewer for lecture feedback.
///
/// Features:
/// - Exact 15 columns in specified order
/// - Sticky frozen first column (Name)
/// - Sticky frozen header row
/// - Synchronized 60fps vertical scrolling between sticky column & scrollable grid
/// - Real-time updates via Firestore stream
/// - Search by name, register number, or email
/// - Multi-column sort with ascending/descending indicators
/// - Multi-criteria filters: programme, year of study, satisfaction rating, attend more, date range
/// - Tap any row to open full-detail IndividualResponseSheet
/// - Total response counter & active filter chips
/// - Pagination & lazy virtualized rendering (500+ responses support)
/// - Truncated text cells with full views in detail sheet
class ResponsesExcelTable extends ConsumerStatefulWidget {
  final Lecture lecture;

  const ResponsesExcelTable({
    super.key,
    required this.lecture,
  });

  @override
  ConsumerState<ResponsesExcelTable> createState() => _ResponsesExcelTableState();
}

class _ResponsesExcelTableState extends ConsumerState<ResponsesExcelTable> {
  // Dual vertical scroll controllers synchronized in lockstep
  final ScrollController _stickyVerticalController = ScrollController();
  final ScrollController _contentVerticalController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSyncing = false;

  // Constants for fixed geometry guaranteeing pixel-perfect alignment
  static const double kRowHeight = 54.0;
  static const double kHeaderHeight = 48.0;
  static const double kStickyColumnWidth = 160.0;

  // Exact column definitions (excluding the sticky Name column)
  static const List<_ColumnDef> _columns = [
    _ColumnDef(id: 'submittedAt', title: 'Submitted At', width: 145),
    _ColumnDef(id: 'email', title: 'Email', width: 190),
    _ColumnDef(id: 'registerNumber', title: 'Register Number', width: 135),
    _ColumnDef(id: 'programme', title: 'Programme / Dept', width: 175),
    _ColumnDef(id: 'yearOfStudy', title: 'Year of Study', width: 110),
    _ColumnDef(id: 'lectureTitle', title: 'Lecture Title', width: 190),
    _ColumnDef(id: 'relevanceRating', title: 'Relevance (1-5)', width: 125),
    _ColumnDef(id: 'usefulnessRating', title: 'Usefulness (1-5)', width: 125),
    _ColumnDef(id: 'understandingImproved', title: 'Understanding Improved', width: 175),
    _ColumnDef(id: 'mainTakeaway', title: 'Main Takeaway', width: 240),
    _ColumnDef(id: 'attendMore', title: 'Attend More Lectures', width: 165),
    _ColumnDef(id: 'futureTopics', title: 'Future Topics', width: 240),
    _ColumnDef(id: 'suggestions', title: 'Suggestions', width: 240),
    _ColumnDef(id: 'satisfactionRating', title: 'Overall Satisfaction', width: 150),
  ];

  static double get kTotalContentWidth =>
      _columns.fold(0.0, (sum, col) => sum + col.width);

  @override
  void initState() {
    super.initState();
    _stickyVerticalController.addListener(_syncStickyToContent);
    _contentVerticalController.addListener(_syncContentToSticky);
  }

  void _syncStickyToContent() {
    if (_isSyncing) return;
    _isSyncing = true;
    if (_contentVerticalController.hasClients &&
        _contentVerticalController.offset != _stickyVerticalController.offset) {
      _contentVerticalController.jumpTo(_stickyVerticalController.offset);
    }
    _isSyncing = false;
  }

  void _syncContentToSticky() {
    if (_isSyncing) return;
    _isSyncing = true;
    if (_stickyVerticalController.hasClients &&
        _stickyVerticalController.offset != _contentVerticalController.offset) {
      _stickyVerticalController.jumpTo(_contentVerticalController.offset);
    }
    _isSyncing = false;
  }

  @override
  void dispose() {
    _stickyVerticalController.removeListener(_syncStickyToContent);
    _contentVerticalController.removeListener(_syncContentToSticky);
    _stickyVerticalController.dispose();
    _contentVerticalController.dispose();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lectureId = widget.lecture.id;

    // Watch real-time stream data and filtered subset
    final allResponsesAsync = ref.watch(lectureResponsesStreamProvider(lectureId));
    final filteredResponsesAsync = ref.watch(filteredResponsesProvider(lectureId));
    final paginatedResponsesAsync = ref.watch(paginatedResponsesProvider(lectureId));

    // Watch filter states
    final searchQuery = ref.watch(responseSearchQueryProvider);
    final programmeFilter = ref.watch(responseProgrammeFilterProvider);
    final yearFilter = ref.watch(responseYearFilterProvider);
    final satisfactionFilter = ref.watch(responseSatisfactionFilterProvider);
    final attendMoreFilter = ref.watch(responseAttendMoreFilterProvider);
    final dateRangeFilter = ref.watch(responseDateRangeFilterProvider);

    // Watch sorting states
    final sortColumn = ref.watch(responseSortColumnProvider);
    final sortAscending = ref.watch(responseSortAscendingProvider);

    // Watch pagination states
    final currentPage = ref.watch(responseCurrentPageProvider);
    final pageSize = ref.watch(responsePageSizeProvider);

    final totalCount = allResponsesAsync.value?.length ?? 0;
    final filteredCount = filteredResponsesAsync.value?.length ?? 0;
    final totalPages = (filteredCount / pageSize).ceil().clamp(1, 9999);

    final hasActiveFilters = searchQuery.isNotEmpty ||
        programmeFilter != 'All' ||
        yearFilter != 'All' ||
        satisfactionFilter != null ||
        attendMoreFilter != 'All' ||
        dateRangeFilter != null;

    final activeFilterCount = (searchQuery.isNotEmpty ? 1 : 0) +
        (programmeFilter != 'All' ? 1 : 0) +
        (yearFilter != 'All' ? 1 : 0) +
        (satisfactionFilter != null ? 1 : 0) +
        (attendMoreFilter != 'All' ? 1 : 0) +
        (dateRangeFilter != null ? 1 : 0);

    return Column(
      children: [
        // 1. TOOLBAR: Search Bar + Filter Trigger + Active Stats
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  // Search Input
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by name, reg no, or email...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(responseSearchQueryProvider.notifier).state = '';
                                    ref.read(responseCurrentPageProvider.notifier).state = 1;
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) {
                          ref.read(responseSearchQueryProvider.notifier).state = val;
                          ref.read(responseCurrentPageProvider.notifier).state = 1;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Filter Button with Badge
                  Badge(
                    isLabelVisible: activeFilterCount > 0,
                    label: Text('$activeFilterCount'),
                    backgroundColor: AppColors.secondaryBlue,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasActiveFilters ? AppColors.secondaryBlue : AppColors.primaryNavy,
                        side: BorderSide(
                          color: hasActiveFilters ? AppColors.secondaryBlue : AppColors.cardBorder,
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.filter_list_rounded, size: 18),
                      label: const Text('Filters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      onPressed: () => _showFilterSheet(context),
                    ),
                  ),
                ],
              ),

              // Active Filter Chips Strip (if filters applied)
              if (hasActiveFilters) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (programmeFilter != 'All')
                        _buildFilterChip('Prog: $programmeFilter', () {
                          ref.read(responseProgrammeFilterProvider.notifier).state = 'All';
                          ref.read(responseCurrentPageProvider.notifier).state = 1;
                        }),
                      if (yearFilter != 'All')
                        _buildFilterChip('Year: $yearFilter', () {
                          ref.read(responseYearFilterProvider.notifier).state = 'All';
                          ref.read(responseCurrentPageProvider.notifier).state = 1;
                        }),
                      if (satisfactionFilter != null)
                        _buildFilterChip('Satisfaction: $satisfactionFilter ★', () {
                          ref.read(responseSatisfactionFilterProvider.notifier).state = null;
                          ref.read(responseCurrentPageProvider.notifier).state = 1;
                        }),
                      if (attendMoreFilter != 'All')
                        _buildFilterChip('Attend: $attendMoreFilter', () {
                          ref.read(responseAttendMoreFilterProvider.notifier).state = 'All';
                          ref.read(responseCurrentPageProvider.notifier).state = 1;
                        }),
                      if (dateRangeFilter != null)
                        _buildFilterChip(
                          '${DateFormat('dd MMM').format(dateRangeFilter.start)} - ${DateFormat('dd MMM').format(dateRangeFilter.end)}',
                          () {
                            ref.read(responseDateRangeFilterProvider.notifier).state = null;
                            ref.read(responseCurrentPageProvider.notifier).state = 1;
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 28),
                          ),
                          onPressed: _resetAllFilters,
                          child: const Text('Clear All', style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // 2. METRICS & LIVE STATUS BAR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(
              top: BorderSide(color: AppColors.cardBorder),
              bottom: BorderSide(color: AppColors.cardBorder),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Count Summary
              Row(
                children: [
                  const Icon(Icons.table_chart_outlined, size: 16, color: AppColors.primaryNavy),
                  const SizedBox(width: 6),
                  Text(
                    hasActiveFilters
                        ? 'Showing $filteredCount of $totalCount responses (Filtered)'
                        : 'Total Responses: $totalCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),

              // Live Status Badge
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Real-time Firestore Stream',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. EXCEL SPREADSHEET VIEWPORT (FROZEN NAME COLUMN + HORIZONTAL DATA PANE)
        Expanded(
          child: paginatedResponsesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading responses: $err', style: const TextStyle(color: AppColors.error)),
              ),
            ),
            data: (pagedResponses) {
              if (totalCount == 0) {
                return _buildEmptyState(
                  icon: Icons.speaker_notes_off_outlined,
                  title: 'No responses yet',
                  subtitle: 'Student feedback will stream here automatically as soon as it is submitted.',
                );
              }

              if (filteredCount == 0) {
                return _buildEmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'No matching responses',
                  subtitle: 'No responses match your active search and filter criteria.',
                  actionLabel: 'Reset Filters',
                  onAction: _resetAllFilters,
                );
              }

              return Row(
                children: [
                  // -----------------------------------------------------------
                  // A. STICKY FROZEN FIRST COLUMN: Name (Fixed Width 160)
                  // -----------------------------------------------------------
                  Container(
                    width: kStickyColumnWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: const Border(
                        right: BorderSide(color: AppColors.cardBorder, width: 2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          offset: const Offset(2, 0),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Sticky Header: Name
                        _buildStickyHeaderCell(
                          title: 'Name',
                          columnKey: 'name',
                          activeSort: sortColumn,
                          isAscending: sortAscending,
                          width: kStickyColumnWidth,
                        ),

                        // Vertical List of Name Cells
                        Expanded(
                          child: ListView.builder(
                            controller: _stickyVerticalController,
                            itemCount: pagedResponses.length,
                            itemExtent: kRowHeight,
                            physics: const ClampingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final resp = pagedResponses[index];
                              final isEven = index % 2 == 0;
                              return _buildStickyNameCell(resp, isEven);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // -----------------------------------------------------------
                  // B. HORIZONTALLY SCROLLABLE DATA PANE (14 Columns)
                  // -----------------------------------------------------------
                  Expanded(
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: SizedBox(
                          width: kTotalContentWidth,
                          child: Column(
                            children: [
                              // Sticky Data Header Row
                              Container(
                                height: kHeaderHeight,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.cardBorder, width: 1.5),
                                  ),
                                ),
                                child: Row(
                                  children: _columns.map((col) {
                                    return _buildHeaderCell(
                                      title: col.title,
                                      columnKey: col.id,
                                      activeSort: sortColumn,
                                      isAscending: sortAscending,
                                      width: col.width,
                                    );
                                  }).toList(),
                                ),
                              ),

                              // Vertical List of Data Rows
                              Expanded(
                                child: ListView.builder(
                                  controller: _contentVerticalController,
                                  itemCount: pagedResponses.length,
                                  itemExtent: kRowHeight,
                                  physics: const ClampingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final resp = pagedResponses[index];
                                    final isEven = index % 2 == 0;
                                    return _buildDataRow(resp, isEven);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // 4. PAGINATION FOOTER
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Page Size Selector
              Row(
                children: [
                  const Text('Rows per page:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: pageSize,
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    items: const [
                      DropdownMenuItem(value: 25, child: Text('25')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                      DropdownMenuItem(value: 100, child: Text('100')),
                    ],
                    onChanged: (newSize) {
                      if (newSize != null) {
                        ref.read(responsePageSizeProvider.notifier).state = newSize;
                        ref.read(responseCurrentPageProvider.notifier).state = 1;
                      }
                    },
                  ),
                ],
              ),

              // Page Indicator & Prev/Next Controls
              Row(
                children: [
                  Text(
                    'Page $currentPage of $totalPages',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Previous Page',
                    onPressed: currentPage > 1
                        ? () {
                            ref.read(responseCurrentPageProvider.notifier).state = currentPage - 1;
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Next Page',
                    onPressed: currentPage < totalPages
                        ? () {
                            ref.read(responseCurrentPageProvider.notifier).state = currentPage + 1;
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER CELLS WITH INTERACTIVE SORTING
  // ---------------------------------------------------------------------------

  Widget _buildStickyHeaderCell({
    required String title,
    required String columnKey,
    required String activeSort,
    required bool isAscending,
    required double width,
  }) {
    final isSelected = activeSort == columnKey;
    return InkWell(
      onTap: () => _toggleSort(columnKey),
      child: Container(
        height: kHeaderHeight,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          border: Border(
            bottom: BorderSide(color: AppColors.cardBorder, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, size: 13, color: AppColors.primaryNavy),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? (isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 15,
              color: isSelected ? AppColors.secondaryBlue : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell({
    required String title,
    required String columnKey,
    required String activeSort,
    required bool isAscending,
    required double width,
  }) {
    final isSelected = activeSort == columnKey;
    return InkWell(
      onTap: () => _toggleSort(columnKey),
      child: Container(
        height: kHeaderHeight,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: AppColors.cardBorder),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              isSelected
                  ? (isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 15,
              color: isSelected ? AppColors.secondaryBlue : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSort(String columnKey) {
    final currentSort = ref.read(responseSortColumnProvider);
    final currentAsc = ref.read(responseSortAscendingProvider);

    if (currentSort == columnKey) {
      ref.read(responseSortAscendingProvider.notifier).state = !currentAsc;
    } else {
      ref.read(responseSortColumnProvider.notifier).state = columnKey;
      ref.read(responseSortAscendingProvider.notifier).state = true;
    }
  }

  // ---------------------------------------------------------------------------
  // ROW RENDERING & TRUNCATION WITH TAP-TO-EXPAND
  // ---------------------------------------------------------------------------

  Widget _buildStickyNameCell(FeedbackResponse resp, bool isEven) {
    return InkWell(
      onTap: () => IndividualResponseSheet.show(context, resp),
      child: Container(
        height: kRowHeight,
        width: kStickyColumnWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isEven ? Colors.white : const Color(0xFFF8FAFC),
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.lightBlueTint,
              child: Text(
                resp.name.isNotEmpty ? resp.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                resp.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(FeedbackResponse resp, bool isEven) {
    final formattedDate = DateFormat('dd/MM/yy HH:mm').format(resp.submittedAt);
    final futureTopicsStr = resp.futureTopics.join(', ');

    return InkWell(
      onTap: () => IndividualResponseSheet.show(context, resp),
      child: Container(
        height: kRowHeight,
        decoration: BoxDecoration(
          color: isEven ? Colors.white : const Color(0xFFF8FAFC),
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            // 1. Submitted At
            _buildCell(
              width: 145,
              child: Text(
                formattedDate,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary),
              ),
            ),

            // 2. Email
            _buildCell(
              width: 190,
              child: Text(
                resp.email,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 3. Register Number
            _buildCell(
              width: 135,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightBlueTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  resp.registerNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // 4. Programme/Department
            _buildCell(
              width: 175,
              child: Text(
                resp.programme,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 5. Year of Study
            _buildCell(
              width: 110,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  resp.yearOfStudy,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                ),
              ),
            ),

            // 6. Lecture Title
            _buildCell(
              width: 190,
              child: Text(
                resp.lectureTitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 7. Relevance Rating (1-5)
            _buildCell(
              width: 125,
              child: _buildRatingBadge(resp.relevanceRating),
            ),

            // 8. Usefulness Rating (1-5)
            _buildCell(
              width: 125,
              child: _buildRatingBadge(resp.usefulnessRating),
            ),

            // 9. Understanding Improved
            _buildCell(
              width: 175,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: resp.understandingImproved.startsWith('Yes')
                      ? AppColors.success.withOpacity(0.12)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  resp.understandingImproved,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: resp.understandingImproved.startsWith('Yes') ? AppColors.success : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // 10. Main Takeaway (Truncated)
            _buildCell(
              width: 240,
              child: Text(
                resp.mainTakeaway,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 11. Attend More Alumni Lectures
            _buildCell(
              width: 165,
              child: _buildAttendMoreBadge(resp.attendMore),
            ),

            // 12. Future Topics (Comma-separated)
            _buildCell(
              width: 240,
              child: Text(
                futureTopicsStr.isNotEmpty ? futureTopicsStr : 'None',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 13. Suggestions (Truncated)
            _buildCell(
              width: 240,
              child: Text(
                resp.suggestions.isNotEmpty ? resp.suggestions : '—',
                style: TextStyle(
                  fontSize: 12,
                  color: resp.suggestions.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 14. Overall Satisfaction (1-5)
            _buildCell(
              width: 150,
              child: _buildRatingBadge(resp.satisfactionRating, isPrimary: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell({required double width, required Widget child}) {
    return Container(
      width: width,
      height: kRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: child,
    );
  }

  Widget _buildRatingBadge(int rating, {bool isPrimary = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.lightBlueTint : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isPrimary ? AppColors.primaryNavy.withOpacity(0.2) : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$rating',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? AppColors.primaryNavy : const Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.star_rounded,
                size: 14,
                color: isPrimary ? AppColors.secondaryBlue : const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendMoreBadge(String answer) {
    Color bg = const Color(0xFFE2E8F0);
    Color text = AppColors.textSecondary;

    if (answer == 'Definitely') {
      bg = AppColors.success.withOpacity(0.12);
      text = AppColors.success;
    } else if (answer == 'Probably') {
      bg = AppColors.lightBlueTint;
      text = AppColors.primaryNavy;
    } else if (answer == 'Maybe') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFF92400E);
    } else if (answer == 'No') {
      bg = AppColors.error.withOpacity(0.12);
      text = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        answer,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        color: AppColors.lightBlueTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryNavy)),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primaryNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: AppColors.textTertiary),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _resetAllFilters() {
    _searchController.clear();
    ref.read(responseSearchQueryProvider.notifier).state = '';
    ref.read(responseProgrammeFilterProvider.notifier).state = 'All';
    ref.read(responseYearFilterProvider.notifier).state = 'All';
    ref.read(responseSatisfactionFilterProvider.notifier).state = null;
    ref.read(responseAttendMoreFilterProvider.notifier).state = 'All';
    ref.read(responseDateRangeFilterProvider.notifier).state = null;
    ref.read(responseCurrentPageProvider.notifier).state = 1;
  }

  // ---------------------------------------------------------------------------
  // FILTER MODAL SHEET
  // ---------------------------------------------------------------------------

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final progFilter = ref.watch(responseProgrammeFilterProvider);
            final yrFilter = ref.watch(responseYearFilterProvider);
            final satFilter = ref.watch(responseSatisfactionFilterProvider);
            final attFilter = ref.watch(responseAttendMoreFilterProvider);
            final dateFilter = ref.watch(responseDateRangeFilterProvider);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle & Header
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Responses',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      TextButton(
                        onPressed: () {
                          _resetAllFilters();
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Reset All', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                  const Divider(height: 12),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Programme
                          const Text('Programme / Department',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: progFilter,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: ['All', ...FeedbackConstants.programmes].map((prog) {
                              return DropdownMenuItem(value: prog, child: Text(prog, style: const TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(responseProgrammeFilterProvider.notifier).state = val;
                                ref.read(responseCurrentPageProvider.notifier).state = 1;
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // 2. Year of Study
                          const Text('Year of Study',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: yrFilter,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: ['All', ...FeedbackConstants.yearsOfStudy].map((yr) {
                              return DropdownMenuItem(value: yr, child: Text(yr, style: const TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(responseYearFilterProvider.notifier).state = val;
                                ref.read(responseCurrentPageProvider.notifier).state = 1;
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // 3. Satisfaction Rating
                          const Text('Overall Satisfaction (1-5)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: satFilter == null,
                                onSelected: (sel) {
                                  if (sel) {
                                    ref.read(responseSatisfactionFilterProvider.notifier).state = null;
                                    ref.read(responseCurrentPageProvider.notifier).state = 1;
                                  }
                                },
                              ),
                              for (int rating = 5; rating >= 1; rating--)
                                ChoiceChip(
                                  label: Text('$rating ★'),
                                  selected: satFilter == rating,
                                  onSelected: (sel) {
                                    ref.read(responseSatisfactionFilterProvider.notifier).state = sel ? rating : null;
                                    ref.read(responseCurrentPageProvider.notifier).state = 1;
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 4. Attend More
                          const Text('Attend More Alumni Lectures',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: attFilter,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: ['All', ...FeedbackConstants.attendMoreOptions].map((opt) {
                              return DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(responseAttendMoreFilterProvider.notifier).state = val;
                                ref.read(responseCurrentPageProvider.notifier).state = 1;
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // 5. Date Range
                          const Text('Submission Date Range',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                initialDateRange: dateFilter,
                              );
                              if (picked != null) {
                                ref.read(responseDateRangeFilterProvider.notifier).state = picked;
                                ref.read(responseCurrentPageProvider.notifier).state = 1;
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateFilter == null
                                        ? 'All time (Tap to select date range)'
                                        : '${DateFormat('dd/MM/yyyy').format(dateFilter.start)} - ${DateFormat('dd/MM/yyyy').format(dateFilter.end)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: dateFilter != null ? FontWeight.bold : FontWeight.normal,
                                      color: dateFilter != null ? AppColors.primaryNavy : AppColors.textSecondary,
                                    ),
                                  ),
                                  const Icon(Icons.date_range_rounded, size: 18, color: AppColors.primaryNavy),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Apply Filters', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ColumnDef {
  final String id;
  final String title;
  final double width;

  const _ColumnDef({
    required this.id,
    required this.title,
    required this.width,
  });
}
