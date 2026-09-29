import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Screen allowing the user to update their optional profile details
/// (username, phone number, and avatar photo).
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  var _didInitFromUser = false;

  /// A photo picked on this screen, uploaded only when the user saves.
  XFile? _pickedAvatar;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.userName ?? '');
    _phoneController = TextEditingController(text: user?.userPhone ?? '');
    if (user != null) {
      _didInitFromUser = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      // Downsized on the device: an avatar never needs a 12MP original, and
      // it keeps the upload well under the backend's 5MB limit.
      final picked = await ref
          .read(imagePickerProvider)
          .pickImage(
            source: source,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );
      if (picked != null && mounted) setState(() => _pickedAvatar = picked);
    } on Exception {
      AppToast.error('Could not open your photos. Check app permissions.');
    }
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final failure = await ref
        .read(profileEditProvider.notifier)
        .updateProfile(
          userName: name,
          userPhone: phone,
          avatarFilePath: _pickedAvatar?.path,
        );

    if (!mounted) return;

    if (failure != null) {
      AppToast.error(failure.message);
      return;
    }

    AppToast.success('Profile updated successfully');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (!_didInitFromUser && next != null) {
        setState(() {
          _nameController.text = next.userName ?? '';
          _phoneController.text = next.userPhone ?? '';
          _didInitFromUser = true;
        });
      }
    });

    final editState = ref.watch(profileEditProvider);
    final user = ref.watch(currentUserProvider);
    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (user?.displayName ?? '');
    final savedAvatarUrl = user?.avatarUrl?.trim() ?? '';
    final initial = Center(
      child: Text(
        displayName.isEmpty ? '\u{1F331}' : displayName[0],
        style: AppTypography.display.copyWith(
          color: AppColors.primary,
          fontSize: 42,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.onSurface,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Profile',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Avatar Preview — tap to pick a new photo
                    Center(
                      child: GestureDetector(
                        key: const Key('edit_profile_avatar'),
                        onTap: editState.isSubmitting ? null : _pickAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryContainer.withValues(
                                  alpha: 0.15,
                                ),
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 4,
                                ),
                                boxShadow: AppSpacing.ambientShadow,
                              ),
                              child: ClipOval(
                                child: _pickedAvatar != null
                                    ? Image.file(
                                        File(_pickedAvatar!.path),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => initial,
                                      )
                                    : savedAvatarUrl.isNotEmpty
                                    ? Image.network(
                                        ApiConstants.mediaUrl(savedAvatarUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => initial,
                                      )
                                    : initial,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryContainer,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.photo_camera_rounded,
                                  color: AppColors.onPrimaryContainer,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'All fields below are optional',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // User Name Field
                    AppTextField(
                      controller: _nameController,
                      label: 'User Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // User Phone Field
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 20),

                    // Avatar Upload Field
                    _AvatarUploadField(
                      hasSavedAvatar: savedAvatarUrl.isNotEmpty,
                      pickedFileName: _pickedAvatar?.name,
                      onTap: editState.isSubmitting ? null : _pickAvatar,
                    ),
                    const SizedBox(height: 36),

                    // Save Button
                    AppButton(
                      label: 'Save Changes',
                      isLoading: editState.isSubmitting,
                      onPressed: editState.isSubmitting ? null : _onSave,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Replaces the old avatar URL text field: shows what will be saved and opens
/// the photo picker on tap. Styled to sit with the [AppTextField]s above it.
class _AvatarUploadField extends StatelessWidget {
  const _AvatarUploadField({
    required this.hasSavedAvatar,
    required this.pickedFileName,
    required this.onTap,
  });

  final bool hasSavedAvatar;
  final String? pickedFileName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final picked = pickedFileName != null;
    final status = picked
        ? 'New photo selected'
        : hasSavedAvatar
        ? 'Current photo'
        : 'No photo yet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            'Profile Photo',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Material(
          color: AppColors.surfaceContainer,
          borderRadius: AppSpacing.borderRadiusPill,
          child: InkWell(
            key: const Key('edit_profile_avatar_upload'),
            borderRadius: AppSpacing.borderRadiusPill,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(
                    picked
                        ? Icons.check_circle_outline_rounded
                        : Icons.image_outlined,
                    color: picked
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.upload_rounded,
                          size: 16,
                          color: AppColors.onPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          picked || hasSavedAvatar ? 'Change' : 'Upload',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
