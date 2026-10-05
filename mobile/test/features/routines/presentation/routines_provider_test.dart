import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/errors/result.dart';
import 'package:mobile/features/routines/presentation/providers/routines_provider.dart';
import 'package:mobile/injection/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockRoutineRepository routines;
  late MockEntryRepository entries;

  setUpAll(registerFallbacks);

  final morning = buildRoutineModel(id: 'routine-1', name: 'Morning Ritual');
  final evening = buildRoutineModel(id: 'routine-2', name: 'Wind Down');

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        routineRepositoryProvider.overrideWithValue(routines),
        entryRepositoryProvider.overrideWithValue(entries),
      ],
    );
    addTearDown(container.dispose);
    // Keeps the auto-disposing provider alive for the whole test.
    container.listen(routinesProvider, (_, _) {});
    return container;
  }

  setUp(() {
    routines = MockRoutineRepository();
    entries = MockEntryRepository();
    when(
      () => routines.getRoutines(date: any(named: 'date')),
    ).thenAnswer((_) async => Success([morning, evening]));
  });

  test('loads the routines on build', () async {
    final container = buildContainer();

    final list = await container.read(routinesProvider.future);

    expect(list.map((r) => r.name), ['Morning Ritual', 'Wind Down']);
  });

  test('a load failure surfaces as an AsyncError', () async {
    when(
      () => routines.getRoutines(date: any(named: 'date')),
    ).thenAnswer((_) async => const ResultError(ServerFailure('boom')));
    final container = buildContainer();

    await expectLater(
      container.read(routinesProvider.future),
      throwsA(isA<ServerFailure>()),
    );
  });

  test('routineByIdProvider finds a loaded routine', () async {
    final container = buildContainer();
    await container.read(routinesProvider.future);

    expect(container.read(routineByIdProvider('routine-2')).value, evening);
    expect(container.read(routineByIdProvider('missing')).value, isNull);
  });

  group('save', () {
    test('creating reloads so the new routine appears', () async {
      final created = buildRoutineModel(id: 'routine-3', name: 'Focus');
      when(
        () => routines.createRoutine(any()),
      ).thenAnswer((_) async => Success(created));
      final container = buildContainer();
      await container.read(routinesProvider.future);
      when(
        () => routines.getRoutines(date: any(named: 'date')),
      ).thenAnswer((_) async => Success([created, morning, evening]));

      final failure = await container
          .read(routinesProvider.notifier)
          .save(buildRoutineDraft(name: 'Focus'));

      expect(failure, isNull);
      expect(container.read(routinesProvider).value, hasLength(3));
    });

    test('updating swaps in the routine the server returned', () async {
      final renamed = buildRoutineModel(id: 'routine-1', name: 'Sunrise');
      when(
        () => routines.updateRoutine('routine-1', any()),
      ).thenAnswer((_) async => Success(renamed));
      final container = buildContainer();
      await container.read(routinesProvider.future);

      await container
          .read(routinesProvider.notifier)
          .save(buildRoutineDraft(name: 'Sunrise'), routineId: 'routine-1');

      expect(container.read(routinesProvider).value!.map((r) => r.name), [
        'Sunrise',
        'Wind Down',
      ]);
    });

    test('returns the failure and leaves the list alone', () async {
      when(() => routines.createRoutine(any())).thenAnswer(
        (_) async => const ResultError(ValidationFailure('bad habit')),
      );
      final container = buildContainer();
      await container.read(routinesProvider.future);

      final failure = await container
          .read(routinesProvider.notifier)
          .save(buildRoutineDraft());

      expect(failure, isA<ValidationFailure>());
      expect(container.read(routinesProvider).value, hasLength(2));
    });
  });

  group('remove', () {
    test('drops the routine', () async {
      when(
        () => routines.deleteRoutine('routine-1'),
      ).thenAnswer((_) async => const Success(null));
      final container = buildContainer();
      await container.read(routinesProvider.future);

      final failure = await container
          .read(routinesProvider.notifier)
          .remove('routine-1');

      expect(failure, isNull);
      expect(container.read(routinesProvider).value, [evening]);
    });

    test('restores the routine when the delete fails', () async {
      when(
        () => routines.deleteRoutine('routine-1'),
      ).thenAnswer((_) async => const ResultError(NetworkFailure()));
      final container = buildContainer();
      await container.read(routinesProvider.future);

      final failure = await container
          .read(routinesProvider.notifier)
          .remove('routine-1');

      expect(failure, isA<NetworkFailure>());
      expect(container.read(routinesProvider).value, [morning, evening]);
    });
  });

  group('completeStep', () {
    test('checks the habit off for today and marks the step done', () async {
      when(
        () => entries.checkOff(
          habitId: any(named: 'habitId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async => Success(buildHabitEntryModel()));
      final container = buildContainer();
      await container.read(routinesProvider.future);
      final habitId = morning.steps.first.habitId;

      final failure = await container
          .read(routinesProvider.notifier)
          .completeStep('routine-1', habitId);

      expect(failure, isNull);
      verify(
        () => entries.checkOff(
          habitId: habitId,
          date: any(named: 'date'),
        ),
      ).called(1);
      final step = container
          .read(routineByIdProvider('routine-1'))
          .value!
          .steps
          .first;
      expect(step.isCompleted, isTrue);
    });

    test('does not call the API for a step already done today', () async {
      final done = buildRoutineModel(id: 'routine-1', firstStepDone: true);
      when(
        () => routines.getRoutines(date: any(named: 'date')),
      ).thenAnswer((_) async => Success([done]));
      final container = buildContainer();
      await container.read(routinesProvider.future);

      await container
          .read(routinesProvider.notifier)
          .completeStep('routine-1', done.steps.first.habitId);

      verifyNever(
        () => entries.checkOff(
          habitId: any(named: 'habitId'),
          date: any(named: 'date'),
        ),
      );
    });

    test('returns the failure and leaves the step unchecked', () async {
      when(
        () => entries.checkOff(
          habitId: any(named: 'habitId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async => const ResultError(NetworkFailure()));
      final container = buildContainer();
      await container.read(routinesProvider.future);

      final failure = await container
          .read(routinesProvider.notifier)
          .completeStep('routine-1', morning.steps.first.habitId);

      expect(failure, isA<NetworkFailure>());
      expect(
        container
            .read(routineByIdProvider('routine-1'))
            .value!
            .steps
            .first
            .isCompleted,
        isFalse,
      );
    });
  });
}
