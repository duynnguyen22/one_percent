import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../injection/dependency_injection.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// State for the profile editing flow.
class ProfileEditState {
  const ProfileEditState({this.isSubmitting = false, this.failure});

  final bool isSubmitting;
  final Failure? failure;

  ProfileEditState copyWith({bool? isSubmitting, Failure? failure}) {
    return ProfileEditState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: failure,
    );
  }
}

/// Drives profile updates and synchronises the updated user with [authNotifierProvider].
class ProfileEditNotifier extends Notifier<ProfileEditState> {
  @override
  ProfileEditState build() => const ProfileEditState();

  /// Saves the text fields and, when [avatarFilePath] is given, uploads it as
  /// the new avatar first. Stops at the first failure.
  Future<Failure?> updateProfile({
    String? userName,
    String? userPhone,
    String? avatarFilePath,
  }) async {
    state = state.copyWith(isSubmitting: true);

    if (avatarFilePath != null) {
      final upload = await ref.read(uploadAvatarUseCaseProvider)(
        avatarFilePath,
      );
      switch (upload) {
        case Success(:final data):
          // Shown right away, even if the text fields then fail to save.
          ref.read(authNotifierProvider.notifier).updateUser(data);
        case ResultError(:final failure):
          state = state.copyWith(isSubmitting: false, failure: failure);
          return failure;
      }
    }

    final result = await ref.read(updateProfileUseCaseProvider)(
      userName: userName,
      userPhone: userPhone,
    );

    switch (result) {
      case Success(:final data):
        ref.read(authNotifierProvider.notifier).updateUser(data);
        state = const ProfileEditState(isSubmitting: false);
        return null;
      case ResultError(:final failure):
        state = state.copyWith(isSubmitting: false, failure: failure);
        return failure;
    }
  }
}

final profileEditProvider =
    NotifierProvider<ProfileEditNotifier, ProfileEditState>(
      ProfileEditNotifier.new,
    );

/// The platform photo picker, behind a provider so tests can stub it.
final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());
