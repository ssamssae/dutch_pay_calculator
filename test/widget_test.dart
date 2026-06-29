import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dutch_pay_calculator/screens/calculator_screen.dart';

/// MaterialApp 으로 감싸 Navigator·MediaQuery 컨텍스트를 제공한다.
Widget _wrap(Widget child) =>
    MaterialApp(home: child, debugShowCheckedModeBanner: false);

void main() {
  // 인원을 2명으로 두면 1인당 금액이 총 금액과 달라져 총 금액 텍스트가 유일해진다
  // (1명일 때는 실시간 계산으로 총 금액 == 1인당 금액이라 텍스트가 중복된다).
  Future<void> setTwoPeople(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
  }

  testWidgets('CalculatorScreen: 키패드 입력으로 금액이 천 단위 콤마와 함께 표시된다', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const CalculatorScreen()));
    await setTwoPeople(tester);

    expect(find.text('얼마를 나눌까요?'), findsOneWidget);

    for (final k in ['1', '2', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }

    expect(find.text('12,000원'), findsOneWidget);
    expect(find.text('얼마를 나눌까요?'), findsNothing);
  });

  testWidgets('CalculatorScreen: ⌫ 버튼이 마지막 자리를 지운다', (tester) async {
    await tester.pumpWidget(_wrap(const CalculatorScreen()));
    await setTwoPeople(tester);

    for (final k in ['1', '2', '3']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    expect(find.text('123원'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(find.text('12원'), findsOneWidget);
  });

  testWidgets('CalculatorScreen: C 버튼이 입력을 모두 지운다', (tester) async {
    await tester.pumpWidget(_wrap(const CalculatorScreen()));
    await setTwoPeople(tester);

    for (final k in ['9', '9', '9']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    expect(find.text('999원'), findsOneWidget);

    await tester.tap(find.text('C'));
    await tester.pump();
    expect(find.text('얼마를 나눌까요?'), findsOneWidget);
  });

  testWidgets('CalculatorScreen: +/- 버튼이 인원수를 1~100 범위에서 조정한다', (tester) async {
    await tester.pumpWidget(_wrap(const CalculatorScreen()));

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

  testWidgets('CalculatorScreen: +10/-10 버튼이 10명씩 조정하고 1~100 범위로 clamp 된다', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const CalculatorScreen()));

    expect(find.text('1명'), findsOneWidget);

    // +10 → 11명
    await tester.tap(find.text('+10'));
    await tester.pump();
    expect(find.text('11명'), findsOneWidget);

    // -10 → 1명 (clamp, 1 미만 내려가지 않음)
    await tester.tap(find.text('-10'));
    await tester.pump();
    expect(find.text('1명'), findsOneWidget);
  });

  testWidgets('CalculatorScreen: 10,000원 / 3명 → 3,333원 + 1원 나머지가 실시간 표시된다', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const CalculatorScreen()));

    for (final k in ['1', '0', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('3명'), findsOneWidget);

    // 계산하기 버튼 없이 실시간으로 결과가 보인다.
    expect(find.text('1인당 금액'), findsOneWidget);
    expect(find.text('3,333원'), findsOneWidget);
    expect(find.text('남는 돈 1원'), findsOneWidget);
    expect(find.text('카톡으로 공유'), findsOneWidget);
  });

  testWidgets('CalculatorScreen: 나머지가 0이면 안내 텍스트가 보이지 않는다', (tester) async {
    await tester.pumpWidget(_wrap(const CalculatorScreen()));

    // 9,000원 / 3명 = 3,000원, 나머지 0
    for (final k in ['9', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('3,000원'), findsOneWidget);
    expect(find.textContaining('남는 돈'), findsNothing);
  });

  testWidgets('CalculatorScreen: 주요 입력 컨트롤에 접근성 툴팁이 있다', (tester) async {
    await tester.pumpWidget(_wrap(const CalculatorScreen()));

    expect(find.byTooltip('1명 줄이기'), findsOneWidget);
    expect(find.byTooltip('1명 늘리기'), findsOneWidget);
    expect(find.byTooltip('한 자리 지우기'), findsOneWidget);
    expect(find.byTooltip('금액 전체 지우기'), findsOneWidget);
  });

  test('buildSettlementShareText formats a Kakao-friendly summary', () {
    expect(
      buildSettlementShareText(
        amount: 12000,
        personCount: 3,
        perPerson: 4000,
        remainder: 0,
      ),
      '더치페이 계산 결과\n'
      '총 금액: 12,000원\n'
      '인원수: 3명\n'
      '1인당: 4,000원\n'
      '남는 돈: 없음',
    );
  });

  test(
    'buildSettlementShareText: 계좌가 있으면 입금 계좌 줄이 마지막에 붙고 trailing 개행이 없다',
    () {
      final text = buildSettlementShareText(
        amount: 30000,
        personCount: 2,
        perPerson: 15000,
        remainder: 0,
        account: '카카오뱅크 3333-01-1234567',
      );
      expect(
        text,
        '더치페이 계산 결과\n'
        '총 금액: 30,000원\n'
        '인원수: 2명\n'
        '1인당: 15,000원\n'
        '남는 돈: 없음\n'
        '입금 계좌: 카카오뱅크 3333-01-1234567',
      );
      // #9: 마지막 문자가 개행이 아니어야 한다(trailing 빈 줄 제거).
      expect(text.endsWith('\n'), isFalse);
    },
  );
}
