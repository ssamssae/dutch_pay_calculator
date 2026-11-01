import 'package:dutch_pay_calculator/screens/calculator_screen.dart';
import 'package:dutch_pay_calculator/screens/main_shell.dart';
import 'package:dutch_pay_calculator/screens/settings_screen.dart';
import 'package:dutch_pay_calculator/services/account_service.dart';
import 'package:dutch_pay_calculator/services/iap_service.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/layout_devices.dart';

/// 앱 바(오른쪽 위 actions)에 광고 제거 아이콘이 없는지 본다.
void _expectNoRemoveAdsAppBarIcon(WidgetTester tester) {
  expect(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.block),
    ),
    findsNothing,
  );
  expect(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.block_outlined),
    ),
    findsNothing,
  );
  expect(find.byTooltip('광고 제거'), findsNothing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAdsChannel();
    IapService.adsRemoved.value = false;
  });

  tearDown(() {
    IapService.adsRemoved.value = false;
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(440, 956);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MainShell()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTile(WidgetTester tester, String tile) async {
    await tester.tap(find.byTooltip('미니앱 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey(tile)));
    await tester.pumpAndSettle();
  }

  testWidgets('앱 바 오른쪽 위에 광고 제거 아이콘이 없다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const CalculatorScreen()),
    );
    await tester.pump();

    _expectNoRemoveAdsAppBarIcon(tester);
    expect(find.byType(AppBar), findsOneWidget);
    final calculatorBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(calculatorBar.actions, anyOf(isNull, isEmpty));

    await pumpShell(tester);
    expect(find.byType(CalculatorScreen), findsOneWidget);
    _expectNoRemoveAdsAppBarIcon(tester);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    _expectNoRemoveAdsAppBarIcon(tester);

    for (final tile in [
      'tile-ladder',
      'tile-calculator',
      'tile-roulette',
      'tile-lottery',
      'tile-team',
    ]) {
      await openTile(tester, tile);
      _expectNoRemoveAdsAppBarIcon(tester);
      await tester.tap(find.byKey(const ValueKey('miniapp-back')));
      await tester.pumpAndSettle();
      _expectNoRemoveAdsAppBarIcon(tester);
    }
  });

  testWidgets('설정에 광고 제거 구매와 구매 복원 목록이 있다', (tester) async {
    await AccountService.init();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-remove-ads')), findsOneWidget);
    expect(find.text('광고 제거'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-restore')), findsOneWidget);
    expect(find.text('구매 복원'), findsOneWidget);
    _expectNoRemoveAdsAppBarIcon(tester);

    IapService.adsRemoved.value = true;
    await tester.pump();

    expect(find.byKey(const ValueKey('settings-remove-ads')), findsNothing);
    expect(find.byKey(const ValueKey('settings-restore')), findsOneWidget);
    expect(find.text('구매 복원'), findsOneWidget);
    _expectNoRemoveAdsAppBarIcon(tester);
  });
}
