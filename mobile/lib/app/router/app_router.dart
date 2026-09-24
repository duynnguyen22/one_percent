import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../shell/main_shell_scaffold.dart';
import '../../features/habits/presentation/pages/today_page.dart';
import '../../features/habits/presentation/pages/my_habits_page.dart';
import '../../features/habits/presentation/pages/add_habit_page.dart';
import '../../features/insights/presentation/pages/insights_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/offline/presentation/pages/offline_page.dart';
import '../../features/routines/domain/entities/routine.dart';
import '../../features/routines/presentation/pages/create_routine_page.dart';
import '../../features/routines/presentation/pages/edit_routine_page.dart';
import '../../features/routines/presentation/pages/routine_completed_page.dart';
import '../../features/routines/presentation/pages/routine_detail_page.dart';
import '../../features/routines/presentation/pages/routine_execution_page.dart';
import '../../features/routines/presentation/pages/routines_home_page.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app's GoRouter, rebuilt when auth state changes.
///
/// Redirects live here rather than in the pages: a page should not have to know
/// whether the user may see it. The rules are:
///
/// - status unknown → hold on the welcome screen
/// - unauthenticated on a private route → go to login
/// - authenticated on an auth route → go to the main shell, except on the
///   welcome screen, which every launch passes through
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<AuthStatus>(AuthStatus.unknown);

  ref.listen(
    authNotifierProvider.select((state) => state.status),
    (_, status) => notifier.value = status,
    fireImmediately: true,
  );
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.welcomePath,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final status = notifier.value;
      final location = state.matchedLocation;
      final isPublic = RouteNames.publicPaths.contains(location);

      // Still restoring the stored session — stay on the welcome screen.
      if (status == AuthStatus.unknown) {
        return location == RouteNames.welcomePath
            ? null
            : RouteNames.welcomePath;
      }

      if (status == AuthStatus.unauthenticated) {
        return isPublic ? null : RouteNames.loginPath;
      }

      // Authenticated: keep the user out of the auth pages. The welcome screen
      // is the exception — it opens every launch and moves the user on itself
      // once the brand has had its moment.
      if (location == RouteNames.welcomePath) return null;

      return isPublic ? RouteNames.todayPath : null;
    },
    routes: [
      GoRoute(
        path: RouteNames.welcomePath,
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.registerPath,
        name: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPasswordPath,
        name: RouteNames.forgotPassword,
        builder: (context, state) => ForgotPasswordPage(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.resetPasswordPath,
        name: RouteNames.resetPassword,
        // The token arrives from the verify step. Landing here without one is a
        // deep link or a stale tab, and the page has no way to authorise the
        // change, so send the user back to start the flow again.
        redirect: (context, state) =>
            (state.uri.queryParameters['token'] ?? '').isEmpty
                ? RouteNames.forgotPasswordPath
                : null,
        builder: (context, state) => ResetPasswordPage(
          resetToken: state.uri.queryParameters['token'] ?? '',
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.offlinePath,
        name: RouteNames.offline,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => OfflinePage(
          flowTitle: state.uri.queryParameters['flowTitle'] ?? 'Add Habit Flow',
          lastSyncedText: state.uri.queryParameters['lastSynced'] ?? 'Synced 8:30 AM',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.todayPath,
                name: RouteNames.today,
                builder: (context, state) => const TodayPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.habitsPath,
                name: RouteNames.habits,
                builder: (context, state) => const MyHabitsPage(),
                routes: [
                  GoRoute(
                    path: RouteNames.addHabitPath,
                    name: RouteNames.addHabit,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddHabitPage(),
                  ),
                  GoRoute(
                    path: RouteNames.habitDetailPath,
                    name: RouteNames.habitDetail,
                    builder: (context, state) => _PlaceholderPage(
                      title: 'Habit ${state.pathParameters['habitId']}',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.routinesPath,
                name: RouteNames.routines,
                builder: (context, state) => const RoutinesHomePage(),
                routes: [
                  GoRoute(
                    path: RouteNames.createRoutinePath,
                    name: RouteNames.createRoutine,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreateRoutinePage(),
                  ),
                  GoRoute(
                    path: RouteNames.routineDetailPath,
                    name: RouteNames.routineDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final routineId = state.pathParameters['routineId'] ?? '';
                      final extra = state.extra as Routine?;
                      final routine = extra ??
                          Routine.defaults.firstWhere(
                            (r) => r.id == routineId,
                            orElse: () => Routine.defaults.first,
                          );
                      return RoutineDetailPage(routine: routine);
                    },
                  ),
                  GoRoute(
                    path: RouteNames.editRoutinePath,
                    name: RouteNames.editRoutine,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final routineId = state.pathParameters['routineId'] ?? '';
                      final extra = state.extra as Routine?;
                      final routine = extra ??
                          Routine.defaults.firstWhere(
                            (r) => r.id == routineId,
                            orElse: () => Routine.defaults.first,
                          );
                      return EditRoutinePage(routine: routine);
                    },
                  ),
                  GoRoute(
                    path: RouteNames.routineExecutionPath,
                    name: RouteNames.routineExecution,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final routineId = state.pathParameters['routineId'] ?? '';
                      final extra = state.extra as Routine?;
                      final routine = extra ??
                          Routine.defaults.firstWhere(
                            (r) => r.id == routineId,
                            orElse: () => Routine.defaults.first,
                          );
                      return RoutineExecutionPage(routine: routine);
                    },
                  ),
                  GoRoute(
                    path: RouteNames.routineCompletedPath,
                    name: RouteNames.routineCompleted,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final routineId = state.pathParameters['routineId'] ?? '';
                      final extra = state.extra as Routine?;
                      final routine = extra ??
                          Routine.defaults.firstWhere(
                            (r) => r.id == routineId,
                            orElse: () => Routine.defaults.first,
                          );
                      return RoutineCompletedPage(routine: routine);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.insightsPath,
                name: RouteNames.insights,
                builder: (context, state) => const InsightsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profilePath,
                name: RouteNames.profile,
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: RouteNames.editProfilePath,
                    name: RouteNames.editProfile,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const EditProfilePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});

/// Stands in for a feature that has not been built yet.
///
/// Replace each of these with the real page as its feature lands; the route
/// itself does not need to change.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title — coming soon')),
    );
  }
}
