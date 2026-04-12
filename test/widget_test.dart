import 'package:flutter_test/flutter_test.dart';

import 'package:dutch_pay_calculator/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DutchPayApp());
    expect(find.text('더치페이 계산기'), findsOneWidget);
  });
}
