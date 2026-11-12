import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/lecture_export_service.dart';
import '../../domain/feedback_response_model.dart';
import '../../domain/lecture_analytics_model.dart';
import '../../domain/lecture_model.dart';

/// Modal bottom sheet allowing the administrator to export lecture responses
/// in Excel (.xlsx), CSV (.csv), PDF (.pdf), or backup to Google Drive.
class ExportOptionsSheet extends ConsumerStatefulWidget {
  final Lecture lecture;
  final List<FeedbackResponse> responses;

  const ExportOptionsSheet({
    super.key,
    required this.lecture,
    required this.responses,
  });

  static Future<void> show(
    BuildContext context, {
    required Lecture lecture,
    required List<FeedbackResponse> responses,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportOptionsSheet(
        lecture: lecture,
        responses: responses,
      ),
    );
  }

  @override
  ConsumerState<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends ConsumerState<ExportOptionsSheet> {
  bool _isExporting = false;
  String _exportingStatus = '';

  Future<void> _exportExcel() async {
    setState(() {
      _isExporting = true;
      _exportingStatus = 'Generating Excel Workbook (.xlsx)...';
    });

    try {
      await LectureExportService.exportLectureToExcel(
        lecture: widget.lecture,
        responses: widget.responses,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
      _exportingStatus = 'Generating CSV Spreadsheet (.csv)...';
    });

    try {
      await LectureExportService.exportLectureToCsv(
        lecture: widget.lecture,
        responses: widget.responses,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() {
      _isExporting = true;
      _exportingStatus = 'Rendering PDF Report & Charts...';
    });

    try {
      final collegeName = ref.read(settingsControllerProvider).collegeName;
      final analytics = LectureAnalyticsSummary.fromResponses(widget.responses);

      await LectureExportService.exportLectureToPdf(
        lecture: widget.lecture,
        responses: widget.responses,
        analytics: analytics,
        collegeName: collegeName,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _backupToDrive() async {
    setState(() {
      _isExporting = true;
      _exportingStatus = 'Backing up to Google Drive...';
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('backupLectureToDrive');
      final result = await callable.call({'lectureId': widget.lecture.id});
      final data = result.data as Map<dynamic, dynamic>? ?? {};

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']?.toString() ?? 'Backup completed to Google Drive'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drive backup note: $e'), backgroundColor: AppColors.warning),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              const Icon(Icons.ios_share_rounded, color: AppColors.primaryNavy),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Lecture Data',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.lecture.folderName} • ${widget.responses.length} responses',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isExporting) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    _exportingStatus,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Option 1: Excel
            _buildExportOptionTile(
              icon: Icons.table_chart_rounded,
              iconColor: const Color(0xFF107C41), // Excel green
              title: 'Excel Workbook (.xlsx)',
              subtitle: 'Sheet 1: 15-column Responses • Sheet 2: Metrics Summary',
              onTap: _exportExcel,
            ),
            const SizedBox(height: 10),

            // Option 2: CSV
            _buildExportOptionTile(
              icon: Icons.grid_on_rounded,
              iconColor: const Color(0xFF0284C7),
              title: 'CSV Spreadsheet (.csv)',
              subtitle: 'Raw responses with RFC 4180 escaping and UTF-8 encoding',
              onTap: _exportCsv,
            ),
            const SizedBox(height: 10),

            // Option 3: PDF
            _buildExportOptionTile(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: const Color(0xFFDC2626), // PDF red
              title: 'PDF Analytics Report (.pdf)',
              subtitle: 'Multi-page branded report with KPI cards, distributions, and comments',
              onTap: _exportPdf,
            ),
            const SizedBox(height: 10),

            // Option 4: Google Drive Backup
            _buildExportOptionTile(
              icon: Icons.add_to_drive_rounded,
              iconColor: const Color(0xFFF59E0B), // Drive yellow/amber
              title: 'Backup to Google Drive',
              subtitle: 'Archives responses into folder named after lecture',
              onTap: _backupToDrive,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
