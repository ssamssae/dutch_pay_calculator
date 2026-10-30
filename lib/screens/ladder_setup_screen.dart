import 'package:flutter/material.dart';

import '../ladder/ladder_setup.dart';
import '../ladder/ladder_setup_store.dart';
import '../services/ads_service.dart';
import '../theme/app_theme.dart';
import '../widgets/toss_widgets.dart';
import 'ladder_screen.dart';

/// 사다리 탭 첫 화면: 참가자 이름과 결과(라벨 × 개수)를 적는다.
class LadderSetupScreen extends StatefulWidget {
  const LadderSetupScreen({
    super.key,
    required this.store,
    required this.initialSetup,
  });

  final LadderSetupStore store;
  final LadderSetup initialSetup;

  @override
  State<LadderSetupScreen> createState() => _LadderSetupScreenState();
}

class _ResultRow {
  _ResultRow(String label, this.count)
    : label = TextEditingController(text: label);

  final TextEditingController label;
  int count;
}

class _LadderSetupScreenState extends State<LadderSetupScreen> {
  final _players = <TextEditingController>[];
  final _results = <_ResultRow>[];

  @override
  void initState() {
    super.initState();
    _players.addAll([
      for (final name in widget.initialSetup.players)
        TextEditingController(text: name),
    ]);
    _results.addAll([
      for (final slot in widget.initialSetup.results)
        _ResultRow(slot.label, slot.count),
    ]);
  }

  @override
  void dispose() {
    for (final controller in _players) {
      controller.dispose();
    }
    for (final row in _results) {
      row.label.dispose();
    }
    super.dispose();
  }

  LadderSetup get _setup => LadderSetup(
    players: [for (final controller in _players) controller.text],
    results: [
      for (final row in _results) ResultSlot(row.label.text, row.count),
    ],
  );

  /// 화면을 다시 그리고 지금 입력을 마지막 입력으로 저장한다.
  void _update([VoidCallback? change]) {
    setState(change ?? () {});
    widget.store.save(_setup);
  }

  /// 지운 칸의 컨트롤러는 그 칸이 화면에서 빠진 다음 프레임에 정리한다.
  void _disposeLater(Iterable<TextEditingController> controllers) {
    final list = List.of(controllers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in list) {
        controller.dispose();
      }
    });
  }

  void _addPlayer() => _update(() => _players.add(TextEditingController()));

  void _removePlayer(int index) {
    final removed = _players[index];
    _update(() => _players.removeAt(index));
    _disposeLater([removed]);
  }

  void _addResult() => _update(() => _results.add(_ResultRow('', 1)));

  void _removeResult(int index) {
    final removed = _results[index];
    _update(() => _results.removeAt(index));
    _disposeLater([removed.label]);
  }

  void _setCount(int index, int count) =>
      _update(() => _results[index].count = count);

  void _fill(List<ResultSlot> slots) {
    final old = List.of(_results);
    _update(() {
      _results
        ..clear()
        ..addAll([
          for (final slot in slots) _ResultRow(slot.label, slot.count),
        ]);
    });
    _disposeLater([for (final row in old) row.label]);
  }

  void _start() {
    final setup = _setup;
    if (!setup.canStart) return;
    FocusScope.of(context).unfocus();
    widget.store.save(setup);
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => LadderScreen(setup: setup)));
  }

  @override
  Widget build(BuildContext context) {
    final setup = _setup;
    final players = _players.length;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: TossColors.bgDeep,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 20,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '사다리 타기',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.4,
                color: TossColors.textPrimary,
                height: 1.05,
              ),
            ),
            Text(
              '이름과 결과를 적어요',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: TossColors.textFaint,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  TossCard(
                    cardKey: const ValueKey('player-card'),
                    child: Column(
                      children: [
                        TossSectionHeader(
                          title: '참가자 $players명',
                          action: TextButton.icon(
                            key: const ValueKey('add-player'),
                            style: TextButton.styleFrom(
                              foregroundColor: TossColors.accent,
                              disabledForegroundColor:
                                  TossColors.textQuaternary,
                            ),
                            onPressed: players < LadderSetup.maxPlayers
                                ? _addPlayer
                                : null,
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('추가'),
                          ),
                        ),
                        for (var i = 0; i < players; i++)
                          Padding(
                            key: ObjectKey(_players[i]),
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TossNameField(
                                    fieldKey: ValueKey('player-$i'),
                                    controller: _players[i],
                                    hint: '${i + 1}번',
                                    icon: Icons.person_outline,
                                    onChanged: (_) => _update(),
                                  ),
                                ),
                                IconButton(
                                  tooltip: '${i + 1}번 빼기',
                                  onPressed: players > LadderSetup.minPlayers
                                      ? () => _removePlayer(i)
                                      : null,
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: players > LadderSetup.minPlayers
                                        ? TossColors.textSecondary
                                        : TossColors.textQuaternary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 칩 카드는 결과 카드와 분리한다.
                  // 결과 카드에 넣으면 제목만 보여도 칩을 찾은 것으로 처리된다.
                  Container(
                    key: const ValueKey('quick-chip-card'),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                      color: TossColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TossColors.border),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _QuickChip(
                          label: '당첨/꽝',
                          onPressed: () => _fill(LadderSetup.winLose(players)),
                        ),
                        _QuickChip(
                          label: '1등~$players등',
                          onPressed: () => _fill(LadderSetup.ranks(players)),
                        ),
                        _QuickChip(
                          label: '순서 1~$players',
                          onPressed: () => _fill(LadderSetup.order(players)),
                        ),
                      ],
                    ),
                  ),
                  TossCard(
                    cardKey: const ValueKey('result-card'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TossSectionHeader(
                          title: '결과',
                          action: TextButton.icon(
                            key: const ValueKey('add-result'),
                            style: TextButton.styleFrom(
                              foregroundColor: TossColors.accent,
                              disabledForegroundColor:
                                  TossColors.textQuaternary,
                            ),
                            onPressed: _results.length < LadderSetup.maxPlayers
                                ? _addResult
                                : null,
                            icon: const Icon(Icons.add),
                            label: const Text('줄 추가'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12, bottom: 8),
                          child: Text(
                            '라벨과 개수를 적어요. 개수를 모두 더하면 참가자 수와 같아야 해요.',
                            style: textTheme.bodySmall?.copyWith(
                              color: TossColors.textFaint,
                              height: 1.4,
                            ),
                          ),
                        ),
                        for (var j = 0; j < _results.length; j++)
                          Padding(
                            key: ObjectKey(_results[j]),
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TossNameField(
                                    fieldKey: ValueKey('result-$j'),
                                    controller: _results[j].label,
                                    hint: '결과 ${j + 1}',
                                    onChanged: (_) => _update(),
                                  ),
                                ),
                                TossCountStepper(
                                  id: '$j',
                                  value: _results[j].count,
                                  min: 1,
                                  max: LadderSetup.maxPlayers,
                                  onChanged: (count) => _setCount(j, count),
                                ),
                                IconButton(
                                  tooltip: '결과 ${j + 1} 지우기',
                                  onPressed: _results.length > 1
                                      ? () => _removeResult(j)
                                      : null,
                                  icon: Icon(
                                    Icons.close,
                                    color: _results.length > 1
                                        ? TossColors.textSecondary
                                        : TossColors.textQuaternary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 광고 배너 (시작 버튼 위) — 계산기 탭과 같은 배치.
            const AdaptiveBanner(),
            _StartBar(setup: setup, onStart: _start),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      labelStyle: const TextStyle(
        color: TossColors.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      backgroundColor: TossColors.surfaceElevated,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onPressed: onPressed,
    );
  }
}

class _StartBar extends StatelessWidget {
  const _StartBar({required this.setup, required this.onStart});

  final LadderSetup setup;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final remaining = setup.remaining;
    final players = setup.players.length;
    final ready = setup.canStart;
    final message = remaining > 0
        ? '남은 자리 $remaining'
        : remaining < 0
        ? '${-remaining}자리 넘침 — 개수를 줄여 주세요'
        : '$players명 · $players자리 준비 완료';

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: TossColors.surface,
        border: Border(top: BorderSide(color: TossColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: ready
                    ? TossColors.accentSoft
                    : TossColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  // 글자는 진한 청록(#17A58F). 네온(#3DE0C8)은 테두리로만 둔다.
                  color: ready ? TossColors.accentNeon : TossColors.danger,
                ),
              ),
              child: Text(
                message,
                key: const ValueKey('status'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ready ? TossColors.accent : TossColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                key: const ValueKey('start'),
                style: FilledButton.styleFrom(
                  backgroundColor: TossColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: TossColors.surfaceElevated,
                  disabledForegroundColor: TossColors.textQuaternary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: ready ? onStart : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  '사다리 타기',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
