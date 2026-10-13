import 'package:flutter_test/flutter_test.dart';
import 'package:dutch_pay_calculator/ladder/ladder_round.dart';
import 'package:dutch_pay_calculator/ladder/ladder_setup.dart';

void main() {
  final carSetup = LadderSetup(
    players: const ['민수', '', '지영'],
    results: const [ResultSlot('14호차', 1), ResultSlot('12호차', 2)],
  );

  test('같은 seed 는 같은 배정을 만든다', () {
    final a = LadderRound.start(carSetup, 7);
    final b = LadderRound.start(carSetup, 7);
    expect(a.bottom, b.bottom);
    expect(a.ladder.rungs, b.ladder.rungs);
    expect(
      [for (var i = 0; i < 3; i++) a.resultFor(i)],
      [for (var i = 0; i < 3; i++) b.resultFor(i)],
    );
  });

  test('결과 라벨이 입력한 개수만큼 정확히 배정된다', () {
    for (var seed = 0; seed < 50; seed++) {
      final round = LadderRound.start(carSetup, seed);
      final assigned = [for (var i = 0; i < 3; i++) round.resultFor(i)]..sort();
      expect(assigned, ['12호차', '12호차', '14호차'], reason: 'seed=$seed');
    }
  });

  test('도착 칸에서 출발한 사람을 거꾸로 찾는다', () {
    final round = LadderRound.start(carSetup, 3);
    for (var player = 0; player < 3; player++) {
      expect(round.playerAt(round.ladder.endColumn(player)), player);
    }
  });

  test('결과 복사 글은 참가자 순서대로 「이름 → 결과」 줄이다', () {
    final round = LadderRound.start(carSetup, 11);
    final lines = round.summaryText.split('\n');
    expect(lines, hasLength(3));
    expect(lines[0], '민수 → ${round.resultFor(0)}');
    expect(lines[1], '2번 → ${round.resultFor(1)}');
    expect(lines[2], '지영 → ${round.resultFor(2)}');
  });

  test('결과 칸 순서도 섞어서 누구나 같은 확률로 받는다', () {
    // 사다리만으로는 2명 사다리가 가로줄 2~4개 짝수 편향으로 공정하지 않다.
    // 결과 칸 순서를 함께 섞으면 각 자리가 1/n 확률에 가까워야 한다.
    const trials = 3000;
    final duo = LadderSetup(
      players: const ['', ''],
      results: LadderSetup.winLose(2),
    );
    var duoWins = 0;
    var carWins = 0;
    for (var seed = 0; seed < trials; seed++) {
      if (LadderRound.start(duo, seed).resultFor(0) == '당첨') duoWins++;
      if (LadderRound.start(carSetup, seed).resultFor(0) == '14호차') carWins++;
    }
    expect(duoWins / trials, inInclusiveRange(0.46, 0.54));
    expect(carWins / trials, inInclusiveRange(0.30, 0.37));
  });

  test('탈 수 없는 설정은 거부한다', () {
    final broken = LadderSetup(
      players: const ['', '', ''],
      results: const [ResultSlot('당첨', 1)],
    );
    expect(() => LadderRound.start(broken, 0), throwsArgumentError);
  });
}
