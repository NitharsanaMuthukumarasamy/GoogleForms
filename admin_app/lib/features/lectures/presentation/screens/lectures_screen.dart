import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/lecture_model.dart';
import '../controllers/lecture_controller.dart';
import '../widgets/export_options_sheet.dart';

class LecturesScreen extends ConsumerWidget {
  const LecturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredLecturesAsync = ref.watch(filteredLecturesProvider);
    final statusFilter = ref.watch(lectureStatusFilterProvider);
    final academicYears = ref.watch(availableAcademicYearsProvider);
    final selectedYear = ref.watch(lectureAcademicYearFilterProvider);
    final departments = ref.watch(availableDepartmentsProvider);
    final selectedDept = ref.watch(lectureDepartmentFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Lectures'),
        actions: [
          IconButton(
            tooltip: 'Compare Lectures',
            icon: const Icon(Icons.compare_arrows_rounded),
            onPressed: () => context.push('/lectures/compare'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text('New Lecture'),
        onPressed: () => context.push('/lectures/create'),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search Field
                TextField(
                  onChanged: (val) =>
                      ref.read(lectureSearchQueryProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: 'Search title, speaker, venue...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: ref.watch(lectureSearchQueryProvider).isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => ref
                                .read(lectureSearchQueryProvider.notifier)
                                .state = '',
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip(ref, 'All', statusFilter == 'All'),
                      const SizedBox(width: 8),
                      _buildStatusChip(ref, 'Active', statusFilter.toLowerCase() == 'active', color: AppColors.success),
                      const SizedBox(width: 8),
                      _buildStatusChip(ref, 'Draft', statusFilter.toLowerCase() == 'draft', color: AppColors.warning),
                      const SizedBox(width: 8),
                      _buildStatusChip(ref, 'Closed', statusFilter.toLowerCase() == 'closed', color: AppColors.textTertiary),
                      const SizedBox(width: 12),

                      // Academic Year Dropdown
                      _buildDropdownFilter(
                        label: 'Year',
                        currentValue: selectedYear,
                        items: academicYears,
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(lectureAcademicYearFilterProvider.notifier).state = val;
                          }
                        },
                      ),
                      const SizedBox(width: 8),

                      // Department Dropdown
                      _buildDropdownFilter(
                        label: 'Dept',
                        currentValue: selectedDept,
                        items: departments,
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(lectureDepartmentFilterProvider.notifier).state = val;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Real-time Lectures List
          Expanded(
            child: filteredLecturesAsync.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, __) => const CardSkeletonWidget(),
              ),
              error: (err, _) => AppErrorWidget(
                title: 'Unable to Load Lectures',
                message: err.toString(),
                onRetry: () => ref.refresh(allLecturesStreamProvider),
              ),
              data: (lectures) {
                if (lectures.isEmpty) {
                  return AppEmptyWidget(
                    icon: Icons.folder_open_rounded,
                    title: 'No Lectures Found',
                    hint: 'No alumni lectures match your current search or filters. Create a new lecture or reset your filters.',
                    actionLabel: 'Create New Lecture',
                    onAction: () => context.push('/lectures/create'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(lecturesStreamProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: lectures.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final lecture = lectures[index];
                      return _buildFolderCard(context, ref, lecture);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    WidgetRef ref,
    String label,
    bool isSelected, {
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primaryNavy;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        ref.read(lectureStatusFilterProvider.notifier).state = label;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.cardBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String currentValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : items.first,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item == 'All' ? '$label: All' : item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Folder-style card representing "YYYY_LectureTitle_SpeakerName"
  Widget _buildFolderCard(BuildContext context, WidgetRef ref, Lecture lecture) {
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(lecture.dateTime);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/lectures/${lecture.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Folder Tab Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
              decoration: const BoxDecoration(
                color: AppColors.lightBlueTint,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_rounded,
                    size: 20,
                    color: AppColors.primaryNavy,
                  ),
                  const SizedBox(width: 8),
                  // "YYYY_LectureTitle_SpeakerName"
                  Expanded(
                    child: Text(
                      lecture.folderName,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildStatusBadge(lecture.status),
                  _buildCardMenu(context, ref, lecture),
                ],
              ),
            ),

            // Card Body Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_pin, size: 16, color: AppColors.secondaryBlue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${lecture.speakerName} • ${lecture.designation}, ${lecture.company}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  const SizedBox(height: 10),

                  // Footer: Date & Response Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 15, color: AppColors.textTertiary),
                          const SizedBox(width: 5),
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlueTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.groups_rounded, size: 14, color: AppColors.primaryNavy),
                            const SizedBox(width: 4),
                            Text(
                              '${lecture.responseCount} responses',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LectureStatus status) {
    Color bg;
    Color text;

    switch (status) {
      case LectureStatus.active:
        bg = AppColors.success.withOpacity(0.12);
        text = AppColors.success;
        break;
      case LectureStatus.draft:
        bg = AppColors.warning.withOpacity(0.14);
        text = AppColors.warning;
        break;
      case LectureStatus.closed:
        bg = AppColors.textTertiary.withOpacity(0.15);
        text = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCardMenu(BuildContext context, WidgetRef ref, Lecture lecture) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
      padding: EdgeInsets.zero,
      onSelected: (action) async {
        if (action == 'edit') {
          context.push('/lectures/${lecture.id}/edit');
        } else if (action == 'qr') {
          context.push('/lectures/${lecture.id}?tab=qr');
        } else if (action == 'export') {
          final responses = await ref.read(lectureRepositoryProvider).getResponses(lecture.id);
          if (context.mounted) {
            ExportOptionsSheet.show(context, lecture: lecture, responses: responses);
          }
        } else if (action == 'toggle_status') {
          if (lecture.status == LectureStatus.active) {
            final confirmed = await ConfirmDialog.show(
              context: context,
              title: 'Close Feedback Form?',
              message: 'Are you sure you want to close "${lecture.title}"? Students will no longer be able to submit feedback.',
              confirmLabel: 'Close Form',
            );
            if (!confirmed) return;
          }
          final nextStatus = lecture.status == LectureStatus.active
              ? LectureStatus.closed
              : LectureStatus.active;
          await ref.read(lectureActionControllerProvider.notifier).setStatus(lecture.id, nextStatus);
        } else if (action == 'delete') {
          _confirmDeleteDialog(context, ref, lecture);
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryNavy),
              SizedBox(width: 10),
              Text('Edit Details'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'qr',
          child: Row(
            children: [
              Icon(Icons.qr_code_2, size: 18, color: AppColors.primaryNavy),
              SizedBox(width: 10),
              Text('View QR Code'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.ios_share_rounded, size: 18, color: AppColors.primaryNavy),
              SizedBox(width: 10),
              Text('Export (Excel, CSV, PDF)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle_status',
          child: Row(
            children: [
              Icon(
                lecture.status == LectureStatus.active ? Icons.pause_circle_outline : Icons.play_circle_outline,
                size: 18,
                color: lecture.status == LectureStatus.active ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 10),
              Text(lecture.status == LectureStatus.active ? 'Close Feedback' : 'Activate Feedback'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              SizedBox(width: 10),
              Text('Delete Lecture', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteDialog(BuildContext context, WidgetRef ref, Lecture lecture) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Lecture?',
      message: 'Are you sure you want to permanently delete "${lecture.title}" and all its student responses? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      final success = await ref
          .read(lectureActionControllerProvider.notifier)
          .deleteLecture(lecture.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Lecture deleted successfully' : 'Failed to delete lecture'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightBlueTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Lectures Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No alumni lectures match your current search or filters. Create a new lecture or reset your filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create New Lecture'),
              onPressed: () => context.push('/lectures/create'),
            ),
          ],
        ),
      ),
    );
  }
}
