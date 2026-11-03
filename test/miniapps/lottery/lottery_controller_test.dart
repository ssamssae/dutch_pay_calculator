import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dutch_pay_calculator/ladder/ladder_setup.dart';
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

  test('당첨·꽝 판의 제비 글 = 당첨·꽝', () async {
    final controller = await open(random: Random(3));
    controller.setTotal(6);
    controller.setWinners(2);
    controller.shuffle();

    final board = controller.board!;
    final faces = controller.faces!;
    expect(faces, hasLength(6));
    for (var i = 0; i < 6; i++) {
      expect(faces[i], board[i] ? '당첨' : '꽝');
    }
  });

  test('직접 쓰기 처음 값 = 빈 두 줄 한 장씩, 방식은 당첨·꽝', () async {
    final controller = await open();

    expect(controller.mode, LotteryMode.winLose);
    expect(controller.items, const [ResultSlot('', 1), ResultSlot('', 1)]);
    expect(controller.itemTotal, 2);
    expect(controller.itemLabels, ['결과 1', '결과 2']);
    expect(LotteryController.maxLabelLength, 10);
  });

  test('직접 쓰기 섞기 = 적은 결과가 장수만큼 섞인다', () async {
    final controller = await open(random: Random(11));
    controller.setMode(LotteryMode.custom);
    controller.renameItem(0, '12호차');
    controller.renameItem(1, '14호차');
    controller.setItemCount(1, 2);

    expect(controller.ticketCount, 3);
    expect(controller.remaining, 3);
    controller.shuffle();

    final faces = controller.faces!;
    expect(List.of(faces)..sort(), ['12호차', '14호차', '14호차']);
    expect(controller.board, [true, true, true]);
    expect(controller.revealed, isEmpty);

    final index = faces.indexOf('12호차');
    expect(controller.reveal(index), isTrue);
    expect(controller.revealed, {index});
    expect(controller.remaining, 2);
  });

  test('빈 칸은 결과 번호, 꽝 제비만 축하하지 않는다', () async {
    final controller = await open(random: Random(5));
    controller.setMode(LotteryMode.custom);
    controller.renameItem(0, '   ');
    controller.addItem();
    controller.renameItem(2, '꽝');
    controller.shuffle();

    final faces = controller.faces!;
    expect(List.of(faces)..sort(), ['결과 1', '결과 2', '꽝']..sort());
    final board = controller.board!;
    for (var i = 0; i < faces.length; i++) {
      expect(board[i], faces[i] != '꽝');
    }
  });

  test('글은 10자까지, 앞뒤 공백은 제비에서만 뺀다', () async {
    final controller = await open();
    controller.setMode(LotteryMode.custom);

    controller.renameItem(0, '가나다라마바사아자차카타');
    expect(controller.items[0].label, '가나다라마바사아자차');

    controller.renameItem(1, ' 14호차 ');
    expect(controller.items[1].label, ' 14호차 ');
    expect(controller.itemLabels[1], '14호차');
  });

  test('장수 합계는 20장까지, 마지막 한 줄은 남는다', () async {
    final controller = await open();
    controller.setMode(LotteryMode.custom);

    controller.setItemCount(0, 30);
    expect(controller.items[0].count, 19);
    expect(controller.itemTotal, 20);
    expect(controller.maxCountFor(1), 1);

    controller.addItem();
    expect(controller.items, hasLength(2));

    controller.setItemCount(0, 0);
    expect(controller.items[0].count, 1);

    controller.removeItem(1);
    controller.removeItem(0);
    expect(controller.items, hasLength(1));
    expect(controller.itemTotal, 1);
    expect(controller.canShuffle, isFalse);

    controller.shuffle();
    expect(controller.board, isNull);
    expect(controller.faces, isNull);
  });

  test('직접 쓰기 설정을 바꾸면 판이 사라진다', () async {
    final controller = await open();
    controller.setMode(LotteryMode.custom);

    controller.shuffle();
    controller.reveal(0);
    controller.renameItem(0, '12호차');
    expect(controller.board, isNull);
    expect(controller.faces, isNull);
    expect(controller.revealed, isEmpty);

    controller.shuffle();
    controller.setItemCount(0, 2);
    expect(controller.board, isNull);

    controller.shuffle();
    controller.addItem();
    expect(controller.board, isNull);

    controller.shuffle();
    controller.removeItem(2);
    expect(controller.board, isNull);

    controller.shuffle();
    controller.setMode(LotteryMode.winLose);
    expect(controller.board, isNull);
    expect(controller.faces, isNull);
  });

  test('방식과 직접 쓴 결과는 저장되고 다시 열면 그대로', () async {
    final controller = await open();
    controller.setMode(LotteryMode.custom);
    controller.renameItem(0, '12호차');
    controller.renameItem(1, '14호차');
    controller.setItemCount(1, 3);
    controller.shuffle();

    final again = LotteryController(await SharedPreferences.getInstance());
    addTearDown(again.dispose);
    expect(again.mode, LotteryMode.custom);
    expect(again.items, const [ResultSlot('12호차', 1), ResultSlot('14호차', 3)]);
    expect(again.board, isNull);
    expect(again.total, 4);
    expect(again.winners, 1);
  });

  test('옛 저장값(방식·결과 없음)은 당첨·꽝 그대로 읽는다', () async {
    final controller = await open(
      values: {
        LotteryController.storageKey: jsonEncode({'total': 6, 'winners': 2}),
      },
    );

    expect(controller.mode, LotteryMode.winLose);
    expect(controller.total, 6);
    expect(controller.winners, 2);
    expect(controller.items, const [ResultSlot('', 1), ResultSlot('', 1)]);
  });

  test('결과 저장값이 깨졌으면 결과만 처음 값', () async {
    Future<void> expectDefaultItems(Object items, {Object? mode}) async {
      final controller = await open(
        values: {
          LotteryController.storageKey: jsonEncode({
            'total': 5,
            'winners': 2,
            'mode': mode ?? 'custom',
            'items': items,
          }),
        },
      );
      expect(controller.total, 5);
      expect(controller.winners, 2);
      expect(controller.items, const [ResultSlot('', 1), ResultSlot('', 1)]);
    }

    await expectDefaultItems([
      {'label': 'a', 'count': 0},
    ]);
    await expectDefaultItems([
      {'label': 'a', 'count': 15},
      {'label': 'b', 'count': 6},
    ]);
    await expectDefaultItems([
      {'label': '가나다라마바사아자차카', 'count': 1},
    ]);
    await expectDefaultItems([]);
    await expectDefaultItems('oops');

    final unknown = await open(
      values: {
        LotteryController.storageKey: jsonEncode({
          'total': 5,
          'winners': 2,
          'mode': 'xyz',
        }),
      },
    );
    expect(unknown.mode, LotteryMode.winLose);
  });
}
