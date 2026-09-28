import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/result.dart';
import 'package:mobile/core/utils/date_utils.dart';
import 'package:mobile/features/habits/domain/entities/habit.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile/injection/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late MockHabitRepository habits;
  late MockEntryRepository entries;

  setUpAll(registerFallbacks);

  setUp(() {
    habits = MockHabitRepository();
    entries = MockEntryRepository();

    when(() => habits.getHabitsForDate(any()))
        .thenAnswer((_) async => const Success([]));
    when(() => habits.getHabits()).thenAnswer(
      (_) async => Success<List<Habit>>([
        buildHabitModel(
            id: 'habit-1', name: 'Read', createdAt: DateTime(2026, 1, 1)),
        buildHabitModel(
            id: 'habit-2', name: 'Stretch', createdAt: DateTime(2026, 1, 1)),
      ]),
    );
    when(() => entries.getEntries(
          habitId: any(named: 'habitId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        )).thenAnswer((_) async => Success([AppDateUtils.today]));
  });

  List<Override> overrides({List<Override> auth = const []}) => [
        ...(auth.isEmpty ? signedOutOverrides() : auth),
        habitRepositoryProvider.overrideWithValue(habits),
        entryRepositoryProvider.overrideWithValue(entries),
      ];

  testWidgets('shows the real habit count, not the hardcoded stats',
      (tester) async {
    await pumpApp(tester, const ProfilePage(), overrides: overrides());

    expect(find.text('2'), findsOneWidget);
    expect(find.text('14'), findsNothing);
    expect(find.text('88%'), findsNothing);
    expect(find.text('28'), findsNothing);
  });

  testWidgets('the stat row falls back to zeroes when nothing is tracked',
      (tester) async {
    when(() => habits.getHabits())
        .thenAnswer((_) async => const Success(<Habit>[]));

    await pumpApp(tester, const ProfilePage(), overrides: overrides());

    expect(find.text('0'), findsWidgets);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('shows when the account was created, not a fixed date',
      (tester) async {
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: overrides(
        auth: signedInOverrides(
          buildUserModel(createdAt: DateTime.utc(2026, 1, 15)),
        ),
      ),
    );

    expect(find.textContaining('Growing since January 2026'), findsOneWidget);
    expect(find.textContaining('Oct 2022'), findsNothing);
  });

  testWidgets('a signed-out profile shows a neutral tagline', (tester) async {
    await pumpApp(tester, const ProfilePage(), overrides: overrides());

    expect(find.text('Welcome to Bloom'), findsOneWidget);
  });

  testWidgets('shows userName and userPhone when provided on user profile',
      (tester) async {
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: overrides(
        auth: signedInOverrides(
          buildUserModel(
            userName: 'Samantha Ray',
            userPhone: '+1-555-0199',
          ),
        ),
      ),
    );

    expect(find.text('Samantha Ray'), findsOneWidget);
    expect(find.text('+1-555-0199'), findsOneWidget);
  });

  testWidgets('renders interactive edit badge button', (tester) async {
    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: overrides(
        auth: signedInOverrides(buildUserModel()),
      ),
    );

    expect(find.byKey(const Key('edit_profile_badge_button')), findsOneWidget);
  });

  testWidgets('renders and handles logout confirmation dialog', (tester) async {
    final mockAuthRepo = buildSignedInRepository(buildUserModel());
    when(mockAuthRepo.logout).thenAnswer((_) async => const Success(null));

    await pumpApp(
      tester,
      const ProfilePage(),
      overrides: overrides(
        auth: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
      ),
    );

    final logoutButton = find.widgetWithText(ElevatedButton, 'Log Out');
    await tester.ensureVisible(logoutButton);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(find.text('Log out of Bloom?'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to sign out? Your habit streaks and daily reflections will remain securely saved.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('logout_dialog_confirm_button')), findsOneWidget);
    expect(find.byKey(const Key('logout_dialog_cancel_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('logout_dialog_cancel_button')));
    await tester.pumpAndSettle();

    expect(find.text('Log out of Bloom?'), findsNothing);

    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('logout_dialog_confirm_button')));
    await tester.pumpAndSettle();

    verify(mockAuthRepo.logout).called(1);
    expect(find.text('Log out of Bloom?'), findsNothing);
  });
}

