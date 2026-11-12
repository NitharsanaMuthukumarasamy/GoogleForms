import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_app/features/lectures/domain/lecture_model.dart';
import 'package:admin_app/features/lectures/presentation/screens/create_edit_lecture_screen.dart';
import 'package:admin_app/features/settings/presentation/controllers/settings_controller.dart';

void main() {
  group('CreateEditLectureScreen Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'settings_default_academic_year': '2026-2027',
      });
      prefs = await SharedPreferences.getInstance();
    });

    Widget createTestApp({String? lectureId}) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: CreateEditLectureScreen(lectureId: lectureId),
        ),
      );
    }

    testWidgets('renders all create lecture form sections and fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // App bar title
      expect(find.text('New Alumni Lecture'), findsOneWidget);

      // Status selector segments
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);

      // Form section headers
      expect(find.text('Lifecycle Status'), findsOneWidget);
      expect(find.text('Session Information'), findsOneWidget);
      expect(find.text('Alumni Speaker Details'), findsOneWidget);
      expect(find.text('Academic Classification'), findsOneWidget);
      expect(find.text('Response Target & Milestones (Optional)'), findsOneWidget);

      // Form field labels
      expect(find.text('Lecture Title *'), findsOneWidget);
      expect(find.text('Date & Time *'), findsOneWidget);
      expect(find.text('Venue / Hall *'), findsOneWidget);
      expect(find.text('Speaker Full Name *'), findsOneWidget);
      expect(find.text('Designation / Role *'), findsOneWidget);
      expect(find.text('Company / Organization *'), findsOneWidget);
      expect(find.text('Organizing Department *'), findsOneWidget);
      expect(find.text('Academic Year *'), findsOneWidget);
      expect(find.text('Target Response Count'), findsOneWidget);

      // Action button
      expect(find.text('Create Lecture'), findsOneWidget);
    });

    testWidgets('defaults academic year from settings provider', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Academic Year field should have '2026-2027' prefilled
      expect(find.text('2026-2027'), findsOneWidget);
    });

    testWidgets('validates required fields on empty submit', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Clear the prefilled academic year so all validations trigger
      final academicYearFinder = find.widgetWithText(TextFormField, 'Academic Year *');
      await tester.enterText(academicYearFinder, '');

      // Scroll to bottom and tap Create Lecture
      final createButton = find.text('Create Lecture');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Check validation error messages
      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Venue is required'), findsOneWidget);
      expect(find.text('Speaker name is required'), findsOneWidget);
      expect(find.text('Designation is required'), findsOneWidget);
      expect(find.text('Company is required'), findsOneWidget);
      expect(find.text('Department is required'), findsOneWidget);
      expect(find.text('Academic Year is required'), findsOneWidget);
    });

    testWidgets('validates response target format when non-numeric is entered', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final targetFinder = find.widgetWithText(TextFormField, 'Target Response Count');
      await tester.ensureVisible(targetFinder);
      await tester.enterText(targetFinder, '-10');

      final createButton = find.text('Create Lecture');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid positive number'), findsOneWidget);
    });

    testWidgets('allows switching status between Draft, Active, and Closed', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Draft is initial default
      expect(find.byType(SegmentedButton<LectureStatus>), findsOneWidget);

      // Tap Active
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      // Tap Closed
      await tester.tap(find.text('Closed'));
      await tester.pumpAndSettle();

      // Re-tap Active
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
    });
  });
}
