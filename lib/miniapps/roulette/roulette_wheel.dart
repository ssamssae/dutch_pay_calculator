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
          child: CustomPaint(size: Size(18, 12), painter: _PointerPainter()),
        ),
      ],
    );
  }
}

Color _sliceColor(int index, int count) {
  // 홀수 칸은 첫 칸과 마지막 칸이 맞닿으므로 셋째 청록으로 경계를 가른다.
  if (count.isOdd && index == count - 1) return TossColors.accentBorder;
  return index.isEven ? TossColors.accent : TossColors.accentNeon;
}

Color _labelColor(Color slice) {
  if (slice == TossColors.accent) return TossColors.bgDeep;
  return TossColors.textPrimary;
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
      final color = _sliceColor(i, count);
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
    canvas.drawPath(path, Paint()..color = TossColors.accent);
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) => false;
}
