import 'dart:math';

/// 사다리 경로의 꼭짓점.
///
/// [level] 0 = 맨 위(이름 칸), r+1 = r 번째 행의 가로줄 높이,
/// rows+1 = 맨 아래(결과 칸).
typedef LadderPoint = ({int column, int level});

/// 사다리 한 판.
///
/// `rungs[r][p]` 가 참이면 r 번째 행에 p 번 세로줄과 p+1 번 세로줄을 잇는
/// 가로줄이 있다. 같은 행에서 이웃한 가로줄(`p`, `p+1`)은 함께 있을 수 없다.
class Ladder {
  Ladder({required this.columns, required List<List<bool>> rungs})
    : rungs = List.unmodifiable([
        for (final row in rungs) List<bool>.unmodifiable(row),
      ]) {
    if (columns < 2) {
      throw ArgumentError.value(columns, 'columns', '세로줄은 2개 이상이어야 합니다');
    }
    for (var r = 0; r < this.rungs.length; r++) {
      final row = this.rungs[r];
      if (row.length != columns - 1) {
        throw ArgumentError('행 $r 의 칸 수 ${row.length} 가 ${columns - 1} 이 아닙니다');
      }
      for (var p = 0; p + 1 < row.length; p++) {
        if (row[p] && row[p + 1]) {
          throw ArgumentError('행 $r 에서 가로줄 $p 와 ${p + 1} 이 붙어 있습니다');
        }
      }
    }
  }

  /// [generate] 가 이웃한 쌍마다 가로줄 2~4개를 항상 놓을 수 있는 최소 행 수.
  /// (왼쪽 쌍이 최대 4행을 쓰고 남은 행에서 최대 4행을 고른다.)
  static const minRows = 8;

  final int columns;
  final List<List<bool>> rungs;

  int get rows => rungs.length;

  /// 세로줄 [columns]개, 행 [rows]개 사다리를 `Random(seed)` 로 만든다.
  ///
  /// 이웃한 세로줄 쌍마다 가로줄을 2~4개 놓고, 같은 행에서 이웃한 가로줄은
  /// 붙이지 않는다. 같은 [seed] 는 언제나 같은 사다리를 만든다.
  static Ladder generate(int columns, int rows, int seed) {
    if (columns < 2) {
      throw ArgumentError.value(columns, 'columns', '세로줄은 2개 이상이어야 합니다');
    }
    if (rows < minRows) {
      throw ArgumentError.value(rows, 'rows', '행은 $minRows개 이상이어야 합니다');
    }
    final random = Random(seed);
    final grid = List.generate(rows, (_) => List.filled(columns - 1, false));
    for (var p = 0; p < columns - 1; p++) {
      final count = 2 + random.nextInt(3);
      // 왼쪽 쌍이 쓴 행만 피하면 된다. 오른쪽 쌍은 다음 차례에 이 쌍을 피한다.
      final free = [
        for (var r = 0; r < rows; r++)
          if (p == 0 || !grid[r][p - 1]) r,
      ]..shuffle(random);
      for (final r in free.take(count)) {
        grid[r][p] = true;
      }
    }
    return Ladder(columns: columns, rungs: grid);
  }

  /// [pair] 번 세로줄과 그 오른쪽 세로줄을 잇는 가로줄 개수.
  int rungCount(int pair) {
    RangeError.checkValueInInterval(pair, 0, columns - 2, 'pair');
    var count = 0;
    for (final row in rungs) {
      if (row[pair]) count++;
    }
    return count;
  }

  /// [start] 번 세로줄에서 출발해 도착하는 세로줄 번호.
  int endColumn(int start) {
    RangeError.checkValueInInterval(start, 0, columns - 1, 'start');
    var column = start;
    for (var r = 0; r < rows; r++) {
      column = _next(column, r);
    }
    return column;
  }

  /// [start] 번 세로줄에서 출발한 경로의 꼭짓점을 위에서 아래 순서로 돌려준다.
  ///
  /// 첫 점은 `(start, 0)`, 마지막 점은 `(endColumn(start), rows + 1)` 이다.
  /// 가로줄을 건널 때마다 건너기 전·후 두 점이 같은 level 로 들어간다.
  List<LadderPoint> path(int start) {
    RangeError.checkValueInInterval(start, 0, columns - 1, 'start');
    var column = start;
    final points = <LadderPoint>[(column: column, level: 0)];
    for (var r = 0; r < rows; r++) {
      final next = _next(column, r);
      if (next != column) {
        points
          ..add((column: column, level: r + 1))
          ..add((column: next, level: r + 1));
        column = next;
      }
    }
    points.add((column: column, level: rows + 1));
    return points;
  }

  int _next(int column, int row) {
    final line = rungs[row];
    if (column > 0 && line[column - 1]) return column - 1;
    if (column < columns - 1 && line[column]) return column + 1;
    return column;
  }
}
