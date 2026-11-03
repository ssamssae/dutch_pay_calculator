import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:shared_preferences/shared_preferences.dart';

import '../../ladder/ladder_setup.dart' show ResultSlot;

/// 제비 판을 만드는 방식.
enum LotteryMode {
  /// 전체 장수와 당첨 장수만 정한다. 제비 글 = 「당첨」·「꽝」.
  winLose,

  /// 결과 글과 장수를 직접 적는다. 예: 12호차 ×1, 14호차 ×1.
  custom,
}

/// 제비뽑기 설정과 판.
///
/// 설정(방식 · 장수 · 당첨 수 · 직접 쓴 결과)만 `miniapp_lottery_v1` 에 저장한다.
/// 판은 앱을 다시 열면 사라진다.
class LotteryController extends ChangeNotifier {
  LotteryController(this._prefs, {Random? random})
    : _random = random ?? Random() {
    _load();
  }

  static const storageKey = 'miniapp_lottery_v1';
  static const minTotal = 2;
  static const maxTotal = 20;

  /// 직접 쓰는 결과 한 줄의 글자 수 한도.
  static const maxLabelLength = 10;

  /// 당첨·꽝 방식의 제비 글.
  static const winFace = '당첨';

  /// 이 글이 적힌 제비만 축하하지 않는다. 직접 쓰기에서도 같다.
  static const loseFace = '꽝';

  static const _initialTotal = 4;
  static const _initialWinners = 1;

  final SharedPreferences _prefs;
  final Random _random;

  LotteryMode _mode = LotteryMode.winLose;
  int _total = _initialTotal;
  int _winners = _initialWinners;
  List<ResultSlot> _items = _initialItems();
  List<bool>? _board;
  List<String>? _faces;
  final Set<int> _revealed = {};

  /// 직접 쓰기 처음 값: 빈 결과 두 줄, 한 장씩.
  static List<ResultSlot> _initialItems() => [
    const ResultSlot('', 1),
    const ResultSlot('', 1),
  ];

  LotteryMode get mode => _mode;

  /// 당첨·꽝 방식의 전체 장수.
  int get total => _total;

  /// 당첨·꽝 방식의 당첨 장수.
  int get winners => _winners;

  /// 직접 쓴 결과 줄. 글은 적은 그대로다(빈 칸 포함).
  List<ResultSlot> get items => List<ResultSlot>.unmodifiable(_items);

  /// 직접 쓴 결과의 장수 합계.
  int get itemTotal => _items.fold(0, (sum, item) => sum + item.count);

  /// 제비에 적을 결과 글. 빈 칸은 「결과 1」처럼 번호 이름.
  List<String> get itemLabels => [
    for (var i = 0; i < _items.length; i++)
      _items[i].label.trim().isEmpty ? '결과 ${i + 1}' : _items[i].label.trim(),
  ];

  /// 지금 방식으로 만들 제비 장수.
  int get ticketCount => _mode == LotteryMode.winLose ? _total : itemTotal;

  /// 2..20장이면 섞을 수 있다.
  bool get canShuffle => ticketCount >= minTotal && ticketCount <= maxTotal;

  /// true = 축하할 제비(「꽝」이 아닌 제비). 섞기 전에는 null.
  List<bool>? get board => _board;

  /// 제비마다 적힌 글. 섞기 전에는 null.
  List<String>? get faces => _faces;

  Set<int> get revealed => Set<int>.unmodifiable(_revealed);

  /// 아직 안 뒤집은 장수. 판이 없으면 만들 장수.
  int get remaining {
    final board = _board;
    if (board == null) return ticketCount;
    return board.length - _revealed.length;
  }

  /// 아직 안 뒤집은 당첨 장수. 판이 없으면 당첨·꽝 설정값.
  int get remainingWinners {
    final board = _board;
    if (board == null) return _winners;
    var left = 0;
    for (var i = 0; i < board.length; i++) {
      if (board[i] && !_revealed.contains(i)) left++;
    }
    return left;
  }

  /// [index] 줄이 가질 수 있는 최대 장수. 다른 줄과 합쳐 20장까지.
  int maxCountFor(int index) {
    if (index < 0 || index >= _items.length) return 1;
    return maxTotal - (itemTotal - _items[index].count);
  }

  /// 방식을 바꾸면 판이 사라진다.
  void setMode(LotteryMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    _clearBoard();
    _persist();
    notifyListeners();
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

  /// 빈 결과 한 줄(1장)을 더한다. 이미 20장이면 그대로.
  void addItem() {
    if (itemTotal >= maxTotal) return;
    _items.add(const ResultSlot('', 1));
    _itemsChanged();
  }

  /// 한 줄을 지운다. 마지막 한 줄은 남긴다.
  void removeItem(int index) {
    if (_items.length <= 1) return;
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    _itemsChanged();
  }

  /// 적은 글을 그대로 둔다. 앞뒤 공백은 섞을 때 뺀다. [maxLabelLength] 자까지.
  void renameItem(int index, String text) {
    if (index < 0 || index >= _items.length) return;
    final next = text.characters.take(maxLabelLength).toString();
    if (_items[index].label == next) return;
    _items[index] = ResultSlot(next, _items[index].count);
    _itemsChanged();
  }

  /// 1..[maxCountFor].
  void setItemCount(int index, int count) {
    if (index < 0 || index >= _items.length) return;
    final next = _clamp(count, 1, maxCountFor(index));
    if (next == _items[index].count) return;
    _items[index] = ResultSlot(_items[index].label, next);
    _itemsChanged();
  }

  /// 새 판. 이미 뒤집은 칸은 닫힌다. 섞을 수 없으면 그대로.
  ///
  /// 당첨·꽝 = 당첨이 정확히 [winners] 장. 직접 쓰기 = 결과마다 적은 장수만큼.
  void shuffle() {
    if (!canShuffle) return;
    if (_mode == LotteryMode.winLose) {
      final next = List<bool>.filled(_total, false);
      for (var i = 0; i < _winners; i++) {
        next[i] = true;
      }
      next.shuffle(_random);
      _board = List<bool>.unmodifiable(next);
      _faces = List<String>.unmodifiable([
        for (final win in next) win ? winFace : loseFace,
      ]);
    } else {
      final labels = itemLabels;
      final next = <String>[
        for (var i = 0; i < _items.length; i++)
          for (var k = 0; k < _items[i].count; k++) labels[i],
      ];
      next.shuffle(_random);
      _faces = List<String>.unmodifiable(next);
      _board = List<bool>.unmodifiable([
        for (final face in next) face != loseFace,
      ]);
    }
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
    _clearBoard();
    _persist();
    notifyListeners();
  }

  void _itemsChanged() {
    _clearBoard();
    _persist();
    notifyListeners();
  }

  void _clearBoard() {
    _board = null;
    _faces = null;
    _revealed.clear();
  }

  void _persist() {
    _prefs.setString(
      storageKey,
      jsonEncode({
        'total': _total,
        'winners': _winners,
        'mode': _mode.name,
        'items': [
          for (final item in _items) {'label': item.label, 'count': item.count},
        ],
      }),
    );
  }

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
    _loadCounts(data);
    _loadCustom(data);
  }

  /// 당첨·꽝 장수. 깨졌거나 범위 밖이면 처음 값을 둔다.
  void _loadCounts(Map<dynamic, dynamic> data) {
    final total = data['total'];
    final winners = data['winners'];
    if (total is! int || winners is! int) return;
    if (total < minTotal || total > maxTotal) return;
    if (winners < 1 || winners > total - 1) return;
    _total = total;
    _winners = winners;
  }

  /// 방식과 직접 쓴 결과. 옛 저장값(둘 다 없음)이거나 깨졌으면 처음 값을 둔다.
  void _loadCustom(Map<dynamic, dynamic> data) {
    final mode = data['mode'];
    for (final value in LotteryMode.values) {
      if (value.name == mode) _mode = value;
    }
    final items = data['items'];
    if (items is! List || items.isEmpty) return;
    final parsed = <ResultSlot>[];
    var sum = 0;
    for (final item in items) {
      if (item is! Map) return;
      final label = item['label'];
      final count = item['count'];
      if (label is! String || count is! int) return;
      if (label.characters.length > maxLabelLength) return;
      if (count < 1 || count > maxTotal) return;
      sum += count;
      parsed.add(ResultSlot(label, count));
    }
    if (sum > maxTotal) return;
    _items = parsed;
  }

  int _clamp(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
