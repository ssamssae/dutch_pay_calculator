import 'package:dutch_pay_calculator/miniapps/calculator/calculator_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void check(
    String name,
    List<String> keys,
    String display,
    String expression,
  ) {
    test(name, () {
      final controller = BasicCalculatorController();
      addTearDown(controller.dispose);
      for (final key in keys) {
        controller.press(key);
      }
      expect(controller.display, display, reason: 'display');
      expect(controller.expression, expression, reason: 'expression');
    });
  }

  // 각 줄 = 새 컨트롤러에 키를 차례로 누른 뒤 (display, expression)
  check('연산자 뒤에는 새 수가 크게', ['1', '2', '+', '3'], '3', '12 +');
  check('등호는 식과 결과를 남긴다', ['1', '2', '+', '3', '='], '15', '12 + 3 =');
  check(
    '빼기 뒤 퍼센트',
    ['5', '0', '0', '0', '0', '−', '1', '0', '%', '='],
    '45,000',
    '50,000 − 10% =',
  );
  check(
    '퍼센트 입력 중에는 결과에 %가 붙는다',
    ['5', '0', '0', '0', '0', '−', '1', '0', '%'],
    '10%',
    '50,000 −',
  );
  check(
    '등호 뒤 연산자는 결과에 이어 붙는다',
    ['1', '2', '+', '3', '=', '+', '5', '='],
    '20',
    '15 + 5 =',
  );
  check('등호 뒤 숫자는 새 계산', ['1', '=', '7'], '7', '');
  check('연산자 연속은 바꿔 끼움', ['5', '+', '×'], '5', '5 ×');
  check('연산자로 시작하면 0 부터', ['×'], '0', '0 ×');
  check('소수점은 한 번', ['.', '.'], '0.', '');
  check('00 은 0 을 유지', ['00'], '0', '');
  check('00 은 수 뒤에 두 자리', ['1', '00'], '100', '');
  test('15자리까지', () {
    final controller = BasicCalculatorController();
    addTearDown(controller.dispose);
    for (var i = 0; i < 16; i++) {
      controller.press('1');
    }
    expect(controller.display, '111,111,111,111,111');
    expect(controller.expression, '');
  });
  check('한 자리 지우기', ['1', '2', '3', '⌫'], '12', '');
  check('수가 없으면 연산자를 지움', ['5', '+', '⌫'], '5', '');
  check('0으로 나누면 안내', ['5', '÷', '0', '='], '0으로 나눌 수 없어요', '5 ÷ 0 =');
  check('오류 뒤 키는 새로 시작', ['5', '÷', '0', '=', '3'], '3', '');
  check('등호 연타는 그대로', ['2', '+', '2', '=', '='], '4', '2 + 2 =');
  check('세 자리 쉼표', ['1', '2', '3', '4'], '1,234', '');
  check('AC', ['AC'], '0', '');
  test('AC 는 입력 중이던 식을 지운다', () {
    final controller = BasicCalculatorController();
    addTearDown(controller.dispose);
    for (final key in ['1', '2', '+', '3']) {
      controller.press(key);
    }
    controller.press('AC');
    expect(controller.display, '0');
    expect(controller.expression, '');
  });
}
