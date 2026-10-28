import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dutch_pay_calculator/ladder/ladder_setup.dart';
import 'package:dutch_pay_calculator/ladder/ladder_setup_store.dart';
import 'package:dutch_pay_calculator/screens/ladder_screen.dart';
import 'package:dutch_pay_calculator/screens/ladder_setup_screen.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('설정에서 14호차 1·12호차 2 로 사다리 화면에 가서 모두 보기까지 한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
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

    // 기본값 3명·당첨 1·꽝 2 에서 라벨만 바꾼다.
    // 입력칸을 누르면 글자 전체가 선택돼 지우지 않고 바로 덮어쓴다.
    final firstLabel = find.byKey(const ValueKey('result-0'));
    await tester.tap(firstLabel);
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<TextField>(firstLabel).controller!.selection,
      const TextSelection(baseOffset: 0, extentOffset: 2),
    );
    await tester.enterText(firstLabel, '14호차');
    await tester.enterText(find.byKey(const ValueKey('result-1')), '12호차');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start')));
    await tester.pumpAndSettle();

    expect(find.byType(LadderScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reveal-all')));
    await tester.pumpAndSettle();

    expect(find.textContaining('→ 14호차'), findsOneWidget);
    expect(find.textContaining('→ 12호차'), findsNWidgets(2));
    expect(store.load()?.results, const [
      ResultSlot('14호차', 1),
      ResultSlot('12호차', 2),
    ]);
  });
}
