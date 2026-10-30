import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/mini_app_scaffold.dart';
import 'calculator_controller.dart';

/// 사칙연산 미니앱. 키패드는 배너 아래 [MiniAppScaffold.bottom] 에 둔다.
class BasicCalculatorScreen extends StatelessWidget {
  const BasicCalculatorScreen({super.key, required this.controller});

  final BasicCalculatorController controller;

  static const _rows = <List<String>>[
    ['AC', '⌫', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['00', '0', '.', '='],
  ];

  void _onKey(String key) {
    HapticFeedback.lightImpact();
    controller.press(key);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MiniAppScaffold(
          title: '계산기',
          subtitle: '간단한 계산을 바로 해요',
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      controller.expression,
                      key: const ValueKey('calc-expression'),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: TossColors.textFaint,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.display,
                      key: const ValueKey('calc-display'),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: TossColors.textPrimary,
                        height: 1.05,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottom: _keypad(),
        );
      },
    );
  }

  Widget _keypad() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _rows)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    for (final label in row)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _CalcKey(
                            label: label,
                            onTap: () => _onKey(label),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CalcKey extends StatelessWidget {
  const _CalcKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  bool get _equals => label == '=';

  bool get _operator {
    return label == '+' ||
        label == '−' ||
        label == '×' ||
        label == '÷' ||
        label == '%';
  }

  @override
  Widget build(BuildContext context) {
    final foreground = _equals
        ? Colors.white
        : _operator
        ? TossColors.accent
        : TossColors.textPrimary;
    return Material(
      key: ValueKey('calc-$label'),
      color: _equals ? TossColors.accent : TossColors.keyFill,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: TossColors.splashLight,
        highlightColor: TossColors.highlightLight,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: label.length > 1 ? 18 : 22,
              fontWeight: _equals ? FontWeight.w800 : FontWeight.w700,
              color: foreground,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
