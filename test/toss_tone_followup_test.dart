import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dutch_pay_calculator/ladder/ladder_painter.dart';
import 'package:dutch_pay_calculator/ladder/ladder_setup.dart';
import 'package:dutch_pay_calculator/ladder/ladder_setup_store.dart';
import 'package:dutch_pay_calculator/screens/calculator_screen.dart';
import 'package:dutch_pay_calculator/screens/ladder_screen.dart';
import 'package:dutch_pay_calculator/screens/ladder_setup_screen.dart';
import 'package:dutch_pay_calculator/screens/settings_screen.dart';
import 'package:dutch_pay_calculator/services/account_service.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'dutch_pay_calculator',
      packageName: 'com.daejongkang.dutchpay',
      version: '9.9.9',
      buildNumber: '1',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/google_mobile_ads'),
          (call) async => null,
        );
  });

  test('공용 팔레트는 흰 바탕과 청록 두 값을 유지한다', () {
    expect(TossColors.bgDeep, const Color(0xFFFFFFFF));
    expect(TossColors.accent, const Color(0xFF17A58F));
    expect(TossColors.accentNeon, const Color(0xFF3DE0C8));
    expect(TossColors.accent, isNot(const Color(0xFF3182F6)));
  });

  testWidgets('설정 탭은 흰 바탕의 둥근 카드이고 글자는 진한 청록이다', (tester) async {
    await AccountService.init();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, TossColors.bgDeep);
    expect(
      DefaultTextStyle.of(tester.element(find.text('설정'))).style.fontFamily,
      'Pretendard',
    );

    final card = tester.widget<Material>(
      find.byKey(const ValueKey('settings-account')),
    );
    final shape = card.shape! as RoundedRectangleBorder;
    expect(card.color, TossColors.surface);
    expect(shape.borderRadius, BorderRadius.circular(20));
    expect(shape.side.color, TossColors.border);

    final icon = tester.widget<Icon>(
      find.byIcon(Icons.account_balance_wallet_outlined),
    );
    expect(icon.color, const Color(0xFF17A58F));

    final well = tester.widget<Container>(
      find.byKey(const ValueKey('settings-accent-well')),
    );
    final wellBorder = (well.decoration! as BoxDecoration).border! as Border;
    expect(wellBorder.top.color, const Color(0xFF3DE0C8));

    await tester.tap(find.text('입금 계좌번호'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.backgroundColor, TossColors.surface);
    expect(
      dialog.shape,
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '저장'),
    );
    expect(
      save.style?.backgroundColor?.resolve(const <WidgetState>{}),
      const Color(0xFF17A58F),
    );
  });

  testWidgets('사다리 탭은 둥근 카드·진한 청록 버튼·네온 테두리다', (tester) async {
    final store = LadderSetupStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LadderSetupScreen(
          store: store,
          initialSetup: LadderSetup.initial(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      DefaultTextStyle.of(
        tester.element(find.text('사다리 타기').first),
      ).style.fontFamily,
      'Pretendard',
    );

    final card = tester.widget<Container>(
      find.byKey(const ValueKey('player-card')),
    );
    final cardDeco = card.decoration! as BoxDecoration;
    expect(cardDeco.color, TossColors.surface);
    expect(cardDeco.borderRadius, BorderRadius.circular(20));
    expect((cardDeco.border! as Border).top.color, TossColors.border);

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('player-0')),
    );
    expect(field.decoration?.fillColor, TossColors.surfaceElevated);
    final border = field.decoration?.enabledBorder as OutlineInputBorder;
    expect(border.borderRadius, BorderRadius.circular(14));

    final status = tester.widget<Text>(find.byKey(const ValueKey('status')));
    expect(status.style?.color, const Color(0xFF17A58F));
    final pill = tester.widget<Container>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('status')),
            matching: find.byType(Container),
          )
          .first,
    );
    final pillBorder = (pill.decoration! as BoxDecoration).border! as Border;
    expect(pillBorder.top.color, const Color(0xFF3DE0C8));

    final start = tester.widget<FilledButton>(
      find.byKey(const ValueKey('start')),
    );
    expect(
      start.style?.backgroundColor?.resolve(const <WidgetState>{}),
      const Color(0xFF17A58F),
    );
    expect(
      start.style?.backgroundColor?.resolve(const <WidgetState>{}),
      isNot(const Color(0xFF3182F6)),
    );

    await tester.tap(find.byKey(const ValueKey('start')));
    await tester.pumpAndSettle();

    expect(find.byType(LadderScreen), findsOneWidget);
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<LadderPainter>();
    expect(painters.single.lineColor, TossColors.textFaint);

    final reveal = tester.widget<FilledButton>(
      find.byKey(const ValueKey('reveal-all')),
    );
    expect(
      reveal.style?.backgroundColor?.resolve(const <WidgetState>{}),
      const Color(0xFF17A58F),
    );
  });

  testWidgets('카톡 공유 버튼은 노랑 #FEE500 이다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const CalculatorScreen()),
    );
    await tester.pump();

    await tester.tap(find.text('1'));
    await tester.pump();

    final share = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '카톡으로 공유'),
    );
    expect(
      share.style?.backgroundColor?.resolve(const <WidgetState>{}),
      const Color(0xFFFEE500),
    );
  });
}
