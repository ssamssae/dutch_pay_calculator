import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _fieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(14)),
  borderSide: BorderSide(color: TossColors.border),
);

/// 흰 바탕 · 모서리 20 · 얇은 테두리 카드.
class TossCard extends StatelessWidget {
  const TossCard({super.key, this.cardKey, required this.child});

  /// 안쪽 Container 에 붙는 키.
  final Key? cardKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 0, 0, 2),
      decoration: BoxDecoration(
        color: TossColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TossColors.border),
      ),
      child: child,
    );
  }
}

/// 카드 맨 위 제목 줄. 오른쪽에 버튼 하나를 둔다.
class TossSectionHeader extends StatelessWidget {
  const TossSectionHeader({
    super.key,
    required this.title,
    required this.action,
  });

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: TossColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          action,
        ],
      ),
    );
  }
}

/// 눌러서 들어가면 글자 전체가 선택돼 바로 덮어쓸 수 있는 입력칸.
class TossNameField extends StatefulWidget {
  const TossNameField({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.hint,
    this.icon,
    this.maxLength = 20,
    this.enabled = true,
    required this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String hint;

  /// 칸 왼쪽 아이콘. 좁은 줄에서는 글자 자리를 위해 뺀다.
  final IconData? icon;
  final int maxLength;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  State<TossNameField> createState() => _TossNameFieldState();
}

class _TossNameFieldState extends State<TossNameField> {
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
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      maxLength: widget.maxLength,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        color: TossColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          color: TossColors.textQuaternary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: widget.icon == null
            ? null
            : Icon(widget.icon, color: TossColors.textFaint, size: 20),
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: TossColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: _fieldBorder,
        enabledBorder: _fieldBorder,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: TossColors.accent, width: 1.5),
        ),
      ),
    );
  }
}

/// − 값 + 개수 조절. 키는 `minus-$id` · `count-$id` · `plus-$id`.
class TossCountStepper extends StatelessWidget {
  const TossCountStepper({
    super.key,
    required this.id,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.format,
    this.decreaseTooltip = '개수 줄이기',
    this.increaseTooltip = '개수 늘리기',
  });

  final String id;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  /// 가운데 글자. 없으면 `×값`.
  final String Function(int)? format;
  final String decreaseTooltip;
  final String increaseTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: ValueKey('minus-$id'),
          tooltip: decreaseTooltip,
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 36,
          child: Text(
            format?.call(value) ?? '×$value',
            key: ValueKey('count-$id'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TossColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        IconButton(
          key: ValueKey('plus-$id'),
          tooltip: increaseTooltip,
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// 화면 맨 아래 띠: 위 구분선 · 선택 상태 줄 · 48 높이 큰 버튼.
class TossBottomButton extends StatelessWidget {
  const TossBottomButton({
    super.key,
    required this.buttonKey,
    required this.label,
    this.icon,
    this.onPressed,
    this.status,
  });

  final Key buttonKey;
  final String label;
  final IconData? icon;

  /// null 이면 버튼이 꺼진다.
  final VoidCallback? onPressed;

  /// 버튼 위에 놓는 상태 줄.
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: TossColors.accent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: TossColors.surfaceElevated,
      disabledForegroundColor: TossColors.textQuaternary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
    final text = Text(
      label,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );

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
            if (status case final status?) ...[
              status,
              const SizedBox(height: 6),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: icon == null
                  ? FilledButton(
                      key: buttonKey,
                      style: style,
                      onPressed: onPressed,
                      child: text,
                    )
                  : FilledButton.icon(
                      key: buttonKey,
                      style: style,
                      onPressed: onPressed,
                      icon: Icon(icon),
                      label: text,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
