import 'dart:math';

import 'ladder.dart';
import 'ladder_setup.dart';

/// 사다리 한 판: 설정과 seed 로 정한 사다리 모양 + 아래 결과 칸 순서.
class LadderRound {
  LadderRound._({
    required this.names,
    required this.bottom,
    required this.ladder,
  });

  /// 사다리 행 수. 이웃 쌍마다 가로줄 2~4개가 들어갈 여유를 둔다.
  static const rows = 12;

  /// [setup] 으로 한 판을 만든다. 같은 [seed] 는 같은 판을 만든다.
  ///
  /// 사다리 모양만으로는 출발→도착이 고르게 섞이지 않는다(2명이면 가로줄이
  /// 2·4개일 때 제자리로 내려온다). 그래서 아래 결과 칸 순서도 같은 Random 으로
  /// 섞어 누구나 각 결과를 같은 확률로 받게 한다.
  factory LadderRound.start(LadderSetup setup, int seed) {
    if (!setup.canStart) {
      throw ArgumentError.value(
        setup.remaining,
        'setup.remaining',
        '결과 자리 합계가 참가자 수(2~12명)와 같아야 합니다',
      );
    }
    final random = Random(seed);
    final bottom = setup.expandedResults..shuffle(random);
    final ladder = Ladder.generate(
      setup.players.length,
      rows,
      random.nextInt(1 << 32),
    );
    return LadderRound._(
      names: List.unmodifiable(setup.playerNames),
      bottom: List.unmodifiable(bottom),
      ladder: ladder,
    );
  }

  /// 위쪽 이름 칸(참가자 순서).
  final List<String> names;

  /// 아래 결과 칸. `bottom[c]` = c 번 세로줄 아래 결과.
  final List<String> bottom;

  final Ladder ladder;

  int get size => names.length;

  /// [player] 번 참가자가 받는 결과.
  String resultFor(int player) => bottom[ladder.endColumn(player)];

  /// [column] 번 결과 칸에 도착하는 참가자 번호.
  int playerAt(int column) {
    for (var player = 0; player < size; player++) {
      if (ladder.endColumn(player) == column) return player;
    }
    throw RangeError.range(column, 0, size - 1, 'column');
  }

  /// 「결과 복사」 글. 참가자 순서대로 한 줄에 「이름 → 결과」.
  String get summaryText => [
    for (var i = 0; i < size; i++) '${names[i]} → ${resultFor(i)}',
  ].join('\n');
}
