import 'package:flutter_test/flutter_test.dart';

import 'package:aawaaz/main.dart';

void main() {
  testWidgets('Home screen shows the three entry points', (tester) async {
    await tester.pumpWidget(const AawaazApp());

    expect(find.text('Aawaaz'), findsOneWidget);
    expect(find.text('Register a request'), findsOneWidget);
    expect(find.text('Register (new worker)'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);
  });
}
