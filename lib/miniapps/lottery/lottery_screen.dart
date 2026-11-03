import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/mini_app_scaffold.dart';
import '../../widgets/toss_widgets.dart';
import 'lottery_celebration.dart';
import 'lottery_controller.dart';

/// 제비뽑기 미니앱. 제목 「제비뽑기」.
///
/// 방식 두 가지: 「당첨·꽝」(전체·당첨 장수) · 「직접 쓰기」(결과 글 × 장수,
/// 예: 12호차 ×1). 축하할 제비를 열면 「축하합니다!」 창과 꽃가루가 터진다.
class LotteryScreen extends StatefulWidget {
  const LotteryScreen({super.key, required this.controller});

  final LotteryController controller;

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends State<LotteryScreen> {
  /// 직접 쓰기 결과 줄마다 입력칸 하나. 줄 순서와 같다.
  final List<TextEditingController> _editors = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncEditors);
    _syncEditors();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncEditors);
    for (final editor in _editors) {
      editor.dispose();
    }
    super.dispose();
  }

  /// 줄 수와 글을 컨트롤러에 맞춘다. 지금 치는 글은 저장값과 같아 그대로다.
  void _syncEditors() {
    final items = widget.controller.items;
    while (_editors.length < items.length) {
      _editors.add(TextEditingController(text: items[_editors.length].label));
    }
    while (_editors.length > items.length) {
      _disposeLater(_editors.removeLast());
    }
    for (var i = 0; i < items.length; i++) {
      if (_editors[i].text != items[i].label) {
        _editors[i].text = items[i].label;
      }
    }
  }

  /// 지운 줄의 입력칸은 그 줄이 화면에서 빠진 다음 프레임에 정리한다.
  void _disposeLater(TextEditingController editor) {
    WidgetsBinding.instance.addPostFrameCallback((_) => editor.dispose());
  }

  void _removeItem(int index) {
    final controller = widget.controller;
    if (controller.items.length <= 1) return;
    if (index < 0 || index >= _editors.length) return;
    _disposeLater(_editors.removeAt(index));
    controller.removeItem(index);
  }

  void _reveal(int index) {
    final controller = widget.controller;
    if (controller.revealed.contains(index)) return;
    final win = controller.reveal(index);
    if (win == null) return;
    HapticFeedback.mediumImpact();
    final faces = controller.faces;
    if (!win || faces == null) return;
    showLotteryCelebration(context, faces[index]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final board = controller.board;
        final faces = controller.faces;
        final custom = controller.mode == LotteryMode.custom;
        return MiniAppScaffold(
          title: '제비뽑기',
          subtitle: custom ? '적은 결과를 하나씩 뽑아요' : '당첨 제비를 하나씩 뽑아요',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _ModeSwitch(
                mode: controller.mode,
                onChanged: (mode) {
                  FocusScope.of(context).unfocus();
                  controller.setMode(mode);
                },
              ),
              if (custom) _customCard(controller) else _winLoseCard(controller),
              if (board != null && faces != null)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return _TicketGrid(
                      faces: faces,
                      board: board,
                      revealed: controller.revealed,
                      onReveal: _reveal,
                      width: constraints.maxWidth,
                    );
                  },
                ),
            ],
          ),
          bottom: _ShuffleButton(controller: controller),
        );
      },
    );
  }

  Widget _winLoseCard(LotteryController controller) {
    return TossCard(
      child: Column(
        children: [
          TossSectionHeader(
            title: '전체',
            action: TossCountStepper(
              id: 'total',
              value: controller.total,
              min: LotteryController.minTotal,
              max: LotteryController.maxTotal,
              onChanged: controller.setTotal,
              format: (v) => '$v장',
              decreaseTooltip: '장수 줄이기',
              increaseTooltip: '장수 늘리기',
            ),
          ),
          TossSectionHeader(
            title: '당첨',
            action: TossCountStepper(
              id: 'winners',
              value: controller.winners,
              min: 1,
              max: controller.total - 1,
              onChanged: controller.setWinners,
              format: (v) => '당첨 $v장',
              decreaseTooltip: '당첨 줄이기',
              increaseTooltip: '당첨 늘리기',
            ),
          ),
        ],
      ),
    );
  }

  Widget _customCard(LotteryController controller) {
    final items = controller.items;
    final canAdd = controller.itemTotal < LotteryController.maxTotal;
    return TossCard(
      cardKey: const ValueKey('lottery-custom-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TossSectionHeader(
            title: '결과 ${controller.itemTotal}장',
            action: TextButton.icon(
              key: const ValueKey('lottery-add-item'),
              style: TextButton.styleFrom(
                foregroundColor: TossColors.accent,
                disabledForegroundColor: TossColors.textQuaternary,
              ),
              onPressed: canAdd ? controller.addItem : null,
              icon: const Icon(Icons.add),
              label: const Text('줄 추가'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 8),
            child: Text(
              '뽑을 결과와 장수를 적어요. 예: 12호차 ×1',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TossColors.textFaint,
                height: 1.4,
              ),
            ),
          ),
          for (var i = 0; i < items.length; i++)
            Padding(
              key: ObjectKey(_editors[i]),
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TossNameField(
                      fieldKey: ValueKey('lottery-item-$i'),
                      controller: _editors[i],
                      hint: '결과 ${i + 1}',
                      maxLength: LotteryController.maxLabelLength,
                      onChanged: (text) => controller.renameItem(i, text),
                    ),
                  ),
                  TossCountStepper(
                    id: 'item-$i',
                    value: items[i].count,
                    min: 1,
                    max: controller.maxCountFor(i),
                    onChanged: (count) => controller.setItemCount(i, count),
                    decreaseTooltip: '결과 ${i + 1} 장수 줄이기',
                    increaseTooltip: '결과 ${i + 1} 장수 늘리기',
                  ),
                  IconButton(
                    key: ValueKey('lottery-remove-item-$i'),
                    tooltip: '결과 ${i + 1} 지우기',
                    onPressed: items.length > 1 ? () => _removeItem(i) : null,
                    icon: Icon(
                      Icons.close,
                      color: items.length > 1
                          ? TossColors.textSecondary
                          : TossColors.textQuaternary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 방식 고르기: 「당첨·꽝」 | 「직접 쓰기」.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final LotteryMode mode;
  final ValueChanged<LotteryMode> onChanged;

  static const _labels = {
    LotteryMode.winLose: '당첨·꽝',
    LotteryMode.custom: '직접 쓰기',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('lottery-mode'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TossColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final value in LotteryMode.values)
            Expanded(child: _segment(value)),
        ],
      ),
    );
  }

  Widget _segment(LotteryMode value) {
    final selected = value == mode;
    return Semantics(
      selected: selected,
      child: Material(
        key: ValueKey('lottery-mode-${value.name}'),
        color: selected ? TossColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected ? null : () => onChanged(value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  _labels[value]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? TossColors.textPrimary
                        : TossColors.textFaint,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 「섞기」 버튼. 500ms 안에는 한 번만 섞는다.
class _ShuffleButton extends StatefulWidget {
  const _ShuffleButton({required this.controller});

  final LotteryController controller;

  @override
  State<_ShuffleButton> createState() => _ShuffleButtonState();
}

class _ShuffleButtonState extends State<_ShuffleButton> {
  /// 연타로 판이 두 번 바뀌지 않게 막는 시간.
  static const _shuffleCooldown = Duration(milliseconds: 500);

  Timer? _shuffleLock;

  @override
  void dispose() {
    _shuffleLock?.cancel();
    super.dispose();
  }

  void _shuffle() {
    if (_shuffleLock?.isActive ?? false) return;
    _shuffleLock = Timer(_shuffleCooldown, () {});
    FocusScope.of(context).unfocus();
    widget.controller.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final board = controller.board;
    final ready = controller.canShuffle;
    final String status;
    if (!ready) {
      status = '결과를 2장 이상 적어 주세요';
    } else if (controller.mode == LotteryMode.custom) {
      status = '남은 제비 ${controller.remaining}장';
    } else {
      status =
          '남은 제비 ${controller.remaining}장 · 남은 당첨 ${controller.remainingWinners}장';
    }
    return TossBottomButton(
      buttonKey: const ValueKey('shuffle'),
      label: board == null ? '섞기' : '다시 섞기',
      onPressed: ready ? _shuffle : null,
      status: Text(
        status,
        key: const ValueKey('lottery-status'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: TossColors.textSecondary,
        ),
      ),
    );
  }
}

class _TicketGrid extends StatelessWidget {
  const _TicketGrid({
    required this.faces,
    required this.board,
    required this.revealed,
    required this.onReveal,
    required this.width,
  });

  final List<String> faces;
  final List<bool> board;
  final Set<int> revealed;
  final ValueChanged<int> onReveal;
  final double width;

  @override
  Widget build(BuildContext context) {
    final columns = (width / 88).floor().clamp(2, 5);
    final tileWidth = (width - 8 * (columns - 1)) / columns;
    final tileHeight = max(48.0, min(tileWidth, 104.0));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < board.length; i++)
          SizedBox(
            width: tileWidth,
            height: tileHeight,
            child: _Ticket(
              index: i,
              face: faces[i],
              win: board[i],
              open: revealed.contains(i),
              onTap: () => onReveal(i),
            ),
          ),
      ],
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({
    required this.index,
    required this.face,
    required this.win,
    required this.open,
    required this.onTap,
  });

  final int index;
  final String face;
  final bool win;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final String label;
    if (!open) {
      background = TossColors.accentSoft;
      foreground = TossColors.accent;
      label = '제비';
    } else if (win) {
      background = TossColors.accent;
      foreground = Colors.white;
      label = face;
    } else {
      background = TossColors.surfaceElevated;
      foreground = TossColors.textFaint;
      label = face;
    }

    return Material(
      key: ValueKey('ticket-$index'),
      color: background,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
