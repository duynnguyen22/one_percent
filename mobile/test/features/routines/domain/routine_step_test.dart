import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routines/domain/entities/routine.dart';

void main() {
  RoutineStep step(List<RoutineGuide> guides) => RoutineStep(
    id: 'habit-1',
    title: 'Stretch',
    subtitle: '',
    durationMinutes: 5,
    category: '',
    guides: guides,
  );

  group('RoutineStep.activeGuideIndex', () {
    final guided = step(const [
      RoutineGuide(title: 'a', durationSeconds: 60),
      RoutineGuide(title: 'b', durationSeconds: 120),
    ]);

    test('is null without guides', () {
      expect(step(const []).activeGuideIndex(10), isNull);
    });

    test('moves to the next guide at each boundary', () {
      expect(guided.activeGuideIndex(0), 0);
      expect(guided.activeGuideIndex(59), 0);
      expect(guided.activeGuideIndex(60), 1);
      expect(guided.activeGuideIndex(179), 1);
    });

    test('keeps the last guide active past the end', () {
      expect(guided.activeGuideIndex(500), 1);
    });
  });

  test('RoutineGuide.durationLabel', () {
    expect(
      const RoutineGuide(title: 'x', durationSeconds: 45).durationLabel,
      '45s',
    );
    expect(
      const RoutineGuide(title: 'x', durationSeconds: 60).durationLabel,
      '1 min',
    );
    expect(
      const RoutineGuide(title: 'x', durationSeconds: 90).durationLabel,
      '1m 30s',
    );
  });
}
