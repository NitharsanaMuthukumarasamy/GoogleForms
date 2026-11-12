import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admin_app/features/auth/presentation/screens/login_screen.dart';
import 'package:admin_app/features/settings/presentation/controllers/settings_controller.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'settings_college_name': 'Govt College of Technology',
      });
      prefs = await SharedPreferences.getInstance();
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    testWidgets('renders all login screen elements and branding', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify branding and titles
      expect(find.text('Govt College of Technology'), findsOneWidget);
      expect(find.text('Administrative Staff & Coordinator Portal'), findsOneWidget);
      expect(find.text('Sign In'), findsNWidgets(2)); // Card header and button text

      // Verify input fields
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Admin Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('validates required email and password fields on empty submission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Sign In button without entering credentials
      final signInButton = find.byType(ElevatedButton);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Form validation errors should be displayed
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('validates email format correctness', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'not-an-email');

      final signInButton = find.byType(ElevatedButton);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('toggles password visibility when eye icon is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Initially visibility_off icon is present
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap the toggle button
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      // Now visibility icon is present
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('opens Forgot Password dialog when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final forgotBtn = find.text('Forgot Password?');
      await tester.tap(forgotBtn);
      await tester.pumpAndSettle();

      // Dialog should be presented
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
