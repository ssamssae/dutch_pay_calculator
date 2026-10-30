/// 계산기 사칙연산. 소수 오차 없이 분수로 계산한다.
enum CalcOp { add, subtract, multiply, divide }

sealed class CalcToken {
  const CalcToken();
}

/// [text] 는 쉼표 없는 수. [percent] 가 켜지면 `%` 수다.
class NumberToken extends CalcToken {
  const NumberToken(this.text, {this.percent = false});

  final String text;
  final bool percent;
}

class OpToken extends CalcToken {
  const OpToken(this.op);

  final CalcOp op;
}

sealed class CalcOutcome {
  const CalcOutcome();
}

class CalcNumber extends CalcOutcome {
  const CalcNumber(this.display);

  final String display;
}

class CalcDivideByZero extends CalcOutcome {
  const CalcDivideByZero();
}

/// [raw] 의 정수부에 세 자리 쉼표를 붙인다. 부호 · 소수 · 끝의 `.` 은 유지한다.
String formatCalcText(String raw) {
  if (raw.isEmpty) return raw;
  var body = raw;
  var sign = '';
  if (body.startsWith('-')) {
    sign = '-';
    body = body.substring(1);
  } else if (body.startsWith('+')) {
    body = body.substring(1);
  }
  final trailingDot = body.endsWith('.');
  if (trailingDot) body = body.substring(0, body.length - 1);
  final parts = body.split('.');
  var intPart = parts[0].isEmpty ? '0' : parts[0];
  intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (intPart.isEmpty) intPart = '0';
  final grouped = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) grouped.write(',');
    grouped.write(intPart[i]);
  }
  final fraction = parts.length > 1 ? '.${parts[1]}' : (trailingDot ? '.' : '');
  return '$sign$grouped$fraction';
}

/// × ÷ 를 + − 보다 먼저 계산한다.
///
/// `%`: + − 뒤는 (그 앞까지 계산한 값) × b ÷ 100, × ÷ 뒤와 맨 앞은 b ÷ 100.
/// 결과는 소수 10자리에서 반올림하고 끝의 0 은 뺀다.
CalcOutcome evaluateTokens(List<CalcToken> tokens) {
  if (tokens.isEmpty) return const CalcNumber('0');
  final list = tokens.last is OpToken
      ? tokens.sublist(0, tokens.length - 1)
      : tokens;
  if (list.isEmpty) return const CalcNumber('0');

  _Frac? acc;
  CalcOp? addOp;
  _Frac? term;
  CalcOp? mulOp;

  void commitTerm() {
    final value = term ?? _Frac.zero;
    if (acc == null || addOp == null) {
      acc = value;
    } else if (addOp == CalcOp.add) {
      acc = acc! + value;
    } else {
      acc = acc! - value;
    }
    term = null;
  }

  for (final token in list) {
    if (token is OpToken) {
      if (token.op == CalcOp.add || token.op == CalcOp.subtract) {
        commitTerm();
        addOp = token.op;
        mulOp = null;
      } else {
        mulOp = token.op;
      }
      continue;
    }
    if (token is! NumberToken) continue;
    final parsed = _Frac.parse(token.text);
    final _Frac value;
    if (!token.percent) {
      value = parsed;
    } else if (mulOp == CalcOp.multiply || mulOp == CalcOp.divide) {
      value = parsed / _Frac.hundred;
    } else if (addOp == null && term == null && acc == null) {
      value = parsed / _Frac.hundred;
    } else {
      final soFar = acc ?? term ?? _Frac.zero;
      value = soFar * parsed / _Frac.hundred;
    }

    if (mulOp == CalcOp.multiply) {
      term = (term ?? _Frac.one) * value;
      mulOp = null;
    } else if (mulOp == CalcOp.divide) {
      if (value.isZero) return const CalcDivideByZero();
      term = (term ?? _Frac.zero) / value;
      mulOp = null;
    } else {
      term = value;
    }
  }

  commitTerm();
  return CalcNumber(formatCalcText((acc ?? _Frac.zero).toRoundedRaw()));
}

class _Frac {
  const _Frac(this.n, this.d);

  final BigInt n;
  final BigInt d;

  static final zero = _Frac(BigInt.zero, BigInt.one);
  static final one = _Frac(BigInt.one, BigInt.one);
  static final hundred = _Frac(BigInt.from(100), BigInt.one);
  static final _ten = BigInt.from(10);
  static final _scale = _ten.pow(10);

  bool get isZero => n == BigInt.zero;

  static _Frac parse(String raw) {
    var text = raw.trim().replaceAll(',', '');
    if (text.isEmpty || text == '.' || text == '-' || text == '+') {
      return zero;
    }
    var neg = false;
    if (text.startsWith('-')) {
      neg = true;
      text = text.substring(1);
    } else if (text.startsWith('+')) {
      text = text.substring(1);
    }
    final parts = text.split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final frac = parts.length > 1 ? parts[1] : '';
    final digits = '$whole$frac';
    final parsed = BigInt.tryParse(digits) ?? BigInt.zero;
    final den = _ten.pow(frac.length);
    return _Frac(neg ? -parsed : parsed, den)._reduce();
  }

  _Frac operator +(_Frac other) =>
      _Frac(n * other.d + other.n * d, d * other.d)._reduce();

  _Frac operator -(_Frac other) =>
      _Frac(n * other.d - other.n * d, d * other.d)._reduce();

  _Frac operator *(_Frac other) => _Frac(n * other.n, d * other.d)._reduce();

  _Frac operator /(_Frac other) {
    var nn = n * other.d;
    var dd = d * other.n;
    if (dd.isNegative) {
      nn = -nn;
      dd = -dd;
    }
    return _Frac(nn, dd)._reduce();
  }

  _Frac _reduce() {
    if (d == BigInt.zero) return zero;
    var nn = n;
    var dd = d;
    if (dd.isNegative) {
      nn = -nn;
      dd = -dd;
    }
    if (nn == BigInt.zero) return zero;
    final g = nn.abs().gcd(dd);
    return _Frac(nn ~/ g, dd ~/ g);
  }

  /// 소수 10자리 반올림(0 에서 먼 쪽). 끝의 0 은 뺀 문자열.
  String toRoundedRaw() {
    final neg = n.isNegative;
    final absN = n.abs();
    final scaled = absN * _scale;
    final quot = scaled ~/ d;
    final rem = scaled % d;
    var rounded = quot;
    if (rem * BigInt.two >= d) rounded += BigInt.one;
    if (rounded == BigInt.zero) return '0';
    final digits = rounded.toString().padLeft(11, '0');
    final intPart = digits.substring(0, digits.length - 10);
    final frac = digits
        .substring(digits.length - 10)
        .replaceFirst(RegExp(r'0+$'), '');
    final body = frac.isEmpty ? intPart : '$intPart.$frac';
    return neg ? '-$body' : body;
  }
}
