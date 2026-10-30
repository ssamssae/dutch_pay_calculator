import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/mini_app_scaffold.dart';
import '../../widgets/toss_widgets.dart';
import 'roulette_controller.dart';
import 'roulette_wheel.dart';

const _spinDuration = Duration(milliseconds: 3500);

/// 룰렛 미니앱. 제목 「룰렛」, 돌리기 3500ms.
class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key, required this.controller});

  final RouletteController controller;

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  final List<TextEditingController> _editors = [];
  final List<TextEditingController> _retired = [];
  double _turns = 0;
  double _from = 0;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncEditors);
    _syncEditors();
    final result = widget.controller.lastResult;
    final count = widget.controller.items.length;
    if (result != null && result >= 0 && result < count) {
      _turns = RouletteWheel.targetTurns(
        currentTurns: 0,
        index: result,
        count: count,
        extraTurns: 0,
      );
    }
    _spin = AnimationController(vsync: this, duration: _spinDuration)
      ..addListener(_onTick)
      ..addStatusListener(_onSpinStatus);
  }

  @override
  void dispose() {
    _spin
      ..removeListener(_onTick)
      ..removeStatusListener(_onSpinStatus)
      ..dispose();
    widget.controller.removeListener(_syncEditors);
    if (widget.controller.spinning) {
      widget.controller.finishSpin();
    }
    for (final editor in _editors) {
      editor.dispose();
    }
    for (final editor in _retired) {
      editor.dispose();
    }
    super.dispose();
  }

  void _syncEditors() {
    final items = widget.controller.items;
    while (_editors.length < items.length) {
      _editors.add(TextEditingController(text: items[_editors.length]));
    }
    while (_editors.length > items.length) {
      _retired.add(_editors.removeLast());
    }
    for (var i = 0; i < items.length; i++) {
      if (_editors[i].text != items[i]) {
        _editors[i].text = items[i];
      }
    }
  }

  void _onTick() {
    final t = Curves.decelerate.transform(_spin.value);
    setState(() {
      _turns = _from + (_to - _from) * t;
    });
  }

  void _onSpinStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    widget.controller.finishSpin();
    HapticFeedback.mediumImpact();
  }

  void _spinWheel() {
    final controller = widget.controller;
    final index = controller.startSpin();
    if (index < 0) return;
    _from = _turns;
    _to = RouletteWheel.targetTurns(
      currentTurns: _turns,
      index: index,
      count: controller.items.length,
    );
    _spin.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final spinning = controller.spinning;
        final result = controller.lastResult;
        final resultLabel =
            !spinning &&
                result != null &&
                result >= 0 &&
                result < controller.labels.length
            ? controller.labels[result]
            : null;
        final canAdd =
            !spinning && controller.items.length < RouletteController.maxItems;

        return MiniAppScaffold(
          title: '룰렛',
          subtitle: '누가 쏠지 돌려서 정해요',
          body: LayoutBuilder(
            builder: (context, constraints) {
              final inner = max(constraints.maxWidth - 32, 0.0);
              final side = min(inner, 280.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: RouletteWheel(
                          labels: controller.labels,
                          turns: _turns,
                        ),
                      ),
                    ),
                    if (resultLabel != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        resultLabel,
                        key: const ValueKey('roulette-result'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: TossColors.accent,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TossCard(
                      child: Column(
                        children: [
                          TossSectionHeader(
                            title: '항목',
                            action: IconButton(
                              key: const ValueKey('roulette-add'),
                              tooltip: '항목 추가',
                              onPressed: canAdd ? controller.addItem : null,
                              icon: const Icon(Icons.add),
                            ),
                          ),
                          for (var i = 0; i < controller.items.length; i++)
                            _itemRow(controller, i, spinning),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          bottom: TossBottomButton(
            buttonKey: const ValueKey('spin'),
            label: '돌리기',
            onPressed: spinning ? null : _spinWheel,
          ),
        );
      },
    );
  }

  Widget _itemRow(RouletteController controller, int index, bool spinning) {
    final canRemove =
        !spinning && controller.items.length > RouletteController.minItems;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TossNameField(
              fieldKey: ValueKey('roulette-item-$index'),
              controller: _editors[index],
              hint: '항목 ${index + 1}',
              maxLength: RouletteController.maxLength,
              enabled: !spinning,
              onChanged: (text) => controller.renameItem(index, text),
            ),
          ),
          IconButton(
            key: ValueKey('roulette-remove-$index'),
            tooltip: '항목 지우기',
            onPressed: canRemove ? () => controller.removeItem(index) : null,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
