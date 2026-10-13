import 'package:flutter/material.dart';

import '../ladder/ladder_setup.dart';
import '../ladder/ladder_setup_store.dart';
import '../services/ads_service.dart';
import '../theme/app_theme.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('사다리 타기')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _SectionHeader(
                    title: '참가자 $players명',
                    action: TextButton.icon(
                      key: const ValueKey('add-player'),
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
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SelectAllField(
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
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: '결과',
                    action: TextButton.icon(
                      key: const ValueKey('add-result'),
                      onPressed: _results.length < LadderSetup.maxPlayers
                          ? _addResult
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('줄 추가'),
                    ),
                  ),
                  Text(
                    '라벨과 개수를 적어요. 개수를 모두 더하면 참가자 수와 같아야 해요.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        label: const Text('당첨/꽝'),
                        onPressed: () => _fill(LadderSetup.winLose(players)),
                      ),
                      ActionChip(
                        label: Text('1등~$players등'),
                        onPressed: () => _fill(LadderSetup.ranks(players)),
                      ),
                      ActionChip(
                        label: Text('순서 1~$players'),
                        onPressed: () => _fill(LadderSetup.order(players)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var j = 0; j < _results.length; j++)
                    Padding(
                      key: ObjectKey(_results[j]),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SelectAllField(
                              fieldKey: ValueKey('result-$j'),
                              controller: _results[j].label,
                              hint: '결과 ${j + 1}',
                              onChanged: (_) => _update(),
                            ),
                          ),
                          _CountStepper(
                            index: j,
                            count: _results[j].count,
                            onChanged: (count) => _setCount(j, count),
                          ),
                          IconButton(
                            tooltip: '결과 ${j + 1} 지우기',
                            onPressed: _results.length > 1
                                ? () => _removeResult(j)
                                : null,
                            icon: const Icon(Icons.close),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          action,
        ],
      ),
    );
  }
}

/// 눌러서 들어가면 글자 전체가 선택돼 바로 덮어쓸 수 있는 입력칸.
class _SelectAllField extends StatefulWidget {
  const _SelectAllField({
    required this.fieldKey,
    required this.controller,
    required this.hint,
    this.icon,
    required this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String hint;

  /// 칸 왼쪽 아이콘. 좁은 결과 줄에서는 글자 자리를 위해 뺀다.
  final IconData? icon;
  final ValueChanged<String> onChanged;

  @override
  State<_SelectAllField> createState() => _SelectAllFieldState();
}

class _SelectAllFieldState extends State<_SelectAllField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) return;
    // 탭한 자리에 커서가 놓인 뒤 다음 프레임에 전체를 선택한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focus.hasFocus) return;
      final controller = widget.controller;
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: widget.fieldKey,
      controller: widget.controller,
      focusNode: _focus,
      onChanged: widget.onChanged,
      maxLength: 20,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        counterText: '',
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.index,
    required this.count,
    required this.onChanged,
  });

  final int index;
  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: ValueKey('minus-$index'),
          tooltip: '개수 줄이기',
          onPressed: count > 1 ? () => onChanged(count - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '×$count',
            key: ValueKey('count-$index'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          key: ValueKey('plus-$index'),
          tooltip: '개수 늘리기',
          onPressed: count < LadderSetup.maxPlayers
              ? () => onChanged(count + 1)
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _StartBar extends StatelessWidget {
  const _StartBar({required this.setup, required this.onStart});

  final LadderSetup setup;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final remaining = setup.remaining;
    final players = setup.players.length;
    final message = remaining > 0
        ? '남은 자리 $remaining'
        : remaining < 0
        ? '${-remaining}자리 넘침 — 개수를 줄여 주세요'
        : '$players명 · $players자리 준비 완료';

    return Material(
      color: DarkColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              key: const ValueKey('status'),
              style: textTheme.bodyMedium?.copyWith(
                color: setup.canStart ? scheme.primary : scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                key: const ValueKey('start'),
                onPressed: setup.canStart ? onStart : null,
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
