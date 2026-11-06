import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dutch_pay_calculator/miniapps/roulette/roulette_controller.dart';
import 'package:dutch_pay_calculator/miniapps/roulette/roulette_screen.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';

import '../../support/layout_devices.dart';

/// 룰렛 목록 카드 — 칩·새 목록·이름 바꾸기·지우기 (T-261106-018).
void main() {
  setUp(() {
    mockAdsChannel();
    SharedPreferences.setMockInitialValues({});
  });

  Future<RouletteController> openController() async {
    final controller = RouletteController(
      await SharedPreferences.getInstance(),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    RouletteController controller,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RouletteScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  String itemText(WidgetTester tester, int index) => tester
      .widget<TextField>(find.byKey(ValueKey('roulette-item-$index')))
      .controller!
      .text;

  testWidgets('새 목록을 열면 빈 항목, 칩을 누르면 그 목록의 항목', (tester) async {
    final controller = await openController();
    controller.renameItem(0, '민수');
    controller.renameItem(1, '지영');

    await pumpScreen(tester, controller);
    expect(find.text('목록'), findsOneWidget);
    expect(find.byKey(const ValueKey('roulette-preset-0')), findsOneWidget);
    expect(find.text('목록 1'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('roulette-preset-0')))
          .selected,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('roulette-preset-add')));
    await tester.pumpAndSettle();

    expect(controller.presetNames, ['목록 1', '목록 2']);
    expect(find.text('목록 2'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('roulette-preset-1')))
          .selected,
      isTrue,
    );
    expect(itemText(tester, 0), '');
    expect(itemText(tester, 1), '');

    await tester.enterText(
      find.byKey(const ValueKey('roulette-item-0')),
      '햄버거',
    );
    await tester.pump();
    expect(controller.items, ['햄버거', '']);

    await tester.tap(find.byKey(const ValueKey('roulette-preset-0')));
    await tester.pumpAndSettle();

    expect(controller.currentPreset, 0);
    expect(itemText(tester, 0), '민수');
    expect(itemText(tester, 1), '지영');

    await tester.tap(find.byKey(const ValueKey('roulette-preset-1')));
    await tester.pumpAndSettle();
    expect(itemText(tester, 0), '햄버거');
  });

  testWidgets('5개가 되면 새 목록 단추가 꺼진다', (tester) async {
    final controller = await openController();
    await pumpScreen(tester, controller);

    for (var i = 1; i < RouletteController.maxPresets; i++) {
      await tester.tap(find.byKey(const ValueKey('roulette-preset-add')));
      await tester.pumpAndSettle();
    }
    expect(controller.presetNames.length, RouletteController.maxPresets);
    expect(find.byKey(const ValueKey('roulette-preset-4')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('roulette-preset-add')))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('이름 바꾸기 창 → 저장하면 칩 글자가 바뀐다', (tester) async {
    final controller = await openController();
    await pumpScreen(tester, controller);

    await tester.tap(find.byKey(const ValueKey('roulette-preset-rename')));
    await tester.pumpAndSettle();
    expect(find.text('목록 이름'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('roulette-preset-name')))
          .controller
          ?.text,
      '목록 1',
    );

    await tester.enterText(
      find.byKey(const ValueKey('roulette-preset-name')),
      '  점심  ',
    );
    await tester.tap(find.byKey(const ValueKey('roulette-preset-name-save')));
    await tester.pumpAndSettle();

    expect(find.text('목록 이름'), findsNothing);
    expect(controller.presetNames, ['점심']);
    expect(find.text('점심'), findsOneWidget);
    expect(find.text('목록 1'), findsNothing);

    // 취소하면 그대로.
    await tester.tap(find.byKey(const ValueKey('roulette-preset-rename')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('roulette-preset-name')),
      '저녁',
    );
    await tester.tap(find.byKey(const ValueKey('roulette-preset-name-cancel')));
    await tester.pumpAndSettle();
    expect(controller.presetNames, ['점심']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('목록 지우기 — 하나면 단추 꺼짐, 둘이면 확인 뒤 지운다', (tester) async {
    final controller = await openController();
    controller.renameItem(0, '민수');
    await pumpScreen(tester, controller);

    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('roulette-preset-remove')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('roulette-preset-add')));
    await tester.pumpAndSettle();
    expect(controller.currentPreset, 1);

    await tester.tap(find.byKey(const ValueKey('roulette-preset-remove')));
    await tester.pumpAndSettle();
    expect(find.text('목록 지우기'), findsOneWidget);
    expect(find.textContaining('「목록 2」'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('roulette-preset-remove-cancel')),
    );
    await tester.pumpAndSettle();
    expect(controller.presetNames, ['목록 1', '목록 2']);

    await tester.tap(find.byKey(const ValueKey('roulette-preset-remove')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('roulette-preset-remove-confirm')),
    );
    await tester.pumpAndSettle();

    expect(controller.presetNames, ['목록 1']);
    expect(controller.currentPreset, 0);
    expect(itemText(tester, 0), '민수');
    expect(find.byKey(const ValueKey('roulette-preset-1')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('돌리는 동안은 목록 단추와 칩이 꺼진다', (tester) async {
    final controller = await openController();
    controller.addPreset();
    await pumpScreen(tester, controller);

    await tester.tap(find.byKey(const ValueKey('spin')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    for (final key in const [
      'roulette-preset-rename',
      'roulette-preset-remove',
      'roulette-preset-add',
    ]) {
      expect(
        tester.widget<IconButton>(find.byKey(ValueKey(key))).onPressed,
        isNull,
        reason: key,
      );
    }
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('roulette-preset-0')))
          .onSelected,
      isNull,
    );

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 1));
    expect(controller.spinning, isFalse);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('roulette-preset-0')))
          .onSelected,
      isNotNull,
    );
  });

  for (final device in kLayoutDevices) {
    testWidgets('목록 5개·항목 12개 넘치지 않는다 ${device.name}', (tester) async {
      final controller = await openController();
      while (controller.canAddPreset) {
        controller.addPreset();
        controller.renamePreset(controller.currentPreset, '가나다라마바사아');
      }
      while (controller.items.length < RouletteController.maxItems) {
        controller.addItem();
      }

      await pumpOnDevice(
        tester,
        device,
        MaterialApp(
          theme: AppTheme.light,
          home: RouletteScreen(controller: controller),
        ),
      );

      expect(find.byKey(const ValueKey('roulette-preset-4')), findsOneWidget);
      expect(find.byKey(const ValueKey('spin')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
