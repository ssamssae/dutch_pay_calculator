import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 룰렛 목록 여러 벌과 돌리기 결과. 목록 전부(이름·항목·고른 목록)를
/// `miniapp_roulette_v2` 에 저장한다. 1.4.0 까지가 `miniapp_roulette_v1` 에
/// 남긴 항목 한 벌은 「목록 1」로 가져온다 (T-261106-018).
class RouletteController extends ChangeNotifier {
  RouletteController(this._prefs, {Random? random})
    : _random = random ?? Random() {
    final loaded = _readPresets() ?? _readLegacy();
    _presets = loaded?.presets ?? [_Preset(defaultName(1), _fresh())];
    _current = loaded?.current ?? 0;
  }

  static const storageKey = 'miniapp_roulette_v2';
  static const legacyStorageKey = 'miniapp_roulette_v1';
  static const minItems = 2;
  static const maxItems = 12;
  static const maxLength = 10;
  static const maxPresets = 5;
  static const maxPresetNameLength = 8;

  /// 목록의 기본 이름 「목록 n」.
  static String defaultName(int n) => '목록 $n';

  final SharedPreferences _prefs;
  final Random _random;

  late List<_Preset> _presets;
  late int _current;
  bool _spinning = false;
  bool _closed = false;
  int? _lastResult;
  int? _pendingIndex;

  List<String> get _items => _presets[_current].items;

  /// 고른 목록의 항목. 빈 글자를 그대로 둔 저장 값.
  List<String> get items => List.unmodifiable(_items);

  /// 빈 칸은 「항목 1」처럼 번호 이름.
  List<String> get labels => [
    for (var i = 0; i < _items.length; i++)
      _items[i].trim().isEmpty ? '항목 ${i + 1}' : _items[i],
  ];

  /// 저장한 목록들의 이름, 저장한 차례대로.
  List<String> get presetNames => [for (final preset in _presets) preset.name];

  /// 지금 고른 목록의 자리.
  int get currentPreset => _current;

  bool get canAddPreset => !_spinning && _presets.length < maxPresets;

  /// 목록은 하나는 남는다.
  bool get canRemovePreset => !_spinning && _presets.length > 1;

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
    _lastResult = null;
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

  /// 다른 목록을 고른다. 결과 글자는 지운다.
  void selectPreset(int index) {
    if (_spinning || index == _current) return;
    if (index < 0 || index >= _presets.length) return;
    _current = index;
    _lastResult = null;
    _persist();
    notifyListeners();
  }

  /// 빈 항목 2개짜리 새 목록을 만들고 바로 고른다. [maxPresets] 개까지.
  void addPreset() {
    if (!canAddPreset) return;
    _presets.add(_Preset(_unusedName(), _fresh()));
    _current = _presets.length - 1;
    _lastResult = null;
    _persist();
    notifyListeners();
  }

  /// 앞뒤 공백을 빼고 [maxPresetNameLength] 자까지. 비우면 「목록 n」.
  void renamePreset(int index, String name) {
    if (_spinning) return;
    if (index < 0 || index >= _presets.length) return;
    var next = name.trim();
    if (next.length > maxPresetNameLength) {
      next = next.substring(0, maxPresetNameLength).trim();
    }
    if (next.isEmpty) next = _unusedName(except: index);
    if (_presets[index].name == next) return;
    _presets[index].name = next;
    _persist();
    notifyListeners();
  }

  /// 목록과 그 항목을 지운다. 고른 목록을 지우면 그 자리의 다음 목록을 고른다.
  void removePreset(int index) {
    if (!canRemovePreset) return;
    if (index < 0 || index >= _presets.length) return;
    _presets.removeAt(index);
    if (_current > index) {
      _current -= 1;
    } else if (_current >= _presets.length) {
      _current = _presets.length - 1;
    }
    _lastResult = null;
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

  /// 아직 안 쓴 「목록 n」 가운데 가장 작은 번호. [except] 자리 이름은 빼고 센다.
  String _unusedName({int? except}) {
    final used = <String>{
      for (var i = 0; i < _presets.length; i++)
        if (i != except) _presets[i].name,
    };
    var n = 1;
    while (used.contains(defaultName(n))) {
      n += 1;
    }
    return defaultName(n);
  }

  void _persist() {
    _prefs.setString(
      storageKey,
      jsonEncode({
        'current': _current,
        'presets': [
          for (final preset in _presets)
            {'name': preset.name, 'items': preset.items},
        ],
      }),
    );
  }

  /// `miniapp_roulette_v2`. 없거나 깨졌으면 null.
  ({List<_Preset> presets, int current})? _readPresets() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final rawPresets = decoded['presets'];
      if (rawPresets is! List ||
          rawPresets.isEmpty ||
          rawPresets.length > maxPresets) {
        return null;
      }
      final presets = <_Preset>[];
      for (final entry in rawPresets) {
        if (entry is! Map) return null;
        final name = entry['name'];
        if (name is! String ||
            name.trim().isEmpty ||
            name.length > maxPresetNameLength) {
          return null;
        }
        final items = _parseItems(entry['items']);
        if (items == null) return null;
        presets.add(_Preset(name, items));
      }
      final current = decoded['current'];
      final index = current is int && current >= 0 && current < presets.length
          ? current
          : 0;
      return (presets: presets, current: index);
    } on FormatException {
      return null;
    }
  }

  /// 1.4.0 까지의 `miniapp_roulette_v1` 항목 한 벌 → 「목록 1」.
  ({List<_Preset> presets, int current})? _readLegacy() {
    final raw = _prefs.getString(legacyStorageKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final items = _parseItems(decoded['items']);
      if (items == null) return null;
      return (presets: [_Preset(defaultName(1), items)], current: 0);
    } on FormatException {
      return null;
    }
  }

  static List<String>? _parseItems(Object? rawItems) {
    if (rawItems is! List) return null;
    if (rawItems.length < minItems || rawItems.length > maxItems) {
      return null;
    }
    final parsed = <String>[];
    for (final item in rawItems) {
      if (item is! String || item.length > maxLength) return null;
      parsed.add(item);
    }
    return parsed;
  }

  static List<String> _fresh() => ['', ''];
}

/// 저장 목록 한 벌: 이름과 항목.
class _Preset {
  _Preset(this.name, this.items);

  String name;
  final List<String> items;
}
