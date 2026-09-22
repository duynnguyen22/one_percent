import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/network_info.dart';
import 'package:mobile/features/offline/presentation/pages/offline_page.dart';
import 'package:mobile/injection/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/toasts.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  group('OfflinePage', () {
    late MockNetworkInfo mockNetworkInfo;

    setUp(() {
      mockNetworkInfo = MockNetworkInfo();
    });

    testWidgets('renders all visual elements matching Stitch design', (tester) async {
      await pumpApp(
        tester,
        const OfflinePage(
          flowTitle: 'Add Habit Flow',
          lastSyncedText: 'Synced 8:30 AM',
        ),
      );

      // Header
      expect(find.text('Add Habit Flow'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      // Status Bar
      expect(find.text('Offline Mode Active'), findsOneWidget);
      expect(find.text('Synced 8:30 AM'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

      // Hero
      expect(find.byIcon(Icons.spa_rounded), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Connection Paused'), findsOneWidget);
      expect(
        find.textContaining('Your space of calm remains unbroken'),
        findsOneWidget,
      );

      // Capabilities Bento Card
      expect(find.text('Always Available Offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
      expect(find.text('Log mindful habits & check-ins'), findsOneWidget);
      expect(find.text('Your streaks remain continuous and intact.'), findsOneWidget);
      expect(find.text('Access guided timers & notes'), findsOneWidget);
      expect(find.text('Cached audio rings and reflections load instantly.'), findsOneWidget);
      expect(find.text('Seamless automatic sync'), findsOneWidget);
      expect(find.text('Changes quietly merge once connection resumes.'), findsOneWidget);

      // Action Buttons
      expect(find.text('Try Reconnecting'), findsOneWidget);
      expect(find.text('Continue in Offline Mode'), findsOneWidget);
    });

    testWidgets('triggers onContinueOffline when secondary button is tapped', (tester) async {
      bool continued = false;
      await pumpApp(
        tester,
        OfflinePage(
          onContinueOffline: () => continued = true,
        ),
      );

      final continueButton = find.text('Continue in Offline Mode');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();

      expect(continued, isTrue);
    });

    testWidgets('shows signal searching feedback banner when reconnection fails', (tester) async {
      final completer = Completer<bool>();
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) => completer.future);

      await pumpApp(
        tester,
        const OfflinePage(),
        overrides: [
          networkInfoProvider.overrideWithValue(mockNetworkInfo),
        ],
      );

      final reconnectButton = find.text('Try Reconnecting');
      await tester.ensureVisible(reconnectButton);
      await tester.tap(reconnectButton);
      await tester.pump();

      // In checking state - spinner is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete async future with offline (false)
      completer.complete(false);
      await tester.pump();
      await tester.pumpAndSettle();

      // Feedback banner is visible
      expect(
        find.text("Still searching for signal. You're safe to proceed offline."),
        findsOneWidget,
      );
    });

    testWidgets('shows success toast when reconnection succeeds', (tester) async {
      final completer = Completer<bool>();
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) => completer.future);

      await pumpRoutedApp(
        tester,
        const OfflinePage(),
        overrides: [
          networkInfoProvider.overrideWithValue(mockNetworkInfo),
        ],
      );

      final reconnectButton = find.text('Try Reconnecting');
      await tester.ensureVisible(reconnectButton);
      await tester.tap(reconnectButton);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(true);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Connection restored!'), findsOneWidget);

      await clearToasts(tester);
    });
  });
}
