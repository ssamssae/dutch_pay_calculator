import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 룰렛 항목과 돌리기 결과. 항목만 `miniapp_roulette_v1` 에 저장한다.
class RouletteController extends ChangeNotifier {
  RouletteController(this._prefs, {Random? random})
    : _random = random ?? Random() {
    _items = _readItems();
  }

  static const storageKey = 'miniapp_roulette_v1';
  static const minItems = 2;
  static const maxItems = 12;
  static const maxLength = 10;

  final SharedPreferences _prefs;
  final Random _random;

  late List<String> _items;
  bool _spinning = false;
  bool _closed = false;
  int? _lastResult;
  int? _pendingIndex;

  /// 빈 글자를 그대로 둔 저장 값.
  List<String> get items => List.unmodifiable(_items);

  /// 빈 칸은 「항목 1」처럼 번호 이름.
  List<String> get labels => [
    for (var i = 0; i < _items.length; i++)
      _items[i].trim().isEmpty ? '항목 ${i + 1}' : _items[i],
  ];

  bool get spinning => _spinning;

  /// 마지막으로 멈춘 칸. 앱을 다시 열면 새 컨트롤러라 null 이다.
  int? get lastResult => _lastResult;

  void addItem() {
    if (_spinning || _items.length >= maxItems) return;
    _items.add('');
    _persist();
    notifyListeners();
  }

  void removeItem(int index) {
    if (_spinning || _items.length <= minItems) return;
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    if (_lastResult != null && _lastResult! >= _items.length) {
      _lastResult = null;
    }
    _persist();
    notifyListeners();
  }

  /// 앞뒤 공백을 빼고 [maxLength] 자까지만 남긴다.
  void renameItem(int index, String text) {
    if (_spinning) return;
    if (index < 0 || index >= _items.length) return;
    var next = text.trim();
    if (next.length > maxLength) {
      next = next.substring(0, maxLength);
    }
    if (_items[index] == next) return;
    _items[index] = next;
    _persist();
    notifyListeners();
  }

  /// 칸을 고르고 돌기 시작한다. 이미 돌고 있으면 -1.
  int startSpin() {
    if (_spinning) return -1;
    final index = _random.nextInt(_items.length);
    _pendingIndex = index;
    _spinning = true;
    notifyListeners();
    return index;
  }

  void finishSpin() {
    if (_closed || !_spinning) return;
    _spinning = false;
    _lastResult = _pendingIndex;
    notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }

  void _persist() {
    _prefs.setString(storageKey, jsonEncode({'items': _items}));
  }

  List<String> _readItems() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return _fresh();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return _fresh();
      final rawItems = decoded['items'];
      if (rawItems is! List) return _fresh();
      if (rawItems.length < minItems || rawItems.length > maxItems) {
        return _fresh();
      }
      final parsed = <String>[];
      for (final item in rawItems) {
        if (item is! String || item.length > maxLength) return _fresh();
        parsed.add(item);
      }
      return parsed;
    } on FormatException {
      return _fresh();
    }
  }

  List<String> _fresh() => ['', ''];
}
