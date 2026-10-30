import 'dart:io';

import 'package:dutch_pay_calculator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'dutch_pay_calculator',
      packageName: 'com.daejongkang.dutchPayCalculator',
      version: '1.2.0',
      buildNumber: '18',
      buildSignature: '',
    );
  });

  test('iOS 이름 = 나눠요', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(_stringAfterKey(plist, 'CFBundleDisplayName'), '나눠요');
    expect(_stringAfterKey(plist, 'CFBundleName'), '나눠요');
  });

  test('안드로이드 이름 = 나눠요', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:label="나눠요"'));
  });

  testWidgets('앱 제목·로딩 글자 = 나눠요', (tester) async {
    await tester.pumpWidget(const DutchPayApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, '나눠요');
    expect(find.text('나눠요'), findsOneWidget);

    // 로딩 타이머(1.5초)와 전환(0.5초)을 끝내 대기 타이머를 남기지 않는다.
    await tester.pump(const Duration(seconds: 2));
  });

  test('아이콘 원본 = 1024×1024, 알파 없음', () {
    final bytes = File('icon_design/nanwoyo_master.png').readAsBytesSync();
    _expectRgb1024(bytes);
  });

  test('로딩 로고 = 아이콘 원본과 같은 바이트', () {
    final master = File('icon_design/nanwoyo_master.png').readAsBytesSync();
    final logo = File('assets/images/app_logo.png').readAsBytesSync();
    expect(logo, master);
  });

  test('iOS 1024 아이콘에 알파 없음', () {
    final bytes = File(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
    ).readAsBytesSync();
    // IHDR color type. 파일 오프셋 25. 2 = RGB, 알파 없음.
    expect(bytes[25], 2);
  });
}

String _stringAfterKey(String plist, String key) {
  final keyTag = '<key>$key</key>';
  final start = plist.indexOf(keyTag);
  expect(start, isNonNegative, reason: key);
  final rest = plist.substring(start + keyTag.length);
  final match = RegExp(r'<string>([^<]*)</string>').firstMatch(rest);
  expect(match, isNotNull, reason: key);
  return match!.group(1)!;
}

void _expectRgb1024(List<int> bytes) {
  expect(String.fromCharCodes(bytes.sublist(12, 16)), 'IHDR');
  expect(_be32(bytes, 16), 1024);
  expect(_be32(bytes, 20), 1024);
  expect(bytes[25], 2);
}

int _be32(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];
