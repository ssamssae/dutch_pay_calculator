import 'package:dutch_pay_calculator/miniapps/calculator/basic_calculator_screen.dart';
import 'package:dutch_pay_calculator/miniapps/calculator/calculator_controller.dart';
import 'package:dutch_pay_calculator/services/ads_service.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/layout_devices.dart';

Widget _app(BasicCalculatorController controller) {
  return MaterialApp(
    theme: AppTheme.light,
    debugShowCheckedModeBanner: false,
    home: BasicCalculatorScreen(controller: controller),
  );
}

void main() {
  setUp(mockAdsChannel);

  testWidgets('키를 누르면 식과 결과가 보인다', (tester) async {
    final controller = BasicCalculatorController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));

    await tester.tap(find.byKey(const ValueKey('calc-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('calc-+')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('calc-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('calc-=')));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('calc-display'))).data,
      '3',
    );
    expect(find.byKey(const ValueKey('calc-expression')), findsOneWidget);
  });

  testWidgets('키를 누르면 lightImpact 진동 1번', (tester) async {
    final log = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      log.add(call);
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final controller = BasicCalculatorController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));

    await tester.tap(find.byKey(const ValueKey('calc-1')));
    await tester.pump();

    final haptics = log.where(
      (call) =>
          call.method == 'HapticFeedback.vibrate' &&
          call.arguments == 'HapticFeedbackType.lightImpact',
    );
    expect(haptics, hasLength(1));
  });

  testWidgets('배너는 키패드 위에 있다', (tester) async {
    final controller = BasicCalculatorController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pump();

    expect(
      tester.getRect(find.byType(AdaptiveBanner)).bottom,
      lessThanOrEqualTo(
        tester.getRect(find.byKey(const ValueKey('calc-AC'))).top,
      ),
    );
  });

  testWidgets('지우기 키에 한 자리 지우기 이름표가 있다', (tester) async {
    final controller = BasicCalculatorController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));

    expect(find.byTooltip('한 자리 지우기'), findsOneWidget);
    expect(find.byKey(const ValueKey('calc-⌫')), findsOneWidget);
  });

  testWidgets('긴 식은 결과 글자 높이를 줄이지 않는다', (tester) async {
    final controller = BasicCalculatorController();
    addTearDown(controller.dispose);
    final device = kLayoutDevices.firstWhere((d) => d.name == 'iPhone SE 세로');
    await pumpOnDevice(tester, device, _app(controller));

    void press1234Plus() {
      for (final key in ['1', '2', '3', '4', '+']) {
        controller.press(key);
      }
    }

    press1234Plus();
    await tester.pump();
    final shortHeight = tester
        .getRect(find.byKey(const ValueKey('calc-display')))
        .height;

    for (var i = 0; i < 9; i++) {
      press1234Plus();
    }
    await tester.pump();
    final expression = tester
        .widget<Text>(find.byKey(const ValueKey('calc-expression')))
        .data!;
    final longHeight = tester
        .getRect(find.byKey(const ValueKey('calc-display')))
        .height;

    expect(expression.length, greaterThanOrEqualTo(70));
    expect(shortHeight, greaterThan(40));
    expect(
      longHeight,
      shortHeight,
      reason: 'short=$shortHeight long=$longHeight expr=${expression.length}',
    );
  });

  for (final device in kLayoutDevices) {
    testWidgets('넘치지 않는다 ${device.name}', (tester) async {
      final controller = BasicCalculatorController();
      addTearDown(controller.dispose);
      await pumpOnDevice(tester, device, _app(controller));
      expect(find.text('계산기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
