import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dutch_pay_calculator/miniapps/lottery/lottery_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LotteryController> open({
    Map<String, Object> values = const {},
    Random? random,
  }) async {
    SharedPreferences.setMockInitialValues(values);
    final controller = LotteryController(
      await SharedPreferences.getInstance(),
      random: random,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('처음 값 4장·당첨 1장·판 없음', () async {
    final controller = await open();

    expect(controller.total, 4);
    expect(controller.winners, 1);
    expect(controller.board, isNull);
    expect(controller.revealed, isEmpty);
    expect(controller.remaining, 4);
    expect(controller.remainingWinners, 1);
    expect(controller.reveal(0), isNull);
    expect(LotteryController.storageKey, 'miniapp_lottery_v1');
    expect(LotteryController.minTotal, 2);
    expect(LotteryController.maxTotal, 20);
  });

  test('전체를 줄이면 당첨이 따라 준다', () async {
    final controller = await open();

    controller.setWinners(3);
    expect(controller.winners, 3);

    controller.setTotal(3);
    expect(controller.total, 3);
    expect(controller.winners, 2);
  });

  test('범위로 잘린다', () async {
    final controller = await open();

    controller.setTotal(1);
    expect(controller.total, 2);

    controller.setTotal(21);
    expect(controller.total, 20);

    controller.setWinners(0);
    expect(controller.winners, 1);

    controller.setWinners(100);
    expect(controller.winners, 19);
  });

  test('섞으면 당첨이 정확히 winners 장', () async {
    final controller = await open();

    controller.setTotal(20);
    controller.setWinners(7);
    controller.shuffle();

    final board = controller.board;
    expect(board, isNotNull);
    expect(board, hasLength(20));
    expect(board!.where((ticket) => ticket).length, 7);
    expect(controller.revealed, isEmpty);
    expect(controller.remaining, 20);
    expect(controller.remainingWinners, 7);

    controller.reveal(0);
    controller.shuffle();
    expect(controller.revealed, isEmpty);
    expect(controller.board!.where((ticket) => ticket).length, 7);
    expect(controller.remaining, 20);
    expect(controller.remainingWinners, 7);
  });

  test('reveal 은 한 번 뒤집으면 그대로', () async {
    final controller = await open();
    controller.shuffle();

    final first = controller.reveal(2);
    final second = controller.reveal(2);

    expect(first, isNotNull);
    expect(second, first);
    expect(first, controller.board![2]);
    expect(controller.revealed, {2});
    expect(controller.remaining, controller.total - 1);
    expect(
      controller.remainingWinners,
      first! ? controller.winners - 1 : controller.winners,
    );

    expect(controller.reveal(-1), isNull);
    expect(controller.reveal(99), isNull);
    expect(controller.revealed, {2});
  });

  test('설정을 바꾸면 판이 사라진다', () async {
    final controller = await open();
    controller.setTotal(8);
    controller.setWinners(3);
    controller.shuffle();
    controller.reveal(1);
    expect(controller.board, isNotNull);
    expect(controller.revealed, {1});

    controller.setWinners(2);
    expect(controller.winners, 2);
    expect(controller.board, isNull);
    expect(controller.revealed, isEmpty);
    expect(controller.remaining, 8);
    expect(controller.remainingWinners, 2);

    controller.shuffle();
    controller.setTotal(5);
    expect(controller.total, 5);
    expect(controller.winners, 2);
    expect(controller.board, isNull);
    expect(controller.revealed, isEmpty);

    final again = LotteryController(await SharedPreferences.getInstance());
    addTearDown(again.dispose);
    expect(again.total, 5);
    expect(again.winners, 2);
    expect(again.board, isNull);
  });

  test('깨진 저장값이면 처음 값', () async {
    Future<void> expectDefault(Object raw) async {
      final controller = await open(
        values: {LotteryController.storageKey: raw},
      );
      expect(controller.total, 4);
      expect(controller.winners, 1);
      expect(controller.board, isNull);
      expect(controller.revealed, isEmpty);
    }

    await expectDefault(jsonEncode({'total': 1, 'winners': 1}));
    await expectDefault(jsonEncode({'total': 4, 'winners': 4}));
    await expectDefault('{oops');
  });

  test('당첨 자리는 고르다', () async {
    final controller = await open(random: Random(7));
    expect(controller.total, 4);
    expect(controller.winners, 1);

    final counts = List<int>.filled(4, 0);
    for (var i = 0; i < 4000; i++) {
      controller.shuffle();
      final board = controller.board!;
      expect(board.where((ticket) => ticket).length, 1);
      counts[board.indexOf(true)] += 1;
    }

    for (final count in counts) {
      expect(count, inInclusiveRange(900, 1100));
    }
  });
}
