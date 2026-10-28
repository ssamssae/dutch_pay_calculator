import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dutch_pay_calculator/screens/ladder_setup_screen.dart';
import 'package:dutch_pay_calculator/screens/ladder_tab.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';

/// 기기 화면 = 물리 크기, 배율, 안전 영역(물리 픽셀).
typedef _Device = (Size, double, FakeViewPadding);

/// 더치페이는 iPhone 가로와 iPad 를 지원한다(TARGETED_DEVICE_FAMILY 1,2).
/// 사다리요는 iPhone 세로 전용이었으므로, 옮겨 온 사다리 화면이 기기·방향마다
/// 넘치지 않는지 가장 빽빽한 경우(12명·결과 12줄)로 확인한다.
const _devices = <String, _Device>{
  'iPhone SE 세로': (Size(750, 1334), 2, FakeViewPadding(top: 40)),
  'iPhone 6.7 세로': (
    Size(1290, 2796),
    3,
    FakeViewPadding(top: 177, bottom: 102),
  ),
  'iPhone 6.7 가로': (
    Size(2796, 1290),
    3,
    FakeViewPadding(left: 177, right: 177, bottom: 63),
  ),
  'iPad 13 세로': (Size(2048, 2732), 2, FakeViewPadding(top: 48, bottom: 40)),
  'iPad 13 가로': (Size(2732, 2048), 2, FakeViewPadding(top: 48, bottom: 40)),
};

/// MainShell 과 같은 자리(하단 탭 바 위)에 사다리 탭만 띄운다.
/// 계산기 탭은 iPhone 가로에서 이 변경 전부터 몇 px 넘쳐서(b5b1a5f 실측) 여기서 뺀다.
/// 하단 바 높이 80 은 실제 탭 바(약 65)보다 넉넉히 잡아 더 좁은 조건으로 본다.
Widget _host() => MaterialApp(
  theme: AppTheme.light,
  home: const Scaffold(
    body: LadderTab(),
    bottomNavigationBar: SafeArea(top: false, child: SizedBox(height: 80)),
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // 광고 크기 조회는 테스트에서 응답이 없다 → 배너는 숨은 채로 둔다.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/google_mobile_ads'),
          (call) async => null,
        );
  });

  for (final MapEntry(key: name, value: (size, ratio, padding))
      in _devices.entries) {
    testWidgets('사다리 탭이 $name 에서 넘치지 않는다', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      tester.view.padding = padding;
      tester.view.viewPadding = padding;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // 설정 목록은 화면 밖 항목을 만들지 않으므로 스크롤해서 찾는다.
      final list = find
          .descendant(
            of: find.byType(LadderSetupScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      final addPlayer = find.byKey(const ValueKey('add-player'));
      for (var i = 3; i < 12; i++) {
        await tester.scrollUntilVisible(addPlayer, -200, scrollable: list);
        await tester.tap(addPlayer);
        await tester.pump();
      }
      final order = find.text('순서 1~12');
      await tester.scrollUntilVisible(order, 200, scrollable: list);
      await tester.tap(order);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reveal-all')));
      await tester.pumpAndSettle();

      expect(find.textContaining('→'), findsNWidgets(12));
    });
  }
}
