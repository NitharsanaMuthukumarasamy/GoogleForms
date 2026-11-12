import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../domain/feedback_response_model.dart';
import '../domain/lecture_analytics_model.dart';
import '../domain/lecture_model.dart';

/// Service responsible for exporting lecture feedback and summary reports
/// into Excel (.xlsx), CSV (.csv), and PDF (.pdf) formats with cross-platform sharing.
class LectureExportService {
  /// Sanitize file name by replacing prohibited filesystem characters with '_'
  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  /// 1. Export Single Lecture to Excel (.xlsx) with:
  /// - Sheet 1: "Responses" (Exact 15 columns)
  /// - Sheet 2: "Summary" (Ratings averages + choice option counts and %)
  static Future<void> exportLectureToExcel({
    required Lecture lecture,
    required List<FeedbackResponse> responses,
  }) async {
    final excel = Excel.createExcel();

    // Setup Sheet 1: "Responses"
    excel.rename('Sheet1', 'Responses');
    final responsesSheet = excel['Responses'];

    // Header styling
    final headerRow = [
      TextCellValue('Submitted At'),
      TextCellValue('Email'),
      TextCellValue('Name'),
      TextCellValue('Register Number'),
      TextCellValue('Programme/Department'),
      TextCellValue('Year of Study'),
      TextCellValue('Lecture Title'),
      TextCellValue('Relevance (1-5)'),
      TextCellValue('Usefulness (1-5)'),
      TextCellValue('Understanding Improved'),
      TextCellValue('Main Takeaway'),
      TextCellValue('Attend More Alumni Lectures'),
      TextCellValue('Future Topics'),
      TextCellValue('Suggestions'),
      TextCellValue('Overall Satisfaction (1-5)'),
    ];
    responsesSheet.appendRow(headerRow);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    for (final r in responses) {
      responsesSheet.appendRow([
        TextCellValue(dateFormat.format(r.submittedAt)),
        TextCellValue(r.email),
        TextCellValue(r.name),
        TextCellValue(r.registerNumber),
        TextCellValue(r.programme),
        TextCellValue(r.yearOfStudy),
        TextCellValue(r.lectureTitle),
        IntCellValue(r.relevanceRating),
        IntCellValue(r.usefulnessRating),
        TextCellValue(r.understandingImproved),
        TextCellValue(r.mainTakeaway),
        TextCellValue(r.attendMore),
        TextCellValue(r.futureTopics.join(', ')),
        TextCellValue(r.suggestions),
        IntCellValue(r.satisfactionRating),
      ]);
    }

    // Setup Sheet 2: "Summary"
    final summarySheet = excel['Summary'];
    final analytics = LectureAnalyticsSummary.fromResponses(responses);

    summarySheet.appendRow([TextCellValue('ALUMNI GUEST LECTURE - FEEDBACK SUMMARY')]);
    summarySheet.appendRow([TextCellValue('Lecture Title:'), TextCellValue(lecture.title)]);
    summarySheet.appendRow([TextCellValue('Speaker:'), TextCellValue(lecture.speakerName)]);
    summarySheet.appendRow([TextCellValue('Date & Time:'), TextCellValue(dateFormat.format(lecture.dateTime))]);
    summarySheet.appendRow([TextCellValue('Total Responses:'), IntCellValue(analytics.totalResponses)]);
    summarySheet.appendRow([TextCellValue('')]);

    // Rating Averages
    summarySheet.appendRow([TextCellValue('Key Metric'), TextCellValue('Score (out of 5.0)')]);
    summarySheet.appendRow([
      TextCellValue('Average Relevance Rating'),
      DoubleCellValue(double.parse(analytics.averageRelevance.toStringAsFixed(2))),
    ]);
    summarySheet.appendRow([
      TextCellValue('Average Usefulness Rating'),
      DoubleCellValue(double.parse(analytics.averageUsefulness.toStringAsFixed(2))),
    ]);
    summarySheet.appendRow([
      TextCellValue('Average Overall Satisfaction'),
      DoubleCellValue(double.parse(analytics.averageSatisfaction.toStringAsFixed(2))),
    ]);
    summarySheet.appendRow([TextCellValue('')]);

    // Option Counts & Percentages Table
    summarySheet.appendRow([
      TextCellValue('Question / Category'),
      TextCellValue('Option / Selection'),
      TextCellValue('Count'),
      TextCellValue('Percentage (%)'),
    ]);

    void addDistributionRows(String category, Map<String, int> distribution) {
      final total = max(1, analytics.totalResponses);
      distribution.forEach((option, count) {
        final pct = (count / total * 100).toStringAsFixed(1);
        summarySheet.appendRow([
          TextCellValue(category),
          TextCellValue(option),
          IntCellValue(count),
          TextCellValue('$pct%'),
        ]);
      });
    }

    addDistributionRows('Programme / Department', analytics.programmeDistribution);
    addDistributionRows('Year of Study', analytics.yearDistribution);
    addDistributionRows('Did Understanding Improve?', analytics.understandingDistribution);
    addDistributionRows('Attend More Lectures?', analytics.attendMoreDistribution);

    // Future Topics (Multi-select: percentage of respondents)
    for (final entry in analytics.sortedTopics) {
      final pct = (entry.value / max(1, analytics.totalResponses) * 100).toStringAsFixed(1);
      summarySheet.appendRow([
        TextCellValue('Requested Future Topics'),
        TextCellValue(entry.key),
        IntCellValue(entry.value),
        TextCellValue('$pct%'),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to generate Excel bytes');

    final fileName = '${sanitizeFileName(lecture.folderName)}.xlsx';
    await _saveAndShare(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      subject: 'Alumni Lecture Feedback Excel - ${lecture.title}',
    );
  }

  /// 2. Export Single Lecture to RFC 4180 CSV (.csv)
  static Future<void> exportLectureToCsv({
    required Lecture lecture,
    required List<FeedbackResponse> responses,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final rows = <List<dynamic>>[
      [
        'Submitted At',
        'Email',
        'Name',
        'Register Number',
        'Programme/Department',
        'Year of Study',
        'Lecture Title',
        'Relevance (1-5)',
        'Usefulness (1-5)',
        'Understanding Improved',
        'Main Takeaway',
        'Attend More Alumni Lectures',
        'Future Topics',
        'Suggestions',
        'Overall Satisfaction (1-5)',
      ],
      ...responses.map((r) => [
            dateFormat.format(r.submittedAt),
            r.email,
            r.name,
            r.registerNumber,
            r.programme,
            r.yearOfStudy,
            r.lectureTitle,
            r.relevanceRating,
            r.usefulnessRating,
            r.understandingImproved,
            r.mainTakeaway,
            r.attendMore,
            r.futureTopics.join('; '),
            r.suggestions,
            r.satisfactionRating,
          ]),
    ];

    final csvContent = const ListToCsvConverter().convert(rows);
    // Include UTF-8 BOM so Microsoft Excel opens special characters correctly
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];

    final fileName = '${sanitizeFileName(lecture.folderName)}.csv';
    await _saveAndShare(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'text/csv',
      subject: 'Alumni Lecture Feedback CSV - ${lecture.title}',
    );
  }

  /// 3. Export Single Lecture to Comprehensive Multi-Page PDF Report (.pdf)
  static Future<void> exportLectureToPdf({
    required Lecture lecture,
    required List<FeedbackResponse> responses,
    required LectureAnalyticsSummary analytics,
    required String collegeName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy • hh:mm a');

    // Page 1: Overview, KPI Metrics, Academic Distributions
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        collegeName.isNotEmpty ? collegeName.toUpperCase() : 'COLLEGE OF ENGINEERING & TECHNOLOGY',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Alumni Guest Lecture — Feedback & Analytics Report',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.blue200),
                  ),
                  child: pw.Text(
                    lecture.academicYear,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.blue900, thickness: 1.5),
            pw.SizedBox(height: 12),

            // Lecture Metadata Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    lecture.title,
                    style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Speaker: ${lecture.speakerName} (${lecture.designation}, ${lecture.company})',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Text(
                        'Status: ${lecture.status.value.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: lecture.status == LectureStatus.active ? PdfColors.green700 : PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text('Date: ${dateFormat.format(lecture.dateTime)}', style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Expanded(
                        child: pw.Text('Venue: ${lecture.venue}', style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Text('Dept: ${lecture.department}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Executive KPI Cards (Row of 4)
            pw.Row(
              children: [
                _buildPdfKpiCard('Total Responses', '${analytics.totalResponses}', PdfColors.blue800),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Satisfaction', '${analytics.averageSatisfaction.toStringAsFixed(1)} / 5', PdfColors.amber800),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Relevance', '${analytics.averageRelevance.toStringAsFixed(1)} / 5', PdfColors.teal800),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Usefulness', '${analytics.averageUsefulness.toStringAsFixed(1)} / 5', PdfColors.indigo800),
              ],
            ),
            pw.SizedBox(height: 18),

            // Programme & Year Breakdown Tables
            pw.Text('Demographic Breakdown', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 6),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _buildPdfDistributionTable('Programme / Department', analytics.programmeDistribution, analytics.totalResponses)),
                pw.SizedBox(width: 14),
                pw.Expanded(child: _buildPdfDistributionTable('Year of Study', analytics.yearDistribution, analytics.totalResponses)),
              ],
            ),
            pw.SizedBox(height: 18),

            // Ratings Distributions
            pw.Text('Rating Distributions (1 to 5 Stars)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Expanded(child: _buildPdfRatingBar('Relevance', analytics.relevanceDistribution, analytics.totalResponses)),
                pw.SizedBox(width: 12),
                pw.Expanded(child: _buildPdfRatingBar('Usefulness', analytics.usefulnessDistribution, analytics.totalResponses)),
                pw.SizedBox(width: 12),
                pw.Expanded(child: _buildPdfRatingBar('Overall Satisfaction', analytics.satisfactionDistribution, analytics.totalResponses)),
              ],
            ),
            pw.SizedBox(height: 18),

            // Understanding & Attend More
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _buildPdfDistributionTable('Did Lecture Improve Understanding?', analytics.understandingDistribution, analytics.totalResponses)),
                pw.SizedBox(width: 14),
                pw.Expanded(child: _buildPdfDistributionTable('Would Attend More Alumni Lectures?', analytics.attendMoreDistribution, analytics.totalResponses)),
              ],
            ),
            pw.SizedBox(height: 18),

            // Future Topics Requested
            pw.Text('Most Requested Future Topics', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Topic', 'Count', '% of Respondents'],
              data: analytics.sortedTopics.map((e) {
                final pct = (e.value / max(1, analytics.totalResponses) * 100).toStringAsFixed(1);
                return [e.key, '${e.value}', '$pct%'];
              }).toList(),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
            ),
            pw.SizedBox(height: 18),

            // Qualitative Feedback Comments
            pw.Text('Student Feedback Highlights', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 6),
            ...responses
                .where((r) => r.mainTakeaway.isNotEmpty || r.suggestions.isNotEmpty)
                .take(10)
                .map((r) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 6),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.grey200),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('${r.name} (${r.programme}, ${r.yearOfStudy})',
                                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                              pw.Text('Rating: ${r.satisfactionRating}★', style: const pw.TextStyle(fontSize: 8, color: PdfColors.amber800)),
                            ],
                          ),
                          if (r.mainTakeaway.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Takeaway: "${r.mainTakeaway}"', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                          ],
                          if (r.suggestions.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Suggestion: "${r.suggestions}"', style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                          ],
                        ],
                      ),
                    )),

            // Footer note
            pw.SizedBox(height: 14),
            pw.Center(
              child: pw.Text(
                'Report generated by Alumni Lecture Feedback System • ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = '${sanitizeFileName(lecture.folderName)}.pdf';
    await _saveAndShare(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
      subject: 'Alumni Lecture PDF Report - ${lecture.title}',
    );
  }

  /// 4. Export Entire Academic Year Bundle into one Consolidated Excel (.xlsx)
  /// - Sheet 1: "All Summary" (Comparative table across all lectures)
  /// - One sheet per lecture (Capped at 31 chars per Excel spec)
  static Future<void> exportAcademicYearToExcel({
    required String academicYear,
    required List<Lecture> lectures,
    required Map<String, List<FeedbackResponse>> responsesByLectureId,
  }) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'All Summary');
    final allSummarySheet = excel['All Summary'];

    // All Summary Header
    allSummarySheet.appendRow([
      TextCellValue('Academic Year: $academicYear - Alumni Lectures Comparative Summary'),
    ]);
    allSummarySheet.appendRow([TextCellValue('')]);
    allSummarySheet.appendRow([
      TextCellValue('Lecture Title'),
      TextCellValue('Date'),
      TextCellValue('Speaker Name'),
      TextCellValue('Department'),
      TextCellValue('Status'),
      TextCellValue('Responses'),
      TextCellValue('Avg Relevance (1-5)'),
      TextCellValue('Avg Usefulness (1-5)'),
      TextCellValue('Avg Satisfaction (1-5)'),
      TextCellValue('Attend More "Definitely" %'),
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd');
    for (final lecture in lectures) {
      final responses = responsesByLectureId[lecture.id] ?? [];
      final analytics = LectureAnalyticsSummary.fromResponses(responses);
      final definitelyCount = analytics.attendMoreDistribution['Definitely'] ?? 0;
      final definitelyPct = analytics.totalResponses > 0
          ? (definitelyCount / analytics.totalResponses * 100).toStringAsFixed(1)
          : '0.0';

      allSummarySheet.appendRow([
        TextCellValue(lecture.title),
        TextCellValue(dateFormat.format(lecture.dateTime)),
        TextCellValue(lecture.speakerName),
        TextCellValue(lecture.department),
        TextCellValue(lecture.status.value.toUpperCase()),
        IntCellValue(responses.length),
        DoubleCellValue(double.parse(analytics.averageRelevance.toStringAsFixed(2))),
        DoubleCellValue(double.parse(analytics.averageUsefulness.toStringAsFixed(2))),
        DoubleCellValue(double.parse(analytics.averageSatisfaction.toStringAsFixed(2))),
        TextCellValue('$definitelyPct%'),
      ]);

      // Add individual sheet for this lecture (max 31 characters, no invalid chars)
      final cleanTitle = lecture.title.replaceAll(RegExp(r'[\\/:*?\[\]]'), '_');
      final sheetName = cleanTitle.length > 28
          ? '${cleanTitle.substring(0, 25)}...'
          : cleanTitle;

      final lectureSheet = excel[sheetName];
      lectureSheet.appendRow([
        TextCellValue('Submitted At'),
        TextCellValue('Email'),
        TextCellValue('Name'),
        TextCellValue('Register Number'),
        TextCellValue('Programme/Department'),
        TextCellValue('Year of Study'),
        TextCellValue('Lecture Title'),
        TextCellValue('Relevance (1-5)'),
        TextCellValue('Usefulness (1-5)'),
        TextCellValue('Understanding Improved'),
        TextCellValue('Main Takeaway'),
        TextCellValue('Attend More Alumni Lectures'),
        TextCellValue('Future Topics'),
        TextCellValue('Suggestions'),
        TextCellValue('Overall Satisfaction (1-5)'),
      ]);

      for (final r in responses) {
        lectureSheet.appendRow([
          TextCellValue(dateFormat.format(r.submittedAt)),
          TextCellValue(r.email),
          TextCellValue(r.name),
          TextCellValue(r.registerNumber),
          TextCellValue(r.programme),
          TextCellValue(r.yearOfStudy),
          TextCellValue(r.lectureTitle),
          IntCellValue(r.relevanceRating),
          IntCellValue(r.usefulnessRating),
          TextCellValue(r.understandingImproved),
          TextCellValue(r.mainTakeaway),
          TextCellValue(r.attendMore),
          TextCellValue(r.futureTopics.join(', ')),
          TextCellValue(r.suggestions),
          IntCellValue(r.satisfactionRating),
        ]);
      }
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to generate Academic Year Excel bytes');

    final fileName = '${sanitizeFileName(academicYear)}_AllLectures_Summary.xlsx';
    await _saveAndShare(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      subject: 'Academic Year $academicYear Alumni Lectures Report',
    );
  }

  // --- Helpers for PDF rendering ---
  static pw.Widget _buildPdfKpiCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: color, width: 1.2),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfDistributionTable(String title, Map<String, int> distribution, int total) {
    final effectiveTotal = max(1, total);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 3),
        pw.TableHelper.fromTextArray(
          headers: ['Option', 'Count', '%'],
          data: distribution.entries.map((e) {
            final pct = (e.value / effectiveTotal * 100).toStringAsFixed(1);
            return [e.key, '${e.value}', '$pct%'];
          }).toList(),
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
          cellStyle: const pw.TextStyle(fontSize: 7.5),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfRatingBar(String title, Map<int, int> distribution, int total) {
    final effectiveTotal = max(1, total);
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 4),
          ...[5, 4, 3, 2, 1].map((rating) {
            final count = distribution[rating] ?? 0;
            final pct = (count / effectiveTotal * 100).toStringAsFixed(0);
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
              child: pw.Row(
                children: [
                  pw.Text('$rating★', style: const pw.TextStyle(fontSize: 7)),
                  pw.SizedBox(width: 4),
                  pw.Expanded(
                    child: pw.Container(
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Align(
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Container(
                          width: (count / effectiveTotal) * 60,
                          decoration: pw.BoxDecoration(
                            color: rating >= 4 ? PdfColors.green700 : (rating == 3 ? PdfColors.amber700 : PdfColors.red700),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text('$count ($pct%)', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static Future<void> _saveAndShare({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    required String subject,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType, name: fileName)],
      subject: subject,
    );
  }
}
