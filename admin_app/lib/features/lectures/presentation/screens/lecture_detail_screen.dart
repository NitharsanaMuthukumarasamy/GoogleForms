import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/lecture_model.dart';
import '../controllers/lecture_controller.dart';
import '../widgets/responses_excel_table.dart';
import '../widgets/analytics_tab_view.dart';
import '../widgets/export_options_sheet.dart';

class LectureDetailScreen extends ConsumerStatefulWidget {
  final String lectureId;
  final String? initialTab;

  const LectureDetailScreen({
    super.key,
    required this.lectureId,
    this.initialTab,
  });

  @override
  ConsumerState<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends ConsumerState<LectureDetailScreen>
  with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _qrRepaintKey = GlobalKey();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab == 'qr') initialIndex = 1;
    if (widget.initialTab == 'responses') initialIndex = 2;
    if (widget.initialTab == 'analytics') initialIndex = 3;

    _tabController = TabController(length: 4, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lectureAsync = ref.watch(lectureDetailProvider(widget.lectureId));

    return lectureAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Lecture Detail')),
        body: Center(child: Text('Error: $err')),
      ),
      data: (lecture) {
        if (lecture == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lecture Not Found')),
            body: const Center(
              child: Text('This lecture may have been removed.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(lecture.title),
            actions: [
              IconButton(
                tooltip: 'Export Report & Data',
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: () => _openExportOptions(context, lecture),
              ),
              IconButton(
                tooltip: 'Edit Lecture',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/lectures/${lecture.id}/edit'),
              ),
              IconButton(
                tooltip: 'Delete Lecture',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteDialog(context, lecture),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Overview', icon: Icon(Icons.info_outline, size: 18)),
                Tab(text: 'QR Form', icon: Icon(Icons.qr_code_2, size: 18)),
                Tab(text: 'Responses', icon: Icon(Icons.rate_review_outlined, size: 18)),
                Tab(text: 'Analytics', icon: Icon(Icons.analytics_outlined, size: 18)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(lecture),
              _buildQrTab(lecture),
              _buildResponsesTab(lecture),
              _buildAnalyticsTab(lecture),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Overview Tab
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab(Lecture lecture) {
    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy • hh:mm a').format(lecture.dateTime);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Folder Name Header Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBlueTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_shared_rounded, color: AppColors.primaryNavy, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SYSTEM FOLDER IDENTIFIER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lecture.folderName,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status Card with Quick Toggle
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Feedback Status',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusChip(lecture.status),
                  ],
                ),
                PopupMenuButton<LectureStatus>(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Change Status',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primaryNavy),
                      ],
                    ),
                  ),
                  onSelected: (newStatus) async {
                    if (newStatus == LectureStatus.closed) {
                      final confirmed = await ConfirmDialog.show(
                        context: context,
                        title: 'Close Feedback Form?',
                        message: 'Closing this lecture will prevent students from submitting further feedback responses. You can reopen it at any time.',
                        confirmLabel: 'Close Form',
                      );
                      if (!confirmed) return;
                    }
                    await ref
                        .read(lectureActionControllerProvider.notifier)
                        .setStatus(lecture.id, newStatus);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: LectureStatus.active,
                      child: Text('Set to Active (Collecting responses)'),
                    ),
                    const PopupMenuItem(
                      value: LectureStatus.draft,
                      child: Text('Set to Draft (Hidden from students)'),
                    ),
                    const PopupMenuItem(
                      value: LectureStatus.closed,
                      child: Text('Set to Closed (Feedback closed)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Session Information Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lecture Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 14),
                _buildInfoRow(Icons.title, 'Title', lecture.title),
                const Divider(height: 20),
                _buildInfoRow(Icons.calendar_today, 'Date & Time', formattedDate),
                const Divider(height: 20),
                _buildInfoRow(Icons.location_on_outlined, 'Venue', lecture.venue),
                const Divider(height: 20),
                _buildInfoRow(Icons.domain, 'Department', lecture.department),
                const Divider(height: 20),
                _buildInfoRow(Icons.school, 'Academic Year', lecture.academicYear),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Speaker Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alumni Speaker',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 14),
                _buildInfoRow(Icons.person, 'Full Name', lecture.speakerName),
                const Divider(height: 20),
                _buildInfoRow(Icons.badge, 'Designation', lecture.designation),
                const Divider(height: 20),
                _buildInfoRow(Icons.business, 'Company / Org', lecture.company),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Export Data & Reports Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.file_download_outlined, color: AppColors.primaryNavy),
                    SizedBox(width: 8),
                    Text(
                      'Data & Analytics Export',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Export responses into Excel (.xlsx), CSV (.csv), or a branded multi-page PDF summary report.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _openExportOptions(context, lecture),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Export Responses (Excel, CSV, PDF)'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. QR Tab
  // ---------------------------------------------------------------------------
  Widget _buildQrTab(Lecture lecture) {
    // Official student web form URL with lectureId query parameter
    final studentWebUrl = AppConstants.getStudentFeedbackUrl(lecture.id);
    final isInactive = lecture.status != LectureStatus.active;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. INACTIVE WARNING BANNER (Shown if status != active)
              if (isInactive) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QR is inactive (Status: ${lecture.status.value.toUpperCase()})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Students scanning this code will see "This feedback form is closed". Set to Active to collect responses.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          await ref
                              .read(lectureActionControllerProvider.notifier)
                              .setStatus(lecture.id, LectureStatus.active);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lecture activated! QR code is now live.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        child: const Text('Activate Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. LIVE RESPONSE COUNTER BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder, width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isInactive ? AppColors.textTertiary : AppColors.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (!isInactive)
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Student Responses',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              isInactive ? 'Form Inactive' : 'Accepting Submissions',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isInactive ? AppColors.textTertiary : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlueTint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryNavy.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.groups_rounded, size: 16, color: AppColors.primaryNavy),
                          const SizedBox(width: 6),
                          Text(
                            '${lecture.responseCount} Submissions',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. HIGH-RESOLUTION REPAINT BOUNDARY (Captureable for PNG download & slides)
              RepaintBoundary(
                key: _qrRepaintKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      // Collegiate Header Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.school, size: 18, color: AppColors.primaryNavy),
                          SizedBox(width: 8),
                          Text(
                            'ALUMNI GUEST LECTURE FEEDBACK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Large High-Contrast QR Code
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder, width: 2),
                        ),
                        child: QrImageView(
                          data: studentWebUrl,
                          version: QrVersions.auto,
                          size: 240,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.primaryNavy,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lecture Title & Speaker Details under QR
                      Text(
                        lecture.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Speaker: ${lecture.speakerName}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryBlue,
                        ),
                      ),
                      if (lecture.designation.isNotEmpty || lecture.company.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${lecture.designation} • ${lecture.company}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        '${lecture.venue} • ${lecture.department}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlueTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.primaryNavy),
                            SizedBox(width: 6),
                            Text(
                              'Scan with your phone camera to submit feedback',
                              style: TextStyle(
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
                ),
              ),
              const SizedBox(height: 18),

              // 4. ACTION BUTTONS: Download PNG, Share Sheet, Copy Link
              Row(
                children: [
                  // Download PNG Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download_rounded, size: 18),
                      label: const Text(
                        'Download PNG',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isExporting ? null : () => _downloadQrAsPng(lecture),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Share via System Sheet
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryNavy,
                        side: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'Share via...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _shareQrCode(lecture),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. DIRECT LINK WITH COPY BUTTON
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: AppColors.primaryNavy, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Direct Student Form URL',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              studentWebUrl,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy Link',
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryNavy),
                        onPressed: () => _copyLink(studentWebUrl),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Exports the QR card widget as a high-resolution PNG file ready for printing or slide projection.
  Future<void> _downloadQrAsPng(Lecture lecture) async {
    setState(() => _isExporting = true);

    try {
      final boundary = _qrRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('RepaintBoundary not ready.');
      }

      // Capture at 4.0 pixelRatio for ultra-sharp 300+ DPI print resolution
      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to encode image to PNG.');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final fileName = '${lecture.folderName}_QR.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      setState(() => _isExporting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'High-resolution QR exported: $fileName',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => _shareQrCode(lecture, filePath: file.path),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export QR code: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Shares the QR code image and direct URL using the system share sheet (WhatsApp, Email, etc.).
  Future<void> _shareQrCode(Lecture lecture, {String? filePath}) async {
    final studentWebUrl = AppConstants.getStudentFeedbackUrl(lecture.id);
    final shareMessage = 'Alumni Guest Lecture: "${lecture.title}"\n'
        'Speaker: ${lecture.speakerName} (${lecture.designation})\n'
        'Submit your feedback using the link below:\n$studentWebUrl';

    try {
      if (filePath != null && File(filePath).existsSync()) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: shareMessage,
          subject: 'Feedback Form - ${lecture.title}',
        );
      } else {
        // Render image on the fly for sharing
        final boundary = _qrRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 3.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final tempDir = await getTemporaryDirectory();
            final file = File('${tempDir.path}/${lecture.folderName}_QR.png');
            await file.writeAsBytes(byteData.buffer.asUint8List());

            await Share.shareXFiles(
              [XFile(file.path)],
              text: shareMessage,
              subject: 'Feedback Form - ${lecture.title}',
            );
            return;
          }
        }
        await Share.share(shareMessage, subject: 'Feedback Form - ${lecture.title}');
      }
    } catch (e) {
      await Share.share(shareMessage, subject: 'Feedback Form - ${lecture.title}');
    }
  }

  /// Copies the direct link to the device clipboard.
  void _copyLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Feedback URL copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Responses Tab (Excel-Style Responses Spreadsheet View)
  // ---------------------------------------------------------------------------
  Widget _buildResponsesTab(Lecture lecture) {
    return ResponsesExcelTable(lecture: lecture);
  }

  // ---------------------------------------------------------------------------
  // 4. Analytics Tab (Google Forms-Style Interactive Analytics)
  // ---------------------------------------------------------------------------
  Widget _buildAnalyticsTab(Lecture lecture) {
    return AnalyticsTabView(lecture: lecture);
  }

  // ---------------------------------------------------------------------------
  // UI Helpers
  // ---------------------------------------------------------------------------
  Widget _buildStatusChip(LectureStatus status) {
    Color bg;
    Color text;

    switch (status) {
      case LectureStatus.active:
        bg = AppColors.success.withOpacity(0.12);
        text = AppColors.success;
        break;
      case LectureStatus.draft:
        bg = AppColors.warning.withOpacity(0.18);
        text = AppColors.warning;
        break;
      case LectureStatus.closed:
        bg = AppColors.textTertiary.withOpacity(0.15);
        text = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryNavy),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openExportOptions(BuildContext context, Lecture lecture) {
    final responses = ref.read(lectureResponsesStreamProvider(lecture.id)).value ?? [];
    ExportOptionsSheet.show(context, lecture: lecture, responses: responses);
  }

  Future<void> _showDeleteDialog(BuildContext context, Lecture lecture) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Lecture?',
      message: 'Are you sure you want to permanently delete "${lecture.title}"? This will also remove all submitted student feedback.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      final success = await ref
          .read(lectureActionControllerProvider.notifier)
          .deleteLecture(lecture.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lecture deleted'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete lecture'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
