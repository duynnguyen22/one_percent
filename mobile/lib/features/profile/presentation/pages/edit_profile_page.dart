import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Screen allowing the user to update their optional profile details
/// (username, phone number, and avatar image URL).
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarUrlController;
  var _didInitFromUser = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.userName ?? '');
    _phoneController = TextEditingController(text: user?.userPhone ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');
    if (user != null) {
      _didInitFromUser = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final avatar = _avatarUrlController.text.trim();

    final failure = await ref.read(profileEditProvider.notifier).updateProfile(
          userName: name,
          userPhone: phone,
          avatarUrl: avatar,
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
          _avatarUrlController.text = next.avatarUrl ?? '';
          _didInitFromUser = true;
        });
      }
    });

    final editState = ref.watch(profileEditProvider);
    final user = ref.watch(currentUserProvider);
    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (user?.displayName ?? '');

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

                    // Avatar Preview
                    Center(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _avatarUrlController,
                        builder: (context, value, _) {
                          final currentUrl = value.text.trim();
                          return Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryContainer.withValues(alpha: 0.15),
                              border: Border.all(
                                color: AppColors.surface,
                                width: 4,
                              ),
                              boxShadow: AppSpacing.ambientShadow,
                            ),
                            child: ClipOval(
                              child: currentUrl.isNotEmpty
                                  ? Image.network(
                                      currentUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          displayName.isEmpty
                                              ? '\u{1F331}'
                                              : displayName[0],
                                          style: AppTypography.display.copyWith(
                                            color: AppColors.primary,
                                            fontSize: 42,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        displayName.isEmpty
                                            ? '\u{1F331}'
                                            : displayName[0],
                                        style: AppTypography.display.copyWith(
                                          color: AppColors.primary,
                                          fontSize: 42,
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
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
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),

                    // Avatar URL Field
                    AppTextField(
                      controller: _avatarUrlController,
                      label: 'Avatar URL',
                      hintText: 'https://example.com/avatar.png',
                      prefixIcon: Icons.image_outlined,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onSave(),
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
