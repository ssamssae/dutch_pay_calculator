import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 위쪽 화살표가 고정된 룰렛 원판.
///
/// 칸 0 은 12시에서 시계 방향으로 시작한다. [turns] 는 원판이 시계 방향으로
/// 돈 바퀴 수다.
class RouletteWheel extends StatelessWidget {
  const RouletteWheel({super.key, required this.labels, required this.turns});

  final List<String> labels;
  final double turns;

  /// 화살표가 가리키는 칸. [turns] 0 이면 칸 0 의 시작(12시)이다.
  static int indexAtPointer(double turns, int count) {
    if (count <= 0) return 0;
    var shifted = (-turns) % 1;
    if (shifted < 0) shifted += 1;
    var index = (shifted * count).floor();
    if (index >= count) index = count - 1;
    if (index < 0) index = 0;
    return index;
  }

  /// [index] 칸 한가운데가 화살표에 오도록, 지금보다 [extraTurns] 바퀴 이상 더 돈 위치.
  static double targetTurns({
    required double currentTurns,
    required int index,
    required int count,
    int extraTurns = 4,
  }) {
    if (count <= 0) return currentTurns + extraTurns;
    final center = (index + 0.5) / count;
    var fraction = (1 - center) % 1;
    if (fraction < 0) fraction += 1;
    final minimum = currentTurns + extraTurns;
    var target = minimum.floorToDouble() + fraction;
    if (target < minimum) target += 1;
    return target;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipOval(
            child: CustomPaint(
              painter: _DiscPainter(labels: labels, turns: turns),
            ),
          ),
        ),
        const Align(
          alignment: Alignment.topCenter,
          child: CustomPaint(
            key: ValueKey('roulette-pointer'),
            size: Size(30, 24),
            painter: _PointerPainter(),
          ),
        ),
      ],
    );
  }

  /// 위 화살표 색. 알록달록한 칸 위에서도 눈에 띄게 검정에 가까운 색(T-261103-023).
  static const pointerColor = TossColors.textPrimary;

  /// 칸 색 순서. 이웃 칸끼리 서로 다른 밝은 색이 오도록 섞었다(T-261103-023).
  static const palette = <Color>[
    Color(0xFF3182F6), // 파랑
    Color(0xFFFFB331), // 노랑
    Color(0xFFF04452), // 빨강
    Color(0xFF17A58F), // 청록
    Color(0xFF8B5CF6), // 보라
    Color(0xFFFF8A3D), // 주황
    Color(0xFF2BC0E4), // 하늘
    Color(0xFFFF6CA1), // 분홍
    Color(0xFF6BCB77), // 연두
    Color(0xFF4C6EF5), // 남색
  ];

  /// [count] 칸 원판에서 [index] 칸의 색.
  ///
  /// 차례대로 [palette] 를 돌린다. 마지막 칸이 첫 칸과 같은 색이 되면
  /// 둘이 맞닿으므로 마지막 칸만 다음 색으로 바꾼다.
  static Color sliceColor(int index, int count) {
    final n = palette.length;
    var color = palette[index % n];
    if (count > 1 && index == count - 1 && index % n == 0) {
      color = palette[(index + 1) % n];
      if (color == palette[(index - 1) % n]) color = palette[(index + 2) % n];
    }
    return color;
  }
}

Color _labelColor(Color slice) {
  return ThemeData.estimateBrightnessForColor(slice) == Brightness.dark
      ? Colors.white
      : TossColors.textPrimary;
}

class _DiscPainter extends CustomPainter {
  _DiscPainter({required this.labels, required this.turns});

  final List<String> labels;
  final double turns;

  @override
  void paint(Canvas canvas, Size size) {
    final count = labels.length;
    if (count == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final sweep = 2 * pi / count;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turns * 2 * pi);
    canvas.translate(-center.dx, -center.dy);

    for (var i = 0; i < count; i++) {
      final color = RouletteWheel.sliceColor(i, count);
      canvas.drawArc(
        rect,
        -pi / 2 + i * sweep,
        sweep,
        true,
        Paint()..color = color,
      );
      _paintLabel(
        canvas,
        labels[i],
        center,
        radius,
        -pi / 2 + (i + 0.5) * sweep,
        color,
      );
    }

    final seam = Paint()
      ..color = TossColors.bgDeep
      ..strokeWidth = 2;
    for (var i = 0; i < count; i++) {
      final angle = -pi / 2 + i * sweep;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        ),
        seam,
      );
    }
    canvas.restore();

    canvas.drawCircle(
      center,
      radius * 0.16,
      Paint()..color = TossColors.surface,
    );
    canvas.drawCircle(
      center,
      radius * 0.16,
      Paint()
        ..color = TossColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    double angle,
    Color slice,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: _labelColor(slice),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: radius * 0.5);

    final distance = radius * 0.62;
    canvas.save();
    canvas.translate(
      center.dx + distance * cos(angle),
      center.dy + distance * sin(angle),
    );
    canvas.rotate(angle + pi / 2);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DiscPainter oldDelegate) {
    return oldDelegate.turns != turns ||
        !_sameLabels(oldDelegate.labels, labels);
  }
}

bool _sameLabels(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = RouletteWheel.pointerColor);
    // 어두운 칸 위에서도 모양이 보이게 흰 테두리를 두른다.
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) => false;
}
