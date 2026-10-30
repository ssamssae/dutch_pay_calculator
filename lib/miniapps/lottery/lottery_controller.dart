import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 제비뽑기 장수와 판. 장수 · 당첨 수만 `miniapp_lottery_v1` 에 저장한다.
class LotteryController extends ChangeNotifier {
  LotteryController(this._prefs, {Random? random})
    : _random = random ?? Random() {
    _load();
  }

  static const storageKey = 'miniapp_lottery_v1';
  static const minTotal = 2;
  static const maxTotal = 20;

  static const _initialTotal = 4;
  static const _initialWinners = 1;

  final SharedPreferences _prefs;
  final Random _random;

  int _total = _initialTotal;
  int _winners = _initialWinners;
  List<bool>? _board;
  final Set<int> _revealed = {};

  int get total => _total;

  int get winners => _winners;

  /// true = 당첨. 섞기 전에는 null.
  List<bool>? get board => _board;

  Set<int> get revealed => Set<int>.unmodifiable(_revealed);

  /// 아직 안 뒤집은 장수. 판이 없으면 전체 장수.
  int get remaining {
    final board = _board;
    if (board == null) return _total;
    return board.length - _revealed.length;
  }

  /// 아직 안 뒤집은 당첨 장수. 판이 없으면 설정값.
  int get remainingWinners {
    final board = _board;
    if (board == null) return _winners;
    var left = 0;
    for (var i = 0; i < board.length; i++) {
      if (board[i] && !_revealed.contains(i)) left++;
    }
    return left;
  }

  /// 2..20. 당첨 수는 그다음 전체−1 이하로 줄인다.
  void setTotal(int value) {
    final nextTotal = _clamp(value, minTotal, maxTotal);
    final nextWinners = _clamp(_winners, 1, nextTotal - 1);
    _commit(nextTotal, nextWinners);
  }

  /// 1..전체−1.
  void setWinners(int value) {
    _commit(_total, _clamp(value, 1, _total - 1));
  }

  /// 당첨이 정확히 [winners] 장인 새 판. 이미 뒤집은 칸은 닫힌다.
  void shuffle() {
    final next = List<bool>.filled(_total, false);
    for (var i = 0; i < _winners; i++) {
      next[i] = true;
    }
    next.shuffle(_random);
    _board = List<bool>.unmodifiable(next);
    _revealed.clear();
    notifyListeners();
  }

  /// 한 칸을 연다. 이미 연 칸은 같은 값. 판이 없거나 칸이 없으면 null.
  bool? reveal(int index) {
    final board = _board;
    if (board == null) return null;
    if (index < 0 || index >= board.length) return null;
    if (_revealed.add(index)) notifyListeners();
    return board[index];
  }

  void _commit(int total, int winners) {
    if (total == _total && winners == _winners) return;
    _total = total;
    _winners = winners;
    _board = null;
    _revealed.clear();
    _persist();
    notifyListeners();
  }

  void _persist() {
    _prefs.setString(
      storageKey,
      jsonEncode({'total': _total, 'winners': _winners}),
    );
  }

  /// 깨졌거나 범위 밖이면 처음 값을 둔다.
  void _load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return;
    final Object? data;
    try {
      data = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (data is! Map) return;
    final total = data['total'];
    final winners = data['winners'];
    if (total is! int || winners is! int) return;
    if (total < minTotal || total > maxTotal) return;
    if (winners < 1 || winners > total - 1) return;
    _total = total;
    _winners = winners;
  }

  int _clamp(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
