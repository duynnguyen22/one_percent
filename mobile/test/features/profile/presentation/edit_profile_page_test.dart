import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/errors/result.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:mobile/injection/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/toasts.dart';

void main() {
  late MockProfileRepository profileRepo;

  setUpAll(registerFallbacks);

  setUp(() {
    profileRepo = MockProfileRepository();
  });

  List<Override> overrides({User? user}) => [
        ...(user != null ? signedInOverrides(user) : signedOutOverrides()),
        profileRepositoryProvider.overrideWithValue(profileRepo),
      ];

  testWidgets('renders all fields and pre-populates existing user details',
      (tester) async {
    final user = buildUserModel(
      userName: 'Alex Smith',
      userPhone: '+1987654321',
      avatarUrl: 'https://example.com/pic.png',
    );

    await pumpRoutedApp(
      tester,
      const EditProfilePage(),
      overrides: overrides(user: user),
    );

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('All fields below are optional'), findsOneWidget);
    expect(find.text('Alex Smith'), findsWidgets);
    expect(find.text('+1987654321'), findsOneWidget);
    expect(find.text('https://example.com/pic.png'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('submitting calls updateProfile on profile repository',
      (tester) async {
    final user = buildUserModel(
      userName: 'Old Name',
      userPhone: '111',
      avatarUrl: 'https://old.png',
    );

    final updatedUser = buildUserModel(
      userName: 'New Name',
      userPhone: '222',
      avatarUrl: 'https://new.png',
    );

    when(() => profileRepo.updateProfile(
          userName: any(named: 'userName'),
          userPhone: any(named: 'userPhone'),
          avatarUrl: any(named: 'avatarUrl'),
        )).thenAnswer((_) async => Success(updatedUser));

    await pumpRoutedApp(
      tester,
      const EditProfilePage(),
      overrides: overrides(user: user),
    );

    // Edit the text fields
    await tester.enterText(find.byType(TextField).at(0), 'New Name');
    await tester.enterText(find.byType(TextField).at(1), '222');
    await tester.enterText(find.byType(TextField).at(2), 'https://new.png');
    await tester.pump();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    verify(() => profileRepo.updateProfile(
          userName: 'New Name',
          userPhone: '222',
          avatarUrl: 'https://new.png',
        )).called(1);
    await clearToasts(tester);
  });

  testWidgets('shows error when update fails', (tester) async {
    when(() => profileRepo.updateProfile(
          userName: any(named: 'userName'),
          userPhone: any(named: 'userPhone'),
          avatarUrl: any(named: 'avatarUrl'),
        )).thenAnswer(
      (_) async => const ResultError(ServerFailure('Update failed')),
    );

    await pumpRoutedApp(
      tester,
      const EditProfilePage(),
      overrides: overrides(user: buildUserModel()),
    );

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Update failed'), findsOneWidget);
    await clearToasts(tester);
  });
}
