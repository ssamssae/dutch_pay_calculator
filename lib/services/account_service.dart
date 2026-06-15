import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 공유 시 첨부할 입금 계좌번호를 기기에 저장한다 (하이브리드).
///
/// 설정 탭에서 미리 저장해두거나, 공유 시 비어 있으면 팝업으로 입력받아
/// 저장한다. 한 번 저장하면 다음 공유부터는 팝업 없이 저장값을 사용한다.
/// 서버 전송 없이 SharedPreferences 에만 보관한다.
class AccountService {
  static const String _prefsKey = 'share_account';

  /// 현재 저장된 계좌 문자열. 미설정이면 ''. UI 구독용.
  static final ValueNotifier<String> account = ValueNotifier<String>('');

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    account.value = prefs.getString(_prefsKey) ?? '';
  }

  static bool get hasAccount => account.value.trim().isNotEmpty;

  static Future<void> save(String value) async {
    final trimmed = value.trim();
    account.value = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, trimmed);
  }

  static Future<void> clear() => save('');
}
