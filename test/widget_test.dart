import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dutch_pay_calculator/main.dart';

/// MaterialApp 으로 감싸 Navigator·MediaQuery 컨텍스트를 제공한다.
Widget _wrap(Widget child) => MaterialApp(
      home: child,
      debugShowCheckedModeBanner: false,
    );

void main() {
  testWidgets('App launches and splash transitions to main screen',
      (tester) async {
    await tester.pumpWidget(const DutchPayApp());

    // SplashScreen 의 텍스트 확인.
    expect(find.text('더치페이 계산기'), findsOneWidget);

    // SplashScreen Future.delayed(1500ms) + fadeOut(500ms) + 페이지 전환을 모두 소진.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 전환 완료 후 MainScreen 의 키패드/계산하기 버튼이 보여야 한다.
    expect(find.text('계산하기'), findsOneWidget);
    expect(find.text('1명'), findsOneWidget);
  });

  testWidgets('MainScreen: 키패드 입력으로 금액이 천 단위 콤마와 함께 표시된다',
      (tester) async {
    await tester.pumpWidget(_wrap(const MainScreen()));

    expect(find.text('얼마를 나눌까요?'), findsOneWidget);

    for (final k in ['1', '2', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }

    expect(find.text('12,000원'), findsOneWidget);
    expect(find.text('얼마를 나눌까요?'), findsNothing);
  });

  testWidgets('MainScreen: ⌫ 버튼이 마지막 자리를 지운다', (tester) async {
    await tester.pumpWidget(_wrap(const MainScreen()));

    for (final k in ['1', '2', '3']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    expect(find.text('123원'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(find.text('12원'), findsOneWidget);
  });

  testWidgets('MainScreen: C 버튼이 입력을 모두 지운다', (tester) async {
    await tester.pumpWidget(_wrap(const MainScreen()));

    for (final k in ['9', '9', '9']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    expect(find.text('999원'), findsOneWidget);

    await tester.tap(find.text('C'));
    await tester.pump();
    expect(find.text('얼마를 나눌까요?'), findsOneWidget);
  });

  testWidgets('MainScreen: +/- 버튼이 인원수를 1~100 범위에서 조정한다',
      (tester) async {
    await tester.pumpWidget(_wrap(const MainScreen()));

    expect(find.text('1명'), findsOneWidget);

    // - 버튼은 1 미만으로 내려가지 않는다.
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('1명'), findsOneWidget);

    // + 두 번 → 3명
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('3명'), findsOneWidget);

    // - 한 번 → 2명
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('2명'), findsOneWidget);
  });

  testWidgets(
      'MainScreen: 10,000원 / 3명 → 3,333원 + 1원 나머지 메시지가 표시된다',
      (tester) async {
    await tester.pumpWidget(_wrap(const MainScreen()));

    for (final k in ['1', '0', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('3명'), findsOneWidget);

    await tester.tap(find.text('계산하기'));
    await tester.pump();

    expect(find.text('1인당 금액'), findsOneWidget);
    expect(find.text('3,333원'), findsOneWidget);
    expect(find.text('1원은 누가 낼래?'), findsOneWidget);
  });

  testWidgets('MainScreen: 나머지가 0이면 안내 텍스트가 보이지 않는다',
      (tester) async {
    await tester.pumpWidget(_wrap(const MainScreen()));

    // 9,000원 / 3명 = 3,000원, 나머지 0
    for (final k in ['9', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    await tester.tap(find.text('계산하기'));
    await tester.pump();

    expect(find.text('3,000원'), findsOneWidget);
    expect(find.textContaining('누가 낼래?'), findsNothing);
  });

  testWidgets('MainScreen: 금액이 0이면 계산하기 버튼이 비활성화된다',
      (tester) async {
    await tester.pumpWidget(_wrap(const MainScreen()));

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '계산하기'),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.text('5'));
    await tester.pump();

    final enabledButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '계산하기'),
    );
    expect(enabledButton.onPressed, isNotNull);
  });
}
