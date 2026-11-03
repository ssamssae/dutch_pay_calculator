import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// 꽃가루가 터져서 흩날리는 시간.
const _burstDuration = Duration(milliseconds: 2400);

/// 「축하합니다!」 창을 띄운다. 꽃가루가 가운데와 아래 두 모서리에서 터진다.
///
/// 「확인」이나 창 밖을 누르면 닫힌다. 기기 설정에서 움직임 줄이기를 켜면
/// 꽃가루 없이 창만 띄운다.
Future<void> showLotteryCelebration(BuildContext context, String label) {
  HapticFeedback.heavyImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: const Color(0x73000000),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, _, _) => LotteryCelebration(label: label),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// 축하 창 본문. 카드가 튀어나오고 그 위로 꽃가루가 터진다.
class LotteryCelebration extends StatefulWidget {
  const LotteryCelebration({super.key, required this.label});

  /// 뽑은 제비 글. 예: 14호차.
  final String label;

  @override
  State<LotteryCelebration> createState() => _LotteryCelebrationState();
}

class _LotteryCelebrationState extends State<LotteryCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: _burstDuration,
  );
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.55,
    end: 1,
  ).animate(CurvedAnimation(parent: _pop, curve: Curves.elasticOut));
  late final List<_Confetto> _pieces = _Confetto.burst(Random());
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _pop.value = 1;
    } else {
      _pop.forward();
      _burst.forward();
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ScaleTransition(
              scale: _scale,
              child: _CelebrationCard(
                label: widget.label,
                onClose: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ),
        if (!_reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                key: const ValueKey('lottery-confetti'),
                painter: _ConfettiPainter(pieces: _pieces, progress: _burst),
              ),
            ),
          ),
      ],
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({required this.label, required this.onClose});

  final String label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Material(
        key: const ValueKey('lottery-celebration'),
        color: TossColors.surface,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ExcludeSemantics(
                  child: Text(
                    '🎉',
                    style: TextStyle(fontSize: 44, height: 1.1),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '축하합니다!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: TossColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: TossColors.accentSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TossColors.accentBorder),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      key: const ValueKey('lottery-celebration-label'),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: TossColors.accent,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    key: const ValueKey('lottery-celebration-ok'),
                    style: FilledButton.styleFrom(
                      backgroundColor: TossColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onClose,
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 꽃가루 색. 앱 청록 두 가지 + 축제 색 다섯 가지.
const _confettiColors = <Color>[
  TossColors.accent,
  TossColors.accentNeon,
  Color(0xFFFFC94D),
  Color(0xFFFF6B6B),
  Color(0xFF4DA3FF),
  Color(0xFFB18CFF),
  Color(0xFFFF8FC8),
];

/// 공기 저항(1/초). 클수록 빨리 멈춘다.
const _drag = 2.6;

/// 아래로 끄는 힘(짧은 변/초²). 저항과 만나 천천히 떨어지는 속도가 된다.
const _gravity = 1.3;

/// 꽃가루 한 조각. 길이·속도는 화면 짧은 변을 1로 둔 값이다.
class _Confetto {
  const _Confetto({
    required this.origin,
    required this.vx,
    required this.vy,
    required this.width,
    required this.height,
    required this.round,
    required this.color,
    required this.rotation,
    required this.spin,
    required this.flip,
    required this.sway,
    required this.phase,
  });

  /// 가운데 60조각 + 아래 두 모서리 25조각씩.
  static List<_Confetto> burst(Random random) => [
    for (var i = 0; i < 60; i++)
      _Confetto._random(
        random,
        origin: const Offset(0.5, 0.42),
        angle: random.nextDouble() * 2 * pi,
        speed: 1.0 + random.nextDouble() * 1.5,
        lift: 0.6,
      ),
    for (var i = 0; i < 25; i++)
      _Confetto._random(
        random,
        origin: const Offset(0, 1),
        angle: -pi / 3 + (random.nextDouble() - 0.5) * 0.45,
        speed: 2.6 + random.nextDouble() * 1.2,
        lift: 0,
      ),
    for (var i = 0; i < 25; i++)
      _Confetto._random(
        random,
        origin: const Offset(1, 1),
        angle: -2 * pi / 3 + (random.nextDouble() - 0.5) * 0.45,
        speed: 2.6 + random.nextDouble() * 1.2,
        lift: 0,
      ),
  ];

  factory _Confetto._random(
    Random random, {
    required Offset origin,
    required double angle,
    required double speed,
    required double lift,
  }) {
    final round = random.nextDouble() < 0.3;
    final width = 0.016 + random.nextDouble() * 0.01;
    return _Confetto(
      origin: origin,
      vx: cos(angle) * speed,
      vy: sin(angle) * speed - lift,
      width: width,
      height: round ? width : width * (1.4 + random.nextDouble() * 0.6),
      round: round,
      color: _confettiColors[random.nextInt(_confettiColors.length)],
      rotation: random.nextDouble() * 2 * pi,
      spin: (random.nextDouble() - 0.5) * 12,
      flip: 4 + random.nextDouble() * 6,
      sway: 0.01 + random.nextDouble() * 0.02,
      phase: random.nextDouble() * 2 * pi,
    );
  }

  /// 화면 크기 비율로 적은 출발점. (0.5, 0.42) = 가운데 조금 위.
  final Offset origin;
  final double vx;
  final double vy;
  final double width;
  final double height;
  final bool round;
  final Color color;
  final double rotation;
  final double spin;

  /// 종이가 뒤집히는 빠르기(라디안/초).
  final double flip;

  /// 좌우로 살랑이는 폭.
  final double sway;
  final double phase;

  /// [t] 초 뒤 위치. 저항을 받는 속도에 중력이 더해진다.
  Offset positionAt(double t, Size size, double unit) {
    final decay = (1 - exp(-_drag * t)) / _drag;
    const terminal = _gravity / _drag;
    final dx = vx * decay + sway * sin(flip * 0.5 * t + phase);
    final dy = terminal * t + (vy - terminal) * decay;
    return Offset(
      origin.dx * size.width + dx * unit,
      origin.dy * size.height + dy * unit,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.pieces, required this.progress})
    : super(repaint: progress);

  final List<_Confetto> pieces;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final value = progress.value;
    if (value <= 0 || value >= 1) return;
    final t = value * _burstDuration.inMilliseconds / 1000;
    final unit = size.shortestSide;
    // 마지막 30% 동안 서서히 사라진다.
    final alpha = value < 0.7 ? 1.0 : (1 - value) / 0.3;
    final paint = Paint();
    for (final piece in pieces) {
      final position = piece.positionAt(t, size, unit);
      paint.color = piece.color.withValues(alpha: alpha);
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(piece.rotation + piece.spin * t)
        ..scale(1, cos(piece.flip * t + piece.phase));
      final w = piece.width * unit;
      final h = piece.height * unit;
      if (piece.round) {
        canvas.drawCircle(Offset.zero, w / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: h),
            Radius.circular(w * 0.2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.pieces != pieces || oldDelegate.progress != progress;
}
