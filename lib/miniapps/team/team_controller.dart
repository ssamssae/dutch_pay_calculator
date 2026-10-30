import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 팀 나누기 상태. 이름 · 팀 수를 SharedPreferences 에 저장한다.
class TeamController extends ChangeNotifier {
  TeamController(this._prefs, {Random? random}) : _random = random ?? Random() {
    _load();
  }

  static const storageKey = 'miniapp_team_v1';
  static const minPeople = 2;
  static const maxPeople = 30;
  static const minTeams = 2;
  static const maxTeams = 6;

  static const _initialPeople = 4;

  final SharedPreferences _prefs;
  final Random _random;

  List<String> _names = List.filled(_initialPeople, '');
  int _teamCount = minTeams;
  List<List<String>>? _teams;

  List<String> get names => List.unmodifiable(_names);

  /// 빈 칸은 `N번` 으로 바꾼 이름.
  List<String> get labels => [
    for (var i = 0; i < _names.length; i++)
      _names[i].trim().isEmpty ? '${i + 1}번' : _names[i].trim(),
  ];

  int get teamCount => _teamCount;

  int get _maxTeamsNow => min(maxTeams, _names.length);

  /// 나누기 전이나 편집한 뒤에는 null.
  List<List<String>>? get teams => _teams;

  void addPerson() {
    if (_names.length >= maxPeople) return;
    _names = [..._names, ''];
    _changed();
  }

  void removePerson(int index) {
    if (_names.length <= minPeople) return;
    if (index < 0 || index >= _names.length) return;
    _names = [..._names]..removeAt(index);
    _teamCount = min(_teamCount, _maxTeamsNow);
    _changed();
  }

  void renamePerson(int index, String text) {
    if (index < 0 || index >= _names.length) return;
    if (_names[index] == text) return;
    _names = [..._names]..[index] = text;
    _changed();
  }

  void setTeamCount(int value) {
    final next = value.clamp(minTeams, _maxTeamsNow);
    if (next == _teamCount) return;
    _teamCount = next;
    _changed();
  }

  /// 섞은 뒤 1팀부터 차례로 한 명씩 나눠 준다.
  void split() {
    final shuffled = labels..shuffle(_random);
    final result = List.generate(_teamCount, (_) => <String>[]);
    for (var i = 0; i < shuffled.length; i++) {
      result[i % _teamCount].add(shuffled[i]);
    }
    _teams = result;
    notifyListeners();
  }

  void _changed() {
    _teams = null;
    _prefs.setString(
      storageKey,
      jsonEncode({'names': _names, 'teams': _teamCount}),
    );
    notifyListeners();
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
    final names = data['names'];
    final teams = data['teams'];
    if (names is! List || teams is! int) return;
    if (names.length < minPeople || names.length > maxPeople) return;
    if (names.any((name) => name is! String)) return;
    if (teams < minTeams || teams > min(maxTeams, names.length)) return;
    _names = names.cast<String>().toList();
    _teamCount = teams;
  }
}
