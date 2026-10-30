import 'package:flutter/foundation.dart';

import 'calc_engine.dart';

/// 기본 계산기 입력. 저장하지 않는다.
class BasicCalculatorController extends ChangeNotifier {
  final List<CalcToken> _tokens = [];
  String? _entry;
  bool _entryPercent = false;
  bool _justEvaluated = false;
  bool _error = false;

  String _display = '0';
  String _expression = '';

  String get display => _display;
  String get expression => _expression;

  void press(String key) {
    if (_error) _clearAll();
    switch (key) {
      case 'AC':
        _clearAll();
      case '⌫':
        _backspace();
      case '=':
        _equals();
      case '%':
        _percent();
      case '.':
        _dot();
      case '+':
      case '−':
      case '×':
      case '÷':
        _operator(key);
      case '00':
        _digits('00');
      default:
        if (key.length == 1 &&
            key.codeUnitAt(0) >= 0x30 &&
            key.codeUnitAt(0) <= 0x39) {
          _digits(key);
        }
    }
    notifyListeners();
  }

  void _clearAll() {
    _tokens.clear();
    _entry = null;
    _entryPercent = false;
    _justEvaluated = false;
    _error = false;
    _display = '0';
    _expression = '';
  }

  void _digits(String digits) {
    if (_justEvaluated) _clearAll();
    if (_entryPercent) return;
    if (_entry == null || _entry == '0') {
      _entry = _allZero(digits) ? '0' : digits;
      _sync();
      return;
    }
    final next = '$_entry$digits';
    if (_digitCount(next) > 15) return;
    _entry = next;
    _sync();
  }

  void _dot() {
    if (_justEvaluated) _clearAll();
    if (_entryPercent) return;
    final entry = _entry;
    if (entry == null) {
      _entry = '0.';
    } else if (entry.contains('.')) {
      return;
    } else {
      _entry = '$entry.';
    }
    _sync();
  }

  void _operator(String symbol) {
    _justEvaluated = false;
    _commitEntry();
    if (_tokens.isEmpty) {
      _tokens.add(const NumberToken('0'));
    }
    final op = OpToken(_opOf(symbol));
    if (_tokens.last is OpToken) {
      _tokens[_tokens.length - 1] = op;
    } else {
      _tokens.add(op);
    }
    _entry = null;
    _entryPercent = false;
    _sync();
  }

  void _percent() {
    if (_justEvaluated) {
      _justEvaluated = false;
      if (_tokens.length == 1 && _tokens.single is NumberToken) {
        final number = _tokens.removeLast() as NumberToken;
        _entry = number.text;
        _expression = '';
      }
    }
    if (_entry == null) {
      if (_tokens.isNotEmpty && _tokens.last is NumberToken) {
        final number = _tokens.removeLast() as NumberToken;
        _entry = number.text;
      } else {
        _entry = '0';
      }
    }
    _entryPercent = true;
    _sync();
  }

  void _backspace() {
    if (_justEvaluated) {
      _clearAll();
      return;
    }
    final entry = _entry;
    if (entry != null) {
      if (_entryPercent) {
        _entryPercent = false;
        _sync();
        return;
      }
      final next = entry.substring(0, entry.length - 1);
      _entry = next.isEmpty ? null : next;
      _sync();
      return;
    }
    if (_tokens.isNotEmpty && _tokens.last is OpToken) {
      _tokens.removeLast();
      if (_tokens.isNotEmpty && _tokens.last is NumberToken) {
        final number = _tokens.removeLast() as NumberToken;
        _entry = number.text;
        _entryPercent = number.percent;
      }
      _sync();
    }
  }

  void _equals() {
    if (_justEvaluated) return;
    _commitEntry();
    if (_tokens.isEmpty) {
      _display = '0';
      _expression = '0 =';
      _tokens.add(const NumberToken('0'));
      _justEvaluated = true;
      return;
    }
    if (_tokens.last is OpToken) return;
    final shown = _formatTokens(_tokens);
    final outcome = evaluateTokens(_tokens);
    switch (outcome) {
      case CalcNumber(:final display):
        _display = display;
        _expression = '$shown =';
        _tokens
          ..clear()
          ..add(NumberToken(display.replaceAll(',', '')));
        _entry = null;
        _entryPercent = false;
        _justEvaluated = true;
      case CalcDivideByZero():
        _display = '0으로 나눌 수 없어요';
        _expression = '$shown =';
        _tokens.clear();
        _entry = null;
        _entryPercent = false;
        _justEvaluated = false;
        _error = true;
    }
  }

  void _commitEntry() {
    final entry = _entry;
    if (entry == null) return;
    var text = entry;
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    if (text.isEmpty) text = '0';
    _tokens.add(NumberToken(text, percent: _entryPercent));
    _entry = null;
    _entryPercent = false;
  }

  void _sync() {
    _expression = _formatTokens(_tokens);
    final entry = _entry;
    if (entry == null) {
      _display = formatCalcText(_lastNumber()?.text ?? '0');
      return;
    }
    final text = formatCalcText(entry);
    _display = _entryPercent ? '$text%' : text;
  }

  NumberToken? _lastNumber() {
    for (var i = _tokens.length - 1; i >= 0; i--) {
      final token = _tokens[i];
      if (token is NumberToken) return token;
    }
    return null;
  }

  String _formatTokens(List<CalcToken> tokens) {
    final parts = <String>[];
    for (final token in tokens) {
      switch (token) {
        case NumberToken(:final text, :final percent):
          parts.add('${formatCalcText(text)}${percent ? '%' : ''}');
        case OpToken(:final op):
          parts.add(_symbolOf(op));
      }
    }
    return parts.join(' ');
  }
}

CalcOp _opOf(String symbol) {
  return switch (symbol) {
    '−' => CalcOp.subtract,
    '×' => CalcOp.multiply,
    '÷' => CalcOp.divide,
    _ => CalcOp.add,
  };
}

String _symbolOf(CalcOp op) {
  return switch (op) {
    CalcOp.add => '+',
    CalcOp.subtract => '−',
    CalcOp.multiply => '×',
    CalcOp.divide => '÷',
  };
}

bool _allZero(String digits) =>
    digits.isNotEmpty && digits.split('').every((c) => c == '0');

int _digitCount(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '').length;
