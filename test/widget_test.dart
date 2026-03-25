import 'package:flutter_test/flutter_test.dart';

import 'package:surge/app.dart';

void main() {
  testWidgets('App renders without crashing', (tester) async {
    await tester.pumpWidget(const SurgeApp());
    await tester.pump();
    // HomeScreen is the root route; verify the app bar title appears.
    expect(find.text('Surge'), findsOneWidget);
  });
}
