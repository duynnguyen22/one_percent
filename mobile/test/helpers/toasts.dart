import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

/// Dismisses every toast and runs out the timers behind it.
///
/// `toastification` is a global that outlives each test's widget tree. A toast
/// left on screen keeps its auto-close timer running, which fails the test, and
/// holds an overlay entry in the disposed tree, so the next test's toasts would
/// never appear. Call this last in any test that shows one.
Future<void> clearToasts(WidgetTester tester) async {
  // Flush a toast still waiting on its post-frame insert.
  await tester.pump();
  toastification.dismissAll(delayForAnimation: false);
  // Past the exit animation and the removal delay that follows it.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}
