import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ladder/ladder_painter.dart';
import '../ladder/ladder_round.dart';
import '../ladder/ladder_setup.dart';
import '../theme/app_theme.dart';

/// 사다리 화면: 위 이름을 누르면 그 사람 경로가 내려가고 아래 결과가 강조된다.
class LadderScreen extends StatefulWidget {
  const LadderScreen({super.key, required this.setup, this.seed});

  final LadderSetup setup;

  /// 첫 판의 seed. null 이면 판마다 새로 뽑는다.
  final int? seed;

  @override
  State<LadderScreen> createState() => _LadderScreenState();
}

class _LadderScreenState extends State<LadderScreen>
    with SingleTickerProviderStateMixin {
  static const _minColumnWidth = 44.0;
  static const _revealDuration = Duration(milliseconds: 1000);

  final _random = Random();
  late LadderRound _round = LadderRound.start(
    widget.setup,
    widget.seed ?? _newSeed(),
  );
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _revealDuration,
  )..addStatusListener(_onStatus);

  /// 경로를 끝까지 그린 참가자.
  final _revealed = <int>{};

  /// 지금 내려가는 중인 참가자.
  final _running = <int>{};

  int _newSeed() => _random.nextInt(1 << 32);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) setState(_settle);
  }

  void _settle() {
    _revealed.addAll(_running);
    _running.clear();
  }

  void _run(Iterable<int> players) {
    setState(() {
      _settle();
      _running.addAll(players);
      _revealed.removeAll(_running);
    });
    if (_running.isNotEmpty) _controller.forward(from: 0);
  }

  void _revealAll() {
    _settle();
    _run([
      for (var p = 0; p < _round.size; p++)
        if (!_revealed.contains(p)) p,
    ]);
  }

  void _reshuffle() {
    _controller.reset();
    setState(() {
      _revealed.clear();
      _running.clear();
      _round = LadderRound.start(widget.setup, _newSeed());
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _round.summaryText));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('결과를 복사했어요')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = _round.size;
    final colors = [
      for (var p = 0; p < size; p++) pathColor(p, theme.brightness),
    ];
    final arrivals = [for (var c = 0; c < size; c++) _round.playerAt(c)];

    return Scaffold(
      backgroundColor: TossColors.bgDeep,
      appBar: AppBar(
        title: const Text(
          '사다리 타기',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
            color: TossColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columnWidth = max(
                    constraints.maxWidth / size,
                    _minColumnWidth,
                  );
                  final board = SizedBox(
                    width: columnWidth * size,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 56,
                          child: Row(
                            children: [
                              for (var p = 0; p < size; p++)
                                SizedBox(
                                  width: columnWidth,
                                  child: _NameCell(
                                    key: ValueKey('name-$p'),
                                    name: _round.names[p],
                                    color: colors[p],
                                    active:
                                        _revealed.contains(p) ||
                                        _running.contains(p),
                                    onTap: () => _run([p]),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: CustomPaint(
                              painter: LadderPainter(
                                ladder: _round.ladder,
                                colors: colors,
                                lineColor: TossColors.textFaint,
                                revealed: Set.of(_revealed),
                                running: Set.of(_running),
                                progress: _controller,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 64,
                          child: Row(
                            children: [
                              for (var c = 0; c < size; c++)
                                SizedBox(
                                  width: columnWidth,
                                  child: _ResultCell(
                                    label: _round.bottom[c],
                                    owner: _revealed.contains(arrivals[c])
                                        ? _round.names[arrivals[c]]
                                        : null,
                                    color: colors[arrivals[c]],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  if (columnWidth * size <= constraints.maxWidth) return board;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: board,
                  );
                },
              ),
            ),
            _Summary(
              round: _round,
              revealed: _revealed,
              running: _running.isNotEmpty,
              colors: colors,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('reveal-all'),
                          style: _accentButtonStyle,
                          onPressed: _revealAll,
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('모두 보기'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('reshuffle'),
                          style: _ghostButtonStyle,
                          onPressed: _reshuffle,
                          icon: const Icon(Icons.shuffle),
                          label: const Text('다시 섞기'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('copy'),
                          style: _ghostButtonStyle,
                          onPressed: _copy,
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('결과 복사'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          key: const ValueKey('home'),
                          style: TextButton.styleFrom(
                            foregroundColor: TossColors.textSecondary,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('처음으로'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _accentButtonStyle = FilledButton.styleFrom(
  backgroundColor: TossColors.accent,
  foregroundColor: Colors.white,
  elevation: 0,
  minimumSize: const Size(0, 48),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
);

final _ghostButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: TossColors.textPrimary,
  backgroundColor: TossColors.surface,
  side: const BorderSide(color: TossColors.border),
  minimumSize: const Size(0, 48),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
);

class _NameCell extends StatelessWidget {
  const _NameCell({
    super.key,
    required this.name,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Material(
        color: active
            ? color.withValues(alpha: 0.16)
            : TossColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: active ? color : TossColors.border,
            width: active ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: active ? color : TossColors.textPrimary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCell extends StatelessWidget {
  const _ResultCell({
    required this.label,
    required this.owner,
    required this.color,
  });

  final String label;

  /// 이 칸에 도착한 사람(경로를 다 그린 뒤에만).
  final String? owner;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final owner = this.owner;
    final shown = owner != null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: shown
            ? color.withValues(alpha: 0.16)
            : TossColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: shown ? color : TossColors.border,
          width: shown ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: shown ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(
              color: TossColors.textPrimary,
              fontWeight: shown ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          if (shown)
            Text(
              owner,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(color: color),
            ),
        ],
      ),
    );
  }
}

/// 경로를 다 그린 사람의 「이름 → 결과」 목록.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.round,
    required this.revealed,
    required this.running,
    required this.colors,
  });

  final LadderRound round;
  final Set<int> revealed;
  final bool running;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shown = [
      for (var p = 0; p < round.size; p++)
        if (revealed.contains(p)) p,
    ];
    if (shown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          running ? '사다리 타는 중…' : '이름을 누르면 그 사람 사다리를 타요',
          style: textTheme.bodyMedium?.copyWith(color: TossColors.textFaint),
        ),
      );
    }
    // 작은 화면에서 사다리 높이를 남기도록 목록 높이를 화면의 16% 안팎으로 묶는다.
    final maxHeight = (MediaQuery.sizeOf(context).height * 0.16).clamp(
      64.0,
      132.0,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in shown)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: TossColors.surface,
                      border: Border.all(color: TossColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(backgroundColor: colors[p], radius: 5),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '${round.names[p]} → '),
                                  TextSpan(
                                    text: round.resultFor(p),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              style: textTheme.bodyMedium?.copyWith(
                                color: TossColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
