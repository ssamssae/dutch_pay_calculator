import 'package:flutter_test/flutter_test.dart';

import 'package:dutch_pay_calculator/miniapps/roulette/roulette_wheel.dart';

void main() {
  test('targetTurns 로 멈추면 화살표가 그 칸을 가리킨다', () {
    const currentTurns = 0.37;
    for (var count = 2; count <= 12; count++) {
      for (var index = 0; index < count; index++) {
        final turns = RouletteWheel.targetTurns(
          currentTurns: currentTurns,
          index: index,
          count: count,
        );
        expect(
          RouletteWheel.indexAtPointer(turns, count),
          index,
          reason: 'count=$count index=$index turns=$turns',
        );
      }
    }
  });

  test('targetTurns 는 4바퀴 이상 더 돈다', () {
    const currents = [0.0, 0.37, 5.9];
    for (final currentTurns in currents) {
      for (var count = 2; count <= 12; count++) {
        for (var index = 0; index < count; index++) {
          final turns = RouletteWheel.targetTurns(
            currentTurns: currentTurns,
            index: index,
            count: count,
          );
          expect(turns, greaterThanOrEqualTo(currentTurns + 4));
          expect(
            RouletteWheel.indexAtPointer(turns, count),
            index,
            reason: 'current=$currentTurns count=$count index=$index',
          );
        }
      }
    }
  });
}
