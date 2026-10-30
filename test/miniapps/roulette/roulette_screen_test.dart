import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dutch_pay_calculator/miniapps/roulette/roulette_controller.dart';
import 'package:dutch_pay_calculator/miniapps/roulette/roulette_screen.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';

import '../../support/layout_devices.dart';

void main() {
  setUp(() {
    mockAdsChannel();
    SharedPreferences.setMockInitialValues({});
  });

  Future<RouletteController> openController({Random? random}) async {
    final controller = RouletteController(
      await SharedPreferences.getInstance(),
      random: random,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    RouletteController controller,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RouletteScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('돌리기 → 3.5초 뒤 결과 = 뽑힌 이름', (tester) async {
    const seed = 42;
    final controller = await openController(random: Random(seed));
    controller.renameItem(0, '민수');
    controller.renameItem(1, '지영');
    controller.addItem();
    controller.renameItem(2, '하늘');
    final expectedIndex = Random(seed).nextInt(controller.items.length);
    final expected = controller.labels[expectedIndex];

    await pumpScreen(tester, controller);
    expect(find.text('룰렛'), findsOneWidget);
    expect(find.text('누가 쏠지 돌려서 정해요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('spin')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(const ValueKey('spin')))
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('roulette-item-0')))
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('roulette-item-2')))
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('roulette-add')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('roulette-remove-0')))
          .onPressed,
      isNull,
    );
    expect(find.byKey(const ValueKey('roulette-result')), findsNothing);

    // AnimationController 는 재생 시간이 지난 다음 순간에 끝난다.
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 1));

    expect(controller.spinning, isFalse);
    expect(controller.lastResult, expectedIndex);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('roulette-result'))).data,
      expected,
    );
    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(const ValueKey('spin')))
          .enabled,
      isTrue,
    );
  });

  testWidgets('돌리기 연타는 한 번만 돈다', (tester) async {
    const seed = 42;
    final controller = await openController(random: Random(seed));
    controller.renameItem(0, '민수');
    controller.renameItem(1, '지영');
    final expectedIndex = Random(seed).nextInt(controller.items.length);

    await pumpScreen(tester, controller);
    await tester.tap(find.byKey(const ValueKey('spin')));
    await tester.tap(find.byKey(const ValueKey('spin')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pump(const Duration(milliseconds: 1));

    expect(controller.spinning, isFalse);
    expect(controller.lastResult, expectedIndex);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('roulette-result'))).data,
      controller.labels[expectedIndex],
    );
  });

  testWidgets('결과 뒤 지우기 → 결과 글자 없음', (tester) async {
    final controller = await openController(random: _FixedRandom(1));
    controller.renameItem(0, '민수');
    controller.renameItem(1, '지영');
    controller.addItem();
    controller.renameItem(2, '하늘');

    await pumpScreen(tester, controller);
    await tester.tap(find.byKey(const ValueKey('spin')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pump(const Duration(milliseconds: 1));

    expect(controller.lastResult, 1);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('roulette-result'))).data,
      '지영',
    );

    await tester.tap(find.byKey(const ValueKey('roulette-remove-1')));
    await tester.pump();

    expect(find.byKey(const ValueKey('roulette-result')), findsNothing);
  });

  testWidgets('나갔다 와도 항목과 결과가 남는다', (tester) async {
    const seed = 3;
    final controller = await openController(random: Random(seed));
    controller.renameItem(0, '민수');
    controller.renameItem(1, '지영');
    final expected = controller.labels[Random(seed).nextInt(2)];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RouletteScreen(controller: controller),
                    ),
                  );
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('spin')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('roulette-result'))).data,
      expected,
    );

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('열기'), findsOneWidget);

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('roulette-item-0')))
          .controller
          ?.text,
      '민수',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('roulette-item-1')))
          .controller
          ?.text,
      '지영',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('roulette-result'))).data,
      expected,
    );
  });

  for (final device in kLayoutDevices) {
    testWidgets('항목 12개 넘치지 않는다 ${device.name}', (tester) async {
      final controller = await openController();
      while (controller.items.length < RouletteController.maxItems) {
        controller.addItem();
      }
      for (var i = 0; i < controller.items.length; i++) {
        controller.renameItem(i, '가나다라마바사아자차');
      }

      await pumpOnDevice(
        tester,
        device,
        MaterialApp(
          theme: AppTheme.light,
          home: RouletteScreen(controller: controller),
        ),
      );

      expect(find.text('룰렛'), findsOneWidget);
      expect(find.text('누가 쏠지 돌려서 정해요'), findsOneWidget);
      expect(find.byKey(const ValueKey('roulette-item-11')), findsOneWidget);
      expect(find.byKey(const ValueKey('spin')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

/// [nextInt] 가 항상 [value] 를 반환한다. 당첨 칸을 테스트에서 고정할 때 쓴다.
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final int value;

  @override
  int nextInt(int max) {
    if (value < 0 || value >= max) {
      throw RangeError.range(value, 0, max - 1, 'value');
    }
    return value;
  }

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
