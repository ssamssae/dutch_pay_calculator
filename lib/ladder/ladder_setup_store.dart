import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ladder_setup.dart';

/// 마지막 입력(참가자·결과)을 기기 안 SharedPreferences 에만 기억한다.
class LadderSetupStore {
  LadderSetupStore(this._prefs);

  static const key = 'ladder_last_setup_v1';

  final SharedPreferences _prefs;

  /// 저장값이 없거나 깨졌으면 null.
  LadderSetup? load() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return LadderSetup.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  Future<void> save(LadderSetup setup) =>
      _prefs.setString(key, jsonEncode(setup.toJson()));
}
