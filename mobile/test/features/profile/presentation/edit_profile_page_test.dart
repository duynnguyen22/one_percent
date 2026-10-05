import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/errors/result.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:mobile/injection/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/toasts.dart';

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late MockProfileRepository profileRepo;
  late MockImagePicker imagePicker;

  setUpAll(() {
    registerFallbacks();
    registerFallbackValue(ImageSource.gallery);
  });

  setUp(() {
    profileRepo = MockProfileRepository();
    imagePicker = MockImagePicker();
  });

  List<Override> overrides({User? user}) => [
    ...(user != null ? signedInOverrides(user) : signedOutOverrides()),
    profileRepositoryProvider.overrideWithValue(profileRepo),
    imagePickerProvider.overrideWithValue(imagePicker),
  ];

  testWidgets('renders all fields and pre-populates existing user details', (
    tester,
  ) async {
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
    expect(find.text('Profile Photo'), findsOneWidget);
    expect(find.text('Current photo'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('submitting calls updateProfile on profile repository', (
    tester,
  ) async {
    final user = buildUserModel(userName: 'Old Name', userPhone: '111');

    final updatedUser = buildUserModel(userName: 'New Name', userPhone: '222');

    when(
      () => profileRepo.updateProfile(
        userName: any(named: 'userName'),
        userPhone: any(named: 'userPhone'),
        avatarUrl: any(named: 'avatarUrl'),
      ),
    ).thenAnswer((_) async => Success(updatedUser));

    await pumpRoutedApp(
      tester,
      const EditProfilePage(),
      overrides: overrides(user: user),
    );

    // Edit the text fields
    await tester.enterText(find.byType(TextField).at(0), 'New Name');
    await tester.enterText(find.byType(TextField).at(1), '222');
    await tester.pump();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    verify(
      () => profileRepo.updateProfile(userName: 'New Name', userPhone: '222'),
    ).called(1);
    verifyNever(() => profileRepo.uploadAvatar(any()));
    await clearToasts(tester);
  });

  testWidgets('uploads a picked photo before saving the text fields', (
    tester,
  ) async {
    final user = buildUserModel(userName: 'Alex', userPhone: '111');
    final withAvatar = buildUserModel(
      userName: 'Alex',
      userPhone: '111',
      avatarUrl: '/uploads/avatars/new.jpg',
    );

    when(
      () => imagePicker.pickImage(
        source: any(named: 'source'),
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
      ),
    ).thenAnswer((_) async => XFile('/tmp/picked.jpg'));
    when(
      () => profileRepo.uploadAvatar(any()),
    ).thenAnswer((_) async => Success(withAvatar));
    when(
      () => profileRepo.updateProfile(
        userName: any(named: 'userName'),
        userPhone: any(named: 'userPhone'),
        avatarUrl: any(named: 'avatarUrl'),
      ),
    ).thenAnswer((_) async => Success(withAvatar));

    await pumpRoutedApp(
      tester,
      const EditProfilePage(),
      overrides: overrides(user: user),
    );

    expect(find.text('No photo yet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit_profile_avatar_upload')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from library'));
    await tester.pumpAndSettle();

    verify(
      () => imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
      ),
    ).called(1);
    expect(find.text('New photo selected'), findsOneWidget);

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    verifyInOrder([
      () => profileRepo.uploadAvatar('/tmp/picked.jpg'),
      () => profileRepo.updateProfile(userName: 'Alex', userPhone: '111'),
    ]);
    await clearToasts(tester);
  });

  testWidgets('shows the upload error and skips the profile update', (
    tester,
  ) async {
    when(
      () => imagePicker.pickImage(
        source: any(named: 'source'),
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
      ),
    ).thenAnswer((_) async => XFile('/tmp/picked.jpg'));
    when(() => profileRepo.uploadAvatar(any())).thenAnswer(
      (_) async => const ResultError(
        ValidationFailure('Avatar must be a JPEG, PNG or WebP image'),
      ),
    );

    await pumpRoutedApp(
      tester,
      const EditProfilePage(),
      overrides: overrides(user: buildUserModel()),
    );

    await tester.tap(find.byKey(const Key('edit_profile_avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(
      find.text('Avatar must be a JPEG, PNG or WebP image'),
      findsOneWidget,
    );
    verifyNever(
      () => profileRepo.updateProfile(
        userName: any(named: 'userName'),
        userPhone: any(named: 'userPhone'),
        avatarUrl: any(named: 'avatarUrl'),
      ),
    );
    await clearToasts(tester);
  });

  testWidgets('shows error when update fails', (tester) async {
    when(
      () => profileRepo.updateProfile(
        userName: any(named: 'userName'),
        userPhone: any(named: 'userPhone'),
        avatarUrl: any(named: 'avatarUrl'),
      ),
    ).thenAnswer(
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
