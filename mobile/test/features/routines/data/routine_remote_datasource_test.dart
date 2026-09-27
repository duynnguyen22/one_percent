import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/routines/data/datasources/routine_remote_datasource.dart';
import 'package:mobile/features/routines/domain/entities/routine_draft.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late RoutineRemoteDataSourceImpl dataSource;

  Map<String, dynamic> row({String id = 'routine-1'}) => {
        'id': id,
        'name': 'Morning Ritual',
        'description': null,
        'color': '#4D6054',
        'cadence': 'Morning',
        'steps': [
          {
            'habitId': 'habit-1',
            'name': 'Read',
            'color': null,
            'order': 1,
            'durationMinutes': 5,
          },
        ],
      };

  Map<String, dynamic> envelope(Object? data) =>
      {'statusCode': 200, 'message': 'ok', 'data': data};

  const draft = RoutineDraft(
    name: 'Morning Ritual',
    description: 'Start grounded.',
    color: '#4D6054',
    cadence: 'Morning',
    steps: [
      RoutineStepDraft(habitId: 'habit-1', durationMinutes: 5),
      RoutineStepDraft(habitId: 'habit-2', durationMinutes: 10),
    ],
  );

  const draftBody = {
    'name': 'Morning Ritual',
    'description': 'Start grounded.',
    'color': '#4D6054',
    'cadence': 'Morning',
    'steps': [
      {'habitId': 'habit-1', 'durationMinutes': 5},
      {'habitId': 'habit-2', 'durationMinutes': 10},
    ],
  };

  setUp(() {
    client = MockApiClient();
    dataSource = RoutineRemoteDataSourceImpl(client);
  });

  test('getRoutines unwraps the envelope and sends the day', () async {
    when(() => client.get<Map<String, dynamic>>(
          ApiConstants.routines,
          queryParameters: {'date': '2026-09-27'},
        )).thenAnswer((_) async => envelope([row(), row(id: 'routine-2')]));

    final routines = await dataSource.getRoutines(date: DateTime(2026, 9, 27));

    expect(routines.map((r) => r.id), ['routine-1', 'routine-2']);
  });

  test('createRoutine posts the draft and parses the created routine',
      () async {
    when(() => client.post<Map<String, dynamic>>(
          ApiConstants.routines,
          data: draftBody,
        )).thenAnswer((_) async => envelope(row()));

    final routine = await dataSource.createRoutine(draft);

    expect(routine.id, 'routine-1');
  });

  test('updateRoutine patches the whole draft onto the routine', () async {
    when(() => client.patch<Map<String, dynamic>>(
          ApiConstants.routine('routine-1'),
          data: draftBody,
        )).thenAnswer((_) async => envelope(row()));

    final routine = await dataSource.updateRoutine('routine-1', draft);

    expect(routine.name, 'Morning Ritual');
  });

  test('a blank cadence is left out of the body', () async {
    const blank = RoutineDraft(
      name: 'Focus',
      description: '',
      color: '#4D6054',
      cadence: '  ',
      steps: [RoutineStepDraft(habitId: 'habit-1', durationMinutes: 5)],
    );
    when(() => client.post<Map<String, dynamic>>(
          ApiConstants.routines,
          data: any(named: 'data'),
        )).thenAnswer((_) async => envelope(row()));

    await dataSource.createRoutine(blank);

    final body = verify(() => client.post<Map<String, dynamic>>(
          ApiConstants.routines,
          data: captureAny(named: 'data'),
        )).captured.single as Map<String, dynamic>;
    expect(body.containsKey('cadence'), isFalse);
  });

  test('deleteRoutine calls DELETE /routines/:id', () async {
    when(() => client.delete<Map<String, dynamic>>(
          ApiConstants.routine('routine-1'),
        )).thenAnswer((_) async => envelope(null));

    await dataSource.deleteRoutine('routine-1');

    verify(() => client.delete<Map<String, dynamic>>(
          ApiConstants.routine('routine-1'),
        )).called(1);
  });
}
