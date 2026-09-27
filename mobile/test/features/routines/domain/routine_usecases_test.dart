import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/errors/result.dart';
import 'package:mobile/features/routines/domain/entities/routine_draft.dart';
import 'package:mobile/features/routines/domain/usecases/save_routine.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockRoutineRepository repository;
  late SaveRoutine saveRoutine;

  final routine = buildRoutineModel();

  setUpAll(registerFallbacks);

  setUp(() {
    repository = MockRoutineRepository();
    saveRoutine = SaveRoutine(repository);
    when(() => repository.createRoutine(any()))
        .thenAnswer((_) async => Success(routine));
    when(() => repository.updateRoutine(any(), any()))
        .thenAnswer((_) async => Success(routine));
  });

  Future<Failure?> failureFor(RoutineDraft draft) async =>
      (await saveRoutine(draft)).failureOrNull;

  test('creates when there is no routine id, with a trimmed name', () async {
    final result = await saveRoutine(buildRoutineDraft(name: '  Focus  '));

    expect(result.dataOrNull, routine);
    final sent =
        verify(() => repository.createRoutine(captureAny())).captured.single
            as RoutineDraft;
    expect(sent.name, 'Focus');
  });

  test('updates when given a routine id', () async {
    await saveRoutine(buildRoutineDraft(), routineId: 'routine-1');

    verify(() => repository.updateRoutine('routine-1', any())).called(1);
    verifyNever(() => repository.createRoutine(any()));
  });

  test('rejects a blank name', () async {
    expect(await failureFor(buildRoutineDraft(name: '   ')),
        isA<ValidationFailure>());
  });

  test('rejects a routine without steps', () async {
    expect(await failureFor(buildRoutineDraft(steps: const [])),
        isA<ValidationFailure>());
  });

  test('rejects more than 20 steps', () async {
    final steps = [
      for (var i = 0; i < 21; i++)
        RoutineStepDraft(habitId: 'habit-$i', durationMinutes: 5),
    ];
    expect(await failureFor(buildRoutineDraft(steps: steps)),
        isA<ValidationFailure>());
  });

  test('rejects the same habit twice', () async {
    const step = RoutineStepDraft(habitId: 'habit-1', durationMinutes: 5);
    expect(await failureFor(buildRoutineDraft(steps: const [step, step])),
        isA<ValidationFailure>());
  });

  test('rejects step durations outside 1–180 minutes', () async {
    const step = RoutineStepDraft(habitId: 'habit-1', durationMinutes: 181);
    expect(await failureFor(buildRoutineDraft(steps: const [step])),
        isA<ValidationFailure>());
  });

  test('never reaches the repository when invalid', () async {
    await saveRoutine(buildRoutineDraft(name: ''));

    verifyNever(() => repository.createRoutine(any()));
  });
}
