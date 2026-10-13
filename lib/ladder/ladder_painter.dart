import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ladder.dart';

/// 참가자 번호별 경로 색. 12명까지 서로 다른 색이고,
/// 밝은 테마에서는 진한 색, 어두운 테마에서는 밝은 색을 쓴다.
Color pathColor(int player, Brightness brightness) {
  const hues = <MaterialColor>[
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.brown,
    Colors.cyan,
    Colors.amber,
    Colors.lime,
  ];
  final hue = hues[player % hues.length];
  return brightness == Brightness.dark ? hue.shade300 : hue.shade700;
}

/// 세로줄·가로줄과 참가자 경로를 그린다.
///
/// [revealed] 경로는 끝까지, [running] 경로는 [progress] 비율만큼 그린다.
class LadderPainter extends CustomPainter {
  LadderPainter({
    required this.ladder,
    required this.colors,
    required this.lineColor,
    required this.revealed,
    required this.running,
    required this.progress,
  }) : super(repaint: progress);

  final Ladder ladder;
  final List<Color> colors;
  final Color lineColor;
  final Set<int> revealed;
  final Set<int> running;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final columnWidth = size.width / ladder.columns;
    final bottom = ladder.rows + 1;
    Offset at(LadderPoint point) => Offset(
      columnWidth * (point.column + 0.5),
      size.height * point.level / bottom,
    );

    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var c = 0; c < ladder.columns; c++) {
      canvas.drawLine(
        at((column: c, level: 0)),
        at((column: c, level: bottom)),
        line,
      );
    }
    for (var r = 0; r < ladder.rows; r++) {
      for (var p = 0; p < ladder.columns - 1; p++) {
        if (!ladder.rungs[r][p]) continue;
        canvas.drawLine(
          at((column: p, level: r + 1)),
          at((column: p + 1, level: r + 1)),
          line,
        );
      }
    }

    final shown = {...revealed, ...running};
    final occupants = _occupants();
    for (final player in revealed) {
      _drawPath(canvas, player, 1, at, shown, occupants);
    }
    for (final player in running) {
      _drawPath(canvas, player, progress.value, at, shown, occupants);
    }
  }

  /// `occupants[r][c]` = r 번째 행에 닿기 직전 c 번 세로줄에 있는 참가자.
  List<List<int>> _occupants() {
    final at = List<int>.generate(ladder.columns, (c) => c);
    final result = <List<int>>[];
    for (var r = 0; r < ladder.rows; r++) {
      result.add(List.of(at));
      for (var p = 0; p < ladder.columns - 1; p++) {
        if (!ladder.rungs[r][p]) continue;
        final left = at[p];
        at[p] = at[p + 1];
        at[p + 1] = left;
      }
    }
    return result;
  }

  void _drawPath(
    Canvas canvas,
    int player,
    double t,
    Offset Function(LadderPoint) at,
    Set<int> shown,
    List<List<int>> occupants,
  ) {
    final raw = ladder.path(player);
    // 가로줄 하나는 반대 방향 두 사람이 지난다. 둘 다 보일 때는 오른쪽으로
    // 가는 경로를 위로, 왼쪽으로 가는 경로를 아래로 3px 벌려 두 색을 모두 보인다.
    double crossOffset(LadderPoint from, LadderPoint to) {
      final other = occupants[from.level - 1][to.column];
      if (!shown.contains(other)) return 0;
      return to.column > from.column ? -3 : 3;
    }

    final points = <Offset>[];
    for (var i = 0; i < raw.length; i++) {
      final point = raw[i];
      final next = i + 1 < raw.length ? raw[i + 1] : null;
      final prev = i > 0 ? raw[i - 1] : null;
      var dy = 0.0;
      if (next != null && next.level == point.level) {
        dy = crossOffset(point, next);
      } else if (prev != null && prev.level == point.level) {
        dy = crossOffset(prev, point);
      }
      points.add(at(point) + Offset(0, dy));
    }
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    var left = total * t.clamp(0.0, 1.0);
    var tip = points.first;
    final path = Path()..moveTo(tip.dx, tip.dy);
    for (var i = 1; i < points.length && left > 0; i++) {
      final segment = points[i] - points[i - 1];
      final length = segment.distance;
      if (length <= left) {
        tip = points[i];
        left -= length;
      } else {
        tip = points[i - 1] + segment * (left / length);
        left = 0;
      }
      path.lineTo(tip.dx, tip.dy);
    }

    final color = colors[player];
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (t < 1) {
      canvas.drawCircle(tip, 7, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(LadderPainter oldDelegate) =>
      oldDelegate.ladder != ladder ||
      oldDelegate.lineColor != lineColor ||
      !listEquals(oldDelegate.colors, colors) ||
      !setEquals(oldDelegate.revealed, revealed) ||
      !setEquals(oldDelegate.running, running);
}
