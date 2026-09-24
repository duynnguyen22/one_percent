import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/shell/main_shell_scaffold.dart';
import 'package:mobile/app/theme/routine_icon.dart';

void main() {
  GoRouter createTestRouter({String initialLocation = '/today'}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShellScaffold(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/today',
                  builder: (context, state) => const Scaffold(body: Center(child: Text('Today Content'))),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/habits',
                  builder: (context, state) => const Scaffold(body: Center(child: Text('Habits Content'))),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/routines',
                  builder: (context, state) => const Scaffold(body: Center(child: Text('Routines Content'))),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/insights',
                  builder: (context, state) => const Scaffold(body: Center(child: Text('Insights Content'))),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const Scaffold(body: Center(child: Text('Profile Content'))),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  group('MainShellScaffold Bottom Navigation', () {
    testWidgets('renders all 5 bottom navigation tabs including Routines with crafted icon',
        (tester) async {
      final router = createTestRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.text('Routines'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      expect(find.byType(RoutineNavIcon), findsOneWidget);
    });

    testWidgets('tapping Routines tab navigates to routines branch', (tester) async {
      final router = createTestRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today Content'), findsOneWidget);

      // Tap the Routines tab
      await tester.tap(find.text('Routines'));
      await tester.pumpAndSettle();

      expect(find.text('Routines Content'), findsOneWidget);
    });

    testWidgets('renders without overflow on a small 320x568 screen', (tester) async {
      final router = createTestRouter();

      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Routines'), findsOneWidget);
      expect(find.byType(RoutineNavIcon), findsOneWidget);
    });
  });
}
