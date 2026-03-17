import 'package:flutter_test/flutter_test.dart';
import 'package:learnoo/main.dart';

void main() {
  testWidgets('Splash screen shows Learnoo app name', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LearnooApp());

    // Verify that Learnoo app name is shown.
    expect(find.text('Learnoo'), findsOneWidget);
    expect(find.text('Your academic journey starts here'), findsOneWidget);

    // Allow the splash timer to complete to avoid pending timer error
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
