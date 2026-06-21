import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rent_a_partner/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that splash screen text is present.
    expect(find.text('Rent A Partner'), findsOneWidget);
    expect(find.text('Find Your Perfect Companion'), findsOneWidget);
  });
}
