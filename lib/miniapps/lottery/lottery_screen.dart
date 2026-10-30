import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/mini_app_scaffold.dart';
import '../../widgets/toss_widgets.dart';
import 'lottery_controller.dart';

/// 제비뽑기 미니앱. 제목 「제비뽑기」.
class LotteryScreen extends StatelessWidget {
  const LotteryScreen({super.key, required this.controller});

  final LotteryController controller;

  void _reveal(int index) {
    if (controller.revealed.contains(index)) return;
    final result = controller.reveal(index);
    if (result == null) return;
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final board = controller.board;
        return MiniAppScaffold(
          title: '제비뽑기',
          subtitle: '당첨 제비를 하나씩 뽑아요',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              TossCard(
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
              ),
              if (board != null)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return _TicketGrid(
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
    widget.controller.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final board = controller.board;
    return TossBottomButton(
      buttonKey: const ValueKey('shuffle'),
      label: board == null ? '섞기' : '다시 섞기',
      onPressed: _shuffle,
      status: Text(
        '남은 제비 ${controller.remaining}장 · 남은 당첨 ${controller.remainingWinners}장',
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
    required this.board,
    required this.revealed,
    required this.onReveal,
    required this.width,
  });

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
    required this.win,
    required this.open,
    required this.onTap,
  });

  final int index;
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
      label = '당첨';
    } else {
      background = TossColors.surfaceElevated;
      foreground = TossColors.textFaint;
      label = '꽝';
    }

    return Material(
      key: ValueKey('ticket-$index'),
      color: background,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
