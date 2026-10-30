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
