import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dutch_pay_calculator/miniapps/roulette/roulette_controller.dart';

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

  test('처음 값 = 빈 항목 2개, 이름표 항목 1·항목 2', () async {
    final controller = await open();

    expect(controller.items, ['', '']);
    expect(controller.labels, ['항목 1', '항목 2']);
    expect(controller.spinning, isFalse);
    expect(controller.lastResult, isNull);
  });

  test('항목은 12개까지 늘고 2개 아래로 줄지 않는다', () async {
    final controller = await open();

    controller.removeItem(0);
    expect(controller.items, ['', '']);

    for (var i = 0; i < 20; i++) {
      controller.addItem();
    }
    expect(controller.items.length, RouletteController.maxItems);

    controller.removeItem(0);
    expect(controller.items.length, 11);
    while (controller.items.length > RouletteController.minItems) {
      controller.removeItem(0);
    }
    controller.removeItem(0);
    expect(controller.items.length, RouletteController.minItems);
  });

  test('이름은 공백을 빼고 10자까지', () async {
    final controller = await open();

    controller.renameItem(0, '  가나다라마바사아자차카  ');
    expect(controller.items[0], '가나다라마바사아자차');
    expect(controller.items[0].length, RouletteController.maxLength);

    controller.renameItem(1, '  민수  ');
    expect(controller.items[1], '민수');
    expect(controller.labels[1], '민수');
  });

  test('저장한 항목을 새 컨트롤러가 읽는다', () async {
    final first = await open();
    first.renameItem(0, '민수');
    first.addItem();
    first.renameItem(2, '지영');
    final saved = List<String>.from(first.items);

    final second = RouletteController(await SharedPreferences.getInstance());
    addTearDown(second.dispose);

    expect(second.items, saved);
    expect(second.labels, ['민수', '항목 2', '지영']);
    expect(second.lastResult, isNull);
  });

  test('깨진 저장값이면 처음 값', () async {
    Future<void> expectDefault(Object raw) async {
      final controller = await open(
        values: {RouletteController.storageKey: raw},
      );
      expect(controller.items, ['', '']);
      expect(controller.labels, ['항목 1', '항목 2']);
    }

    await expectDefault('{oops');
    await expectDefault(
      jsonEncode({
        'items': ['a'],
      }),
    );
    await expectDefault(jsonEncode({'items': List<String>.filled(13, '가')}));
  });

  test('돌리는 중 두 번째 startSpin 은 -1', () async {
    final controller = await open(random: Random(7));

    final first = controller.startSpin();
    expect(controller.spinning, isTrue);
    expect(first, inInclusiveRange(0, 1));
    expect(controller.startSpin(), -1);
    expect(controller.lastResult, isNull);

    controller.finishSpin();
    expect(controller.spinning, isFalse);
    expect(controller.lastResult, first);
  });

  test('결과 뒤 항목을 지우면 결과가 지워진다', () async {
    Future<RouletteController> spunAt(int winner) async {
      final controller = await open(random: _FixedRandom(winner));
      controller.renameItem(0, '민수');
      controller.renameItem(1, '지영');
      controller.addItem();
      controller.renameItem(2, '하늘');
      expect(controller.startSpin(), winner);
      controller.finishSpin();
      expect(controller.lastResult, winner);
      return controller;
    }

    final removedWinner = await spunAt(1);
    removedWinner.removeItem(1);
    expect(removedWinner.items, ['민수', '하늘']);
    expect(removedWinner.lastResult, isNull);

    final removedBefore = await spunAt(1);
    removedBefore.removeItem(0);
    expect(removedBefore.items, ['지영', '하늘']);
    expect(removedBefore.lastResult, isNull);
  });

  test('뽑기는 고르다', () async {
    final controller = await open(random: Random(42));
    controller.addItem();
    controller.addItem();
    expect(controller.items.length, 4);

    final counts = List<int>.filled(4, 0);
    for (var i = 0; i < 6000; i++) {
      final index = controller.startSpin();
      expect(index, inInclusiveRange(0, 3));
      counts[index] += 1;
      controller.finishSpin();
    }

    for (final count in counts) {
      expect(count, inInclusiveRange(1350, 1650));
    }
  });
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
