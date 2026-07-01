import 'package:dutch_pay_calculator/screens/settings_screen.dart';
import 'package:dutch_pay_calculator/services/account_service.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'share_account': '카카오뱅크 3333-01-1234567',
    });
    PackageInfo.setMockInitialValues(
      appName: 'dutch_pay_calculator',
      packageName: 'com.daejongkang.dutchpay',
      version: '9.9.9',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await AccountService.init();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const SettingsScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('SettingsScreen: 저장된 입금 계좌는 다이얼로그에서 바로 삭제할 수 있다', (tester) async {
    await pumpSettings(tester);

    expect(find.text('카카오뱅크 3333-01-1234567'), findsOneWidget);

    await tester.tap(find.text('입금 계좌번호'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, '삭제'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();

    expect(AccountService.account.value, isEmpty);
    expect(find.text('공유 시 함께 보낼 계좌를 등록하세요'), findsOneWidget);
  });
}
