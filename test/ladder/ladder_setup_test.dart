import 'package:flutter_test/flutter_test.dart';
import 'package:dutch_pay_calculator/ladder/ladder_setup.dart';

void main() {
  test('처음 상태는 3명·당첨 1·꽝 2 라서 바로 탈 수 있다', () {
    final setup = LadderSetup.initial();
    expect(setup.players, ['', '', '']);
    expect(setup.results, const [ResultSlot('당첨', 1), ResultSlot('꽝', 2)]);
    expect(setup.remaining, 0);
    expect(setup.canStart, isTrue);
  });

  test('빈 이름은 1번·2번… 으로, 빈 결과는 결과 1·결과 2… 로 채운다', () {
    final setup = LadderSetup(
      players: const ['', ' 민수 ', ''],
      results: const [ResultSlot('', 1), ResultSlot('12호차', 2)],
    );
    expect(setup.playerNames, ['1번', '민수', '3번']);
    expect(setup.resultLabels, ['결과 1', '12호차']);
  });

  test('결과 개수를 펼치면 라벨이 개수만큼 나온다', () {
    final setup = LadderSetup(
      players: const ['', '', ''],
      results: const [ResultSlot('14호차', 1), ResultSlot('12호차', 2)],
    );
    expect(setup.expandedResults, ['14호차', '12호차', '12호차']);
  });

  test('개수 합계가 참가자 수와 다르면 남은 자리를 알려 주고 막는다', () {
    final short = LadderSetup(
      players: const ['', '', '', ''],
      results: const [ResultSlot('당첨', 1), ResultSlot('꽝', 2)],
    );
    expect(short.remaining, 1);
    expect(short.canStart, isFalse);

    final over = LadderSetup(
      players: const ['', ''],
      results: const [ResultSlot('당첨', 1), ResultSlot('꽝', 2)],
    );
    expect(over.remaining, -1);
    expect(over.canStart, isFalse);
  });

  test('참가자는 2~12명일 때만 탈 수 있다', () {
    LadderSetup withPlayers(int n) => LadderSetup(
      players: List.filled(n, ''),
      results: [ResultSlot('결과', n)],
    );
    expect(withPlayers(1).canStart, isFalse);
    expect(withPlayers(2).canStart, isTrue);
    expect(withPlayers(12).canStart, isTrue);
    expect(withPlayers(13).canStart, isFalse);
  });

  test('빠른 채우기 3종은 참가자 수만큼 자리를 만든다', () {
    expect(LadderSetup.winLose(4), const [
      ResultSlot('당첨', 1),
      ResultSlot('꽝', 3),
    ]);
    expect(LadderSetup.ranks(3), const [
      ResultSlot('1등', 1),
      ResultSlot('2등', 1),
      ResultSlot('3등', 1),
    ]);
    expect(LadderSetup.order(3), const [
      ResultSlot('1번째', 1),
      ResultSlot('2번째', 1),
      ResultSlot('3번째', 1),
    ]);
  });

  test('JSON 으로 저장했다가 그대로 되살린다', () {
    final setup = LadderSetup(
      players: const ['민수', '', '지영'],
      results: const [ResultSlot('14호차', 1), ResultSlot('12호차', 2)],
    );
    final restored = LadderSetup.fromJson(setup.toJson());
    expect(restored, isNotNull);
    expect(restored!.players, setup.players);
    expect(restored.results, setup.results);
  });

  test('망가진 저장값은 null 로 돌려준다', () {
    expect(LadderSetup.fromJson(null), isNull);
    expect(LadderSetup.fromJson('문자열'), isNull);
    expect(LadderSetup.fromJson({'players': 3, 'results': []}), isNull);
    expect(
      LadderSetup.fromJson({
        'players': ['', ''],
        'results': [
          {'label': '꽝', 'count': 0},
        ],
      }),
      isNull,
    );
    expect(
      LadderSetup.fromJson({
        'players': List.filled(13, ''),
        'results': [
          {'label': '꽝', 'count': 13},
        ],
      }),
      isNull,
    );
  });
}
