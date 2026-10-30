import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dutch_pay_calculator/widgets/toss_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('TossCountStepper: 최소에서 빼기·최대에서 더하기가 꺼지고 format 을 쓴다', (
    tester,
  ) async {
    var value = 2;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _wrap(
          TossCountStepper(
            id: 'x',
            value: value,
            min: 2,
            max: 3,
            format: (v) => '$v장',
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    expect(find.text('2장'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byKey(const ValueKey('minus-x'))).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('plus-x')));
    await tester.pump();
    expect(value, 3);
    expect(find.text('3장'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byKey(const ValueKey('plus-x'))).onPressed,
      isNull,
    );
  });

  testWidgets('TossCountStepper: format 이 없으면 ×값', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TossCountStepper(
          id: 'y',
          value: 1,
          min: 1,
          max: 5,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('×1'), findsOneWidget);
    expect(find.byKey(const ValueKey('count-y')), findsOneWidget);
  });

  testWidgets('TossNameField: maxLength 10 이면 11자째가 안 들어간다', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _wrap(
        TossNameField(
          fieldKey: const ValueKey('name'),
          controller: controller,
          hint: '이름',
          maxLength: 10,
          onChanged: (_) {},
        ),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('name')), '가나다라마바사아자차카');
    await tester.pump();
    expect(controller.text.length, 10);
  });

  testWidgets('TossBottomButton: onPressed 가 null 이면 버튼이 꺼진다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TossBottomButton(
          buttonKey: ValueKey('go'),
          label: '돌리기',
          onPressed: null,
        ),
      ),
    );

    final button = find.byKey(const ValueKey('go'));
    expect(button, findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(button).enabled, isFalse);
  });
}
