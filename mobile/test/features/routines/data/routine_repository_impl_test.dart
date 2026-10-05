import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/features/routines/data/repositories/routine_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockRoutineRemoteDataSource remote;
  late MockNetworkInfo network;
  late RoutineRepositoryImpl repository;

  final routine = buildRoutineModel();
  final draft = buildRoutineDraft();

  setUpAll(registerFallbacks);

  setUp(() {
    remote = MockRoutineRemoteDataSource();
    network = MockNetworkInfo();
    when(() => network.isConnected).thenAnswer((_) async => true);
    repository = RoutineRepositoryImpl(
      remoteDataSource: remote,
      networkInfo: network,
    );
  });

  test('getRoutines returns the list for the day', () async {
    when(
      () => remote.getRoutines(date: any(named: 'date')),
    ).thenAnswer((_) async => [routine]);

    final result = await repository.getRoutines(date: DateTime(2026, 9, 27));

    expect(result.dataOrNull, [routine]);
  });

  test('short-circuits when offline without touching the network', () async {
    when(() => network.isConnected).thenAnswer((_) async => false);

    final result = await repository.createRoutine(draft);

    expect(result.failureOrNull, isA<NetworkFailure>());
    verifyNever(() => remote.createRoutine(any()));
  });

  test('forwards create, update and delete to the data source', () async {
    when(() => remote.createRoutine(draft)).thenAnswer((_) async => routine);
    when(
      () => remote.updateRoutine(routine.id, draft),
    ).thenAnswer((_) async => routine);
    when(() => remote.deleteRoutine(routine.id)).thenAnswer((_) async {});

    expect((await repository.createRoutine(draft)).dataOrNull, routine);
    expect(
      (await repository.updateRoutine(routine.id, draft)).dataOrNull,
      routine,
    );
    expect((await repository.deleteRoutine(routine.id)).isSuccess, isTrue);
  });

  test('maps AppExceptions onto Failures', () async {
    final cases = <AppException, Type>{
      const UnauthorizedException(): AuthFailure,
      const ValidationException('Each habit can appear only once'):
          ValidationFailure,
      const NotFoundException('Routine not found!'): NotFoundFailure,
      const ServerException('boom', statusCode: 500): ServerFailure,
    };

    for (final entry in cases.entries) {
      when(() => remote.deleteRoutine(any())).thenThrow(entry.key);

      final result = await repository.deleteRoutine('routine-1');

      expect(result.failureOrNull.runtimeType, entry.value);
      expect(result.failureOrNull!.message, entry.key.message);
    }
  });

  test('an unrecognised error becomes UnexpectedFailure', () async {
    when(
      () => remote.getRoutines(date: any(named: 'date')),
    ).thenThrow(StateError('nope'));

    final result = await repository.getRoutines();

    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });
}
