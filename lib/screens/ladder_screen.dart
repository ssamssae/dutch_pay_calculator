import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ladder/ladder_painter.dart';
import '../ladder/ladder_round.dart';
import '../ladder/ladder_setup.dart';
import '../theme/app_theme.dart';

/// 사다리 화면: 위 이름을 누르면 그 사람 경로가 내려가고 아래 결과가 강조된다.
///
/// 아래 결과 칸은 처음에 가려져 있다. 칸을 눌러야(또는 「모두 보기」) 결과가
/// 보인다. 그래서 사다리를 눈으로 따라가 미리 답을 알 수 없다(T-261103-022).
/// 사다리를 타기 전에는 가운데를 눌러 가로줄을 더 그을 수 있다.
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

  /// 가림막을 걷어 결과가 보이는 아래 칸 번호.
  final _opened = <int>{};

  /// 「모두 보기」: 경로를 다 그리면 아래 칸도 모두 연다.
  var _openAllOnSettle = false;

  int _newSeed() => _random.nextInt(1 << 32);

  /// 누군가 사다리를 탔거나 결과 칸을 열었으면 판이 시작된 것이다.
  /// 시작된 판에는 가로줄을 더 긋지 않는다(이미 본 결과가 바뀌면 안 된다).
  bool get _started =>
      _revealed.isNotEmpty || _running.isNotEmpty || _opened.isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    setState(() {
      _settle();
      if (_openAllOnSettle) _openAll();
    });
  }

  void _openAll() {
    _openAllOnSettle = false;
    _opened.addAll([for (var c = 0; c < _round.size; c++) c]);
  }

  void _open(int column) {
    if (_opened.contains(column)) return;
    HapticFeedback.selectionClick();
    setState(() => _opened.add(column));
  }

  /// 사다리 가운데를 누른 자리([local], 그림 영역 [area] 기준)에 가로줄을 더 긋는다.
  ///
  /// 누른 높이에서 가장 가까운 행에 긋는다. 그 행이 이웃 가로줄과 붙으면
  /// 바로 위·아래 행 중 가까운 쪽에 긋는다. 둘 다 안 되면 긋지 않는다.
  void _addRung(Offset local, Size area) {
    if (_started) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('가로줄은 사다리를 타기 전에만 그을 수 있어요')),
        );
      return;
    }
    final ladder = _round.ladder;
    final columnWidth = area.width / ladder.columns;
    final pair = (local.dx / columnWidth - 0.5).floor();
    if (pair < 0 || pair > ladder.columns - 2) return;
    // 행 r 의 높이 = area.height * (r + 1) / (rows + 1) (LadderPainter 와 같다).
    final level = local.dy / area.height * (ladder.rows + 1) - 1;
    final nearest = level.round();
    final candidates = [nearest, nearest - 1, nearest + 1]
      ..removeWhere((r) => r < 0 || r >= ladder.rows)
      ..sort((a, b) => (a - level).abs().compareTo((b - level).abs()));
    for (final row in candidates) {
      if (ladder.canAddRung(row, pair)) {
        HapticFeedback.lightImpact();
        setState(() => _round = _round.withRung(row, pair));
        return;
      }
    }
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
    final rest = [
      for (var p = 0; p < _round.size; p++)
        if (!_revealed.contains(p)) p,
    ];
    if (rest.isEmpty) {
      setState(_openAll);
      return;
    }
    _openAllOnSettle = true;
    _run(rest);
  }

  void _reshuffle() {
    _controller.reset();
    setState(() {
      _revealed.clear();
      _running.clear();
      _opened.clear();
      _openAllOnSettle = false;
      _round = LadderRound.start(widget.setup, _newSeed());
    });
  }

  /// 사다리를 다 타고 결과 칸까지 연 사람.
  Set<int> get _known => {
    for (final p in _revealed)
      if (_opened.contains(_round.ladder.endColumn(p))) p,
  };

  Future<void> _copy() async {
    // 아직 가려진 결과는 복사하지 않는다(복사로 미리 답을 알 수 없게).
    final known = _known;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (known.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('아직 확인한 결과가 없어요')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: _round.summaryTextFor(known)));
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('결과를 복사했어요')));
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
                            child: LayoutBuilder(
                              builder: (context, area) => GestureDetector(
                                key: const ValueKey('ladder-board'),
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (details) => _addRung(
                                  details.localPosition,
                                  area.biggest,
                                ),
                                child: CustomPaint(
                                  size: area.biggest,
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
                                    key: ValueKey('result-cell-$c'),
                                    label: _round.bottom[c],
                                    opened: _opened.contains(c),
                                    owner: _revealed.contains(arrivals[c])
                                        ? _round.names[arrivals[c]]
                                        : null,
                                    color: colors[arrivals[c]],
                                    onTap: () => _open(c),
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
              known: _known,
              running: _running.isNotEmpty,
              started: _started,
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

/// 아래 결과 칸. 처음에는 「?」 가림막이고, 누르면 결과가 보인다(제비뽑기처럼).
class _ResultCell extends StatelessWidget {
  const _ResultCell({
    super.key,
    required this.label,
    required this.opened,
    required this.owner,
    required this.color,
    required this.onTap,
  });

  final String label;

  /// 가림막을 걷었는지.
  final bool opened;

  /// 이 칸에 도착한 사람(경로를 다 그린 뒤에만).
  final String? owner;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final owner = this.owner;
    final arrived = owner != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Material(
        color: arrived
            ? color.withValues(alpha: 0.16)
            : opened
            ? TossColors.surfaceElevated
            : TossColors.accentSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: arrived
                ? color
                : opened
                ? TossColors.border
                : TossColors.accent,
            width: arrived || !opened ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: opened ? null : onTap,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Padding(
              key: ValueKey(opened),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    opened ? label : '?',
                    maxLines: opened && !arrived ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      color: opened
                          ? TossColors.textPrimary
                          : TossColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: opened ? null : 20,
                    ),
                  ),
                  if (arrived)
                    Text(
                      owner,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(color: color),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 사다리를 다 타고 결과 칸까지 연 사람의 「이름 → 결과」 목록.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.round,
    required this.known,
    required this.running,
    required this.started,
    required this.colors,
  });

  final LadderRound round;
  final Set<int> known;
  final bool running;
  final bool started;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shown = [
      for (var p = 0; p < round.size; p++)
        if (known.contains(p)) p,
    ];
    if (shown.isEmpty) {
      final hint = running
          ? '사다리 타는 중…'
          : started
          ? '아래 「?」 칸을 누르면 결과가 보여요'
          : '가운데를 누르면 가로줄을 더 그어요 · 이름을 누르면 사다리를 타요';
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          hint,
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
