import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dutch_pay_calculator/screens/main_shell.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('MainShell: 하단 탭이 계산기·사다리·설정 3개다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));

    expect(find.text('계산기'), findsOneWidget);
    expect(find.text('사다리'), findsOneWidget);
    expect(find.text('설정'), findsWidgets);
  });

  testWidgets('MainShell: 사다리 탭을 누르면 사다리 설정 화면이 보인다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));

    await tester.tap(find.text('사다리'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '사다리 타기'), findsOneWidget);
    expect(find.byKey(const ValueKey('start')), findsOneWidget);
  });
}
