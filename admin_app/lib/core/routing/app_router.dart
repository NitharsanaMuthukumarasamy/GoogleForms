import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_shell_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/analytics_placeholder_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/lectures/presentation/screens/lectures_screen.dart';
import '../../features/lectures/presentation/screens/create_edit_lecture_screen.dart';
import '../../features/lectures/presentation/screens/lecture_detail_screen.dart';
import '../../features/lectures/presentation/screens/lecture_comparison_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _dashboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'dashboardTab');
final _lecturesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'lecturesTab');
final _analyticsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'analyticsTab');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settingsTab');

/// Listenable that triggers router refresh on auth state changes.
class AuthRouterListenable extends ChangeNotifier {
  final Ref _ref;

  AuthRouterListenable(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    _ref.listen(currentAdminProvider, (_, __) => notifyListeners());
  }
}

final authRouterListenableProvider = Provider<AuthRouterListenable>((ref) {
  return AuthRouterListenable(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authRouterListenableProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateChangesProvider);
      final adminAsync = ref.read(currentAdminProvider);

      final isLoggedIn = authAsync.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // Still loading initial auth state from Firebase
      if (authAsync.isLoading) {
        return null;
      }

      // If user is not logged in, enforce redirect to /login
      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // If user is logged in, ensure they are verified in the admins collection
      if (adminAsync.hasValue && adminAsync.value == null) {
        // Logged in via Firebase Auth, but not an admin -> redirect to /login
        return isLoggingIn ? null : '/login';
      }

      // If user is logged in and trying to access /login, redirect to /dashboard
      if (isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Global nested routes for lecture actions (with full screen navigation)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/lectures/create',
        builder: (context, state) => const CreateEditLectureScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/lectures/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final tab = state.uri.queryParameters['tab'];
          return LectureDetailScreen(lectureId: id, initialTab: tab);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/lectures/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CreateEditLectureScreen(lectureId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/lectures/compare',
        builder: (context, state) => const LectureComparisonScreen(),
      ),

      // Persistent Bottom Navigation Tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _lecturesNavigatorKey,
            routes: [
              GoRoute(
                path: '/lectures',
                builder: (context, state) => const LecturesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _analyticsNavigatorKey,
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const LectureComparisonScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
