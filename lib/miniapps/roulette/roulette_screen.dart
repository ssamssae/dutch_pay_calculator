import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/mini_app_scaffold.dart';
import '../../widgets/toss_widgets.dart';
import 'roulette_controller.dart';
import 'roulette_wheel.dart';

const _spinDuration = Duration(milliseconds: 3500);

const _dialogTitleStyle = TextStyle(
  fontWeight: FontWeight.w800,
  fontSize: 18,
  letterSpacing: -0.3,
  color: TossColors.textPrimary,
);

const _dialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(20)),
);

/// 룰렛 미니앱. 제목 「룰렛」, 돌리기 3500ms. 목록 카드에서 저장한 목록을
/// 골라 쓰고, 새 목록·이름 바꾸기·지우기를 한다 (T-261106-018).
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

  /// 고른 목록의 이름을 바꾸는 창. 저장하면 컨트롤러가 다듬어 저장한다.
  Future<void> _renamePreset() async {
    final controller = widget.controller;
    final index = controller.currentPreset;
    final editor = TextEditingController(text: controller.presetNames[index]);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TossColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape,
        title: const Text('목록 이름', style: _dialogTitleStyle),
        content: TextField(
          key: const ValueKey('roulette-preset-name'),
          controller: editor,
          autofocus: true,
          maxLength: RouletteController.maxPresetNameLength,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            color: TossColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            hintText: '예: 점심, 누가 쏠까',
            hintStyle: TextStyle(color: TossColors.textQuaternary),
            counterText: '',
            filled: true,
            fillColor: TossColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: TossColors.accent, width: 1.5),
            ),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(
            key: const ValueKey('roulette-preset-name-cancel'),
            style: TextButton.styleFrom(
              foregroundColor: TossColors.textSecondary,
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const ValueKey('roulette-preset-name-save'),
            style: FilledButton.styleFrom(
              backgroundColor: TossColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (saved == true) {
      controller.renamePreset(index, editor.text);
    }
    // 창이 닫히는 동안에도 입력칸이 쓰므로 다음 프레임에 정리한다.
    WidgetsBinding.instance.addPostFrameCallback((_) => editor.dispose());
  }

  /// 고른 목록을 지우기 전에 한 번 묻는다.
  Future<void> _removePreset() async {
    final controller = widget.controller;
    final index = controller.currentPreset;
    final name = controller.presetNames[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TossColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape,
        title: const Text('목록 지우기', style: _dialogTitleStyle),
        content: Text(
          '「$name」 목록과 그 항목을 지울까요?',
          style: const TextStyle(
            color: TossColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('roulette-preset-remove-cancel'),
            style: TextButton.styleFrom(
              foregroundColor: TossColors.textSecondary,
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const ValueKey('roulette-preset-remove-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: TossColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('지우기'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      controller.removePreset(index);
    }
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
                      cardKey: const ValueKey('roulette-presets'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TossSectionHeader(
                            title: '목록',
                            action: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  key: const ValueKey('roulette-preset-rename'),
                                  tooltip: '목록 이름 바꾸기',
                                  onPressed: spinning ? null : _renamePreset,
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  key: const ValueKey('roulette-preset-remove'),
                                  tooltip: '목록 지우기',
                                  onPressed: controller.canRemovePreset
                                      ? _removePreset
                                      : null,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                                IconButton(
                                  key: const ValueKey('roulette-preset-add'),
                                  tooltip: '새 목록',
                                  onPressed: controller.canAddPreset
                                      ? controller.addPreset
                                      : null,
                                  icon: const Icon(Icons.playlist_add),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 12, 10),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (
                                  var i = 0;
                                  i < controller.presetNames.length;
                                  i++
                                )
                                  _presetChip(controller, i, spinning),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

  /// 저장한 목록 하나. 고른 목록은 초록, 돌리는 동안은 꺼진다.
  Widget _presetChip(RouletteController controller, int index, bool spinning) {
    final selected = index == controller.currentPreset;
    return ChoiceChip(
      key: ValueKey('roulette-preset-$index'),
      label: Text(controller.presetNames[index]),
      selected: selected,
      showCheckmark: false,
      onSelected: spinning ? null : (_) => controller.selectPreset(index),
      selectedColor: TossColors.accentSoft,
      backgroundColor: TossColors.surfaceElevated,
      side: BorderSide(
        color: selected ? TossColors.accentBorder : TossColors.border,
      ),
      labelStyle: TextStyle(
        color: selected ? TossColors.accent : TossColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
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
