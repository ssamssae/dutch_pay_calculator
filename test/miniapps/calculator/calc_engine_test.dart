import 'package:dutch_pay_calculator/miniapps/calculator/calc_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// 공백으로 나눈 식을 토큰으로 만든다. `10%` 는 percent 수다.
List<CalcToken> t(String raw) {
  return [for (final part in raw.split(' ')) _token(part)];
}

CalcToken _token(String part) {
  const ops = <String, CalcOp>{
    '+': CalcOp.add,
    '−': CalcOp.subtract,
    '×': CalcOp.multiply,
    '÷': CalcOp.divide,
  };
  final op = ops[part];
  if (op != null) return OpToken(op);
  final percent = part.endsWith('%');
  final text = percent ? part.substring(0, part.length - 1) : part;
  return NumberToken(text, percent: percent);
}

String show(List<CalcToken> tokens) {
  final outcome = evaluateTokens(tokens);
  return switch (outcome) {
    CalcNumber(:final display) => display,
    CalcDivideByZero() => '0으로 나눌 수 없어요',
  };
}

void main() {
  test('사칙연산 · 퍼센트 · 반올림 · 0으로 나누기', () {
    expect(show(t('0.1 + 0.2')), '0.3');
    expect(show(t('2 + 3 × 4')), '14');
    expect(show(t('50000 − 10%')), '45,000');
    expect(show(t('100 + 20 + 10%')), '132');
    expect(show(t('2 × 50 + 10%')), '110');
    expect(show(t('200 × 10%')), '20');
    expect(show(t('10%')), '0.1');
    expect(show(t('1 ÷ 3')), '0.3333333333');
    expect(show(t('2 ÷ 3')), '0.6666666667');
    expect(show(t('7 − 10')), '-3');
    expect(show(t('1234567 × 1000')), '1,234,567,000');
    expect(evaluateTokens(t('5 ÷ 0')), isA<CalcDivideByZero>());
  });
}
