import 'package:flutter_test/flutter_test.dart';
import 'package:dutch_pay_calculator/ladder/ladder.dart';

void main() {
  const seeds = [0, 1, 2, 3, 7, 42, 99, 2026, 123456, 987654321];
  const rows = 12;

  group('generate', () {
    test('출발 N개가 도착 N개로 겹치지 않게 이어진다(전단사)', () {
      for (var columns = 2; columns <= 12; columns++) {
        for (final seed in seeds) {
          final ladder = Ladder.generate(columns, rows, seed);
          final ends = [for (var s = 0; s < columns; s++) ladder.endColumn(s)];
          expect(ends.toSet(), {
            for (var c = 0; c < columns; c++) c,
          }, reason: 'columns=$columns seed=$seed ends=$ends');
        }
      }
    });

    test('같은 행에 이웃한 가로줄이 붙지 않는다', () {
      for (var columns = 3; columns <= 12; columns++) {
        for (final seed in seeds) {
          final ladder = Ladder.generate(columns, rows, seed);
          for (var r = 0; r < ladder.rows; r++) {
            for (var p = 0; p + 1 < columns - 1; p++) {
              expect(
                ladder.rungs[r][p] && ladder.rungs[r][p + 1],
                isFalse,
                reason: 'columns=$columns seed=$seed row=$r pair=$p',
              );
            }
          }
        }
      }
    });

    test('이웃한 세로줄 쌍마다 가로줄이 2~4개다', () {
      for (var columns = 2; columns <= 12; columns++) {
        for (final seed in seeds) {
          final ladder = Ladder.generate(columns, rows, seed);
          for (var p = 0; p < columns - 1; p++) {
            expect(
              ladder.rungCount(p),
              inInclusiveRange(2, 4),
              reason: 'columns=$columns seed=$seed pair=$p',
            );
          }
        }
      }
    });

    test('같은 seed 는 같은 사다리를 만든다', () {
      final a = Ladder.generate(6, rows, 42);
      final b = Ladder.generate(6, rows, 42);
      expect(a.rungs, b.rungs);

      final others = [
        for (var seed = 43; seed < 53; seed++) Ladder.generate(6, rows, seed),
      ];
      expect(
        others.any((o) => !_sameRungs(o.rungs, a.rungs)),
        isTrue,
        reason: 'seed 가 바뀌면 적어도 한 번은 다른 사다리가 나와야 한다',
      );
    });

    test('세로줄 2개 미만이나 행이 모자라면 거부한다', () {
      expect(() => Ladder.generate(1, rows, 0), throwsArgumentError);
      expect(
        () => Ladder.generate(4, Ladder.minRows - 1, 0),
        throwsArgumentError,
      );
    });
  });

  group('손으로 그린 세로줄 3개 사다리', () {
    // 행0: 0─1, 행1: 1─2, 행2: 0─1
    //  0   1   2
    //  ├───┤   │
    //  │   ├───┤
    //  ├───┤   │
    final ladder = Ladder(
      columns: 3,
      rungs: [
        [true, false],
        [false, true],
        [true, false],
      ],
    );

    test('도착 칸 = 0→2, 1→1, 2→0', () {
      expect(ladder.endColumn(0), 2);
      expect(ladder.endColumn(1), 1);
      expect(ladder.endColumn(2), 0);
    });

    test('경로 꼭짓점을 위에서 아래로 돌려준다', () {
      expect(ladder.path(0), [
        (column: 0, level: 0),
        (column: 0, level: 1),
        (column: 1, level: 1),
        (column: 1, level: 2),
        (column: 2, level: 2),
        (column: 2, level: 4),
      ]);
      expect(ladder.path(1), [
        (column: 1, level: 0),
        (column: 1, level: 1),
        (column: 0, level: 1),
        (column: 0, level: 3),
        (column: 1, level: 3),
        (column: 1, level: 4),
      ]);
      expect(ladder.path(2), [
        (column: 2, level: 0),
        (column: 2, level: 2),
        (column: 1, level: 2),
        (column: 1, level: 3),
        (column: 0, level: 3),
        (column: 0, level: 4),
      ]);
    });

    test('같은 행 이웃 가로줄이 있으면 만들 때 거부한다', () {
      expect(
        () => Ladder(
          columns: 3,
          rungs: [
            [true, true],
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}

bool _sameRungs(List<List<bool>> a, List<List<bool>> b) {
  if (a.length != b.length) return false;
  for (var r = 0; r < a.length; r++) {
    if (a[r].length != b[r].length) return false;
    for (var p = 0; p < a[r].length; p++) {
      if (a[r][p] != b[r][p]) return false;
    }
  }
  return true;
}
