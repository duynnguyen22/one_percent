import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';

/// Resolves a routine route's `:routineId` against the loaded routines.
///
/// Routes carry only the id, so a deep link, a refresh and an edit all show
/// the same, current routine rather than a copy frozen at navigation time.
class RoutineLoader extends ConsumerWidget {
  const RoutineLoader({
    super.key,
    required this.routineId,
    required this.builder,
  });

  final String routineId;
  final Widget Function(Routine routine) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routine = ref.watch(routineByIdProvider(routineId));

    return switch (routine) {
      AsyncData(value: final routine?) => builder(routine),
      AsyncData() => _Frame(
          child: AppError(
            title: 'Routine not found',
            message: 'It may have been deleted.',
            icon: Icons.search_off_rounded,
          ),
        ),
      AsyncError(:final error) => _Frame(
          child: AppError(
            message: error is Failure ? error.message : '$error',
            onRetry: () => ref.read(routinesProvider.notifier).refresh(),
          ),
        ),
      _ => const _Frame(child: AppLoading()),
    };
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
      body: Center(child: child),
    );
  }
}
