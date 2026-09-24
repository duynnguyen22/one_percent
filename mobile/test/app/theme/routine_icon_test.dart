import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/routine_icon.dart';

void main() {
  group('RoutineNavIcon', () {
    testWidgets('renders in unselected state without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RoutineNavIcon(
                isSelected: false,
                color: Colors.grey,
                size: 24,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RoutineNavIcon), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders in selected state without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RoutineNavIcon(
                isSelected: true,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RoutineNavIcon), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
