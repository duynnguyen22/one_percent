import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../injection/dependency_injection.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// State for the profile editing flow.
class ProfileEditState {
  const ProfileEditState({
    this.isSubmitting = false,
    this.failure,
  });

  final bool isSubmitting;
  final Failure? failure;

  ProfileEditState copyWith({
    bool? isSubmitting,
    Failure? failure,
  }) {
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

  Future<Failure?> updateProfile({
    String? userName,
    String? userPhone,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isSubmitting: true);

    final result = await ref.read(updateProfileUseCaseProvider)(
      userName: userName,
      userPhone: userPhone,
      avatarUrl: avatarUrl,
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
