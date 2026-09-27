import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// When in the day a routine is meant to run. Stored as free text on the
/// backend (`cadence`, 1–30 characters), so a value outside [options] is kept
/// and shown as its own chip.
class CadencePicker extends StatelessWidget {
  const CadencePicker({
    super.key,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  static const List<String> options = [
    'Morning',
    'Afternoon',
    'Evening',
    'Weekend',
  ];

  final String value;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final choices = options.contains(value) ? options : [...options, value];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in choices)
          ChoiceChip(
            label: Text(option),
            selected: option == value,
            onSelected: (_) => onChanged(option),
            showCheckmark: false,
            selectedColor: accentColor.withValues(alpha: 0.18),
            backgroundColor: AppColors.surfaceContainerLowest,
            side: BorderSide.none,
            shape: const RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusPill,
            ),
            labelStyle: AppTypography.labelMedium.copyWith(
              color: option == value ? accentColor : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
