import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dutch_pay_calculator/miniapps/roulette/roulette_controller.dart';

/// 룰렛 목록 여러 벌 (T-261106-018).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<RouletteController> open({
    Map<String, Object> values = const {},
    Random? random,
  }) async {
    SharedPreferences.setMockInitialValues(values);
    final controller = RouletteController(
      await SharedPreferences.getInstance(),
      random: random,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<RouletteController> reopen() async {
    final controller = RouletteController(
      await SharedPreferences.getInstance(),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('처음 값 = 「목록 1」 하나, 빈 항목 2개', () async {
    final controller = await open();

    expect(controller.presetNames, ['목록 1']);
    expect(controller.currentPreset, 0);
    expect(controller.items, ['', '']);
    expect(controller.canAddPreset, isTrue);
    expect(controller.canRemovePreset, isFalse);
  });

  test('1.4.0 까지의 저장값(v1)은 「목록 1」로 가져온다', () async {
    final controller = await open(
      values: {
        RouletteController.legacyStorageKey: jsonEncode({
          'items': ['민수', '지영', ''],
        }),
      },
    );

    expect(controller.presetNames, ['목록 1']);
    expect(controller.items, ['민수', '지영', '']);
    expect(controller.labels, ['민수', '지영', '항목 3']);
  });

  test('새 목록은 빈 항목 2개로 열리고 바로 고른다, 5개까지', () async {
    final controller = await open();
    controller.renameItem(0, '민수');

    controller.addPreset();
    expect(controller.presetNames, ['목록 1', '목록 2']);
    expect(controller.currentPreset, 1);
    expect(controller.items, ['', '']);

    while (controller.canAddPreset) {
      controller.addPreset();
    }
    expect(controller.presetNames.length, RouletteController.maxPresets);
    controller.addPreset();
    expect(controller.presetNames.length, RouletteController.maxPresets);
    expect(controller.currentPreset, RouletteController.maxPresets - 1);
  });

  test('목록을 고르면 그 목록의 항목이 나온다', () async {
    final controller = await open();
    controller.renameItem(0, '민수');
    controller.renameItem(1, '지영');
    controller.addPreset();
    controller.renameItem(0, '햄버거');
    controller.addItem();
    controller.renameItem(2, '편의점');

    controller.selectPreset(0);
    expect(controller.currentPreset, 0);
    expect(controller.items, ['민수', '지영']);

    controller.selectPreset(1);
    expect(controller.items, ['햄버거', '', '편의점']);
    expect(controller.labels, ['햄버거', '항목 2', '편의점']);

    controller.selectPreset(7);
    controller.selectPreset(-1);
    expect(controller.currentPreset, 1);
  });

  test('목록을 바꾸면 결과 글자가 지워진다', () async {
    final controller = await open(random: Random(1));
    controller.addPreset();
    controller.selectPreset(0);
    controller.startSpin();
    controller.finishSpin();
    expect(controller.lastResult, isNotNull);

    controller.selectPreset(1);
    expect(controller.lastResult, isNull);

    controller.startSpin();
    controller.finishSpin();
    expect(controller.lastResult, isNotNull);
    controller.addPreset();
    expect(controller.lastResult, isNull);
  });

  test('이름은 공백을 빼고 8자까지, 비우면 안 쓴 「목록 n」', () async {
    final controller = await open();

    controller.renamePreset(0, '  점심  ');
    expect(controller.presetNames, ['점심']);

    controller.renamePreset(0, '가나다라마바사아자차');
    expect(controller.presetNames, ['가나다라마바사아']);

    controller.renamePreset(0, '가나다라마바사 아');
    expect(controller.presetNames, ['가나다라마바사']);

    controller.addPreset();
    expect(controller.presetNames, ['가나다라마바사', '목록 1']);

    controller.renamePreset(1, '   ');
    expect(controller.presetNames, ['가나다라마바사', '목록 1']);

    controller.renamePreset(0, '');
    expect(controller.presetNames, ['목록 2', '목록 1']);

    controller.renamePreset(5, '없는 자리');
    expect(controller.presetNames, ['목록 2', '목록 1']);
  });

  test('목록 지우기 — 하나 남으면 못 지우고, 고른 목록을 지우면 옆 목록', () async {
    final controller = await open();
    controller.removePreset(0);
    expect(controller.presetNames, ['목록 1']);

    controller.renameItem(0, '민수');
    controller.addPreset();
    controller.renameItem(0, '햄버거');
    controller.addPreset();
    controller.renameItem(0, '서울역');
    expect(controller.presetNames, ['목록 1', '목록 2', '목록 3']);
    expect(controller.currentPreset, 2);

    // 앞 목록을 지우면 고른 자리가 하나 당겨진다.
    controller.removePreset(0);
    expect(controller.presetNames, ['목록 2', '목록 3']);
    expect(controller.currentPreset, 1);
    expect(controller.items, ['서울역', '']);

    // 마지막에 있는 고른 목록을 지우면 그 앞 목록.
    controller.removePreset(1);
    expect(controller.presetNames, ['목록 2']);
    expect(controller.currentPreset, 0);
    expect(controller.items, ['햄버거', '']);

    controller.removePreset(0);
    expect(controller.presetNames, ['목록 2']);
    expect(controller.canRemovePreset, isFalse);

    // 빈 번호를 다시 쓴다.
    controller.addPreset();
    expect(controller.presetNames, ['목록 2', '목록 1']);
  });

  test('저장한 목록들을 새 컨트롤러가 읽는다', () async {
    final first = await open();
    first.renameItem(0, '민수');
    first.renameItem(1, '지영');
    first.renamePreset(0, '누가 쏠까');
    first.addPreset();
    first.renameItem(0, '햄버거');
    first.renameItem(1, '편의점');
    first.addItem();
    first.renameItem(2, '산해진미');
    first.renamePreset(1, '점심');

    final second = await reopen();
    expect(second.presetNames, ['누가 쏠까', '점심']);
    expect(second.currentPreset, 1);
    expect(second.items, ['햄버거', '편의점', '산해진미']);
    expect(second.lastResult, isNull);

    second.selectPreset(0);
    final third = await reopen();
    expect(third.currentPreset, 0);
    expect(third.items, ['민수', '지영']);
  });

  test('깨진 v2 저장값이면 v1, 그것도 없으면 처음 값', () async {
    Future<void> expectDefault(Object raw) async {
      final controller = await open(
        values: {RouletteController.storageKey: raw},
      );
      expect(controller.presetNames, ['목록 1']);
      expect(controller.items, ['', '']);
      expect(controller.currentPreset, 0);
    }

    await expectDefault('{oops');
    await expectDefault(jsonEncode({'presets': []}));
    await expectDefault(
      jsonEncode({
        'current': 0,
        'presets': [
          for (var i = 0; i < 6; i++)
            {
              'name': '목록 ${i + 1}',
              'items': ['', ''],
            },
        ],
      }),
    );
    await expectDefault(
      jsonEncode({
        'current': 0,
        'presets': [
          {
            'name': '아홉글자아홉글자아',
            'items': ['', ''],
          },
        ],
      }),
    );
    await expectDefault(
      jsonEncode({
        'current': 0,
        'presets': [
          {
            'name': '점심',
            'items': ['하나'],
          },
        ],
      }),
    );

    final fallback = await open(
      values: {
        RouletteController.storageKey: '{oops',
        RouletteController.legacyStorageKey: jsonEncode({
          'items': ['민수', '지영'],
        }),
      },
    );
    expect(fallback.presetNames, ['목록 1']);
    expect(fallback.items, ['민수', '지영']);

    final badCurrent = await open(
      values: {
        RouletteController.storageKey: jsonEncode({
          'current': 9,
          'presets': [
            {
              'name': '점심',
              'items': ['햄버거', '편의점'],
            },
          ],
        }),
      },
    );
    expect(badCurrent.presetNames, ['점심']);
    expect(badCurrent.currentPreset, 0);
    expect(badCurrent.items, ['햄버거', '편의점']);
  });

  test('돌리는 중엔 목록을 못 바꾼다', () async {
    final controller = await open(random: Random(3));
    controller.addPreset();
    controller.renamePreset(1, '점심');
    expect(controller.startSpin(), inInclusiveRange(0, 1));

    controller.selectPreset(0);
    controller.addPreset();
    controller.renamePreset(1, '저녁');
    controller.removePreset(0);
    expect(controller.currentPreset, 1);
    expect(controller.presetNames, ['목록 1', '점심']);
    expect(controller.canAddPreset, isFalse);
    expect(controller.canRemovePreset, isFalse);

    controller.finishSpin();
    expect(controller.canAddPreset, isTrue);
    expect(controller.canRemovePreset, isTrue);
  });
}
