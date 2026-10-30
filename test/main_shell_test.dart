import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dutch_pay_calculator/screens/calculator_screen.dart';
import 'package:dutch_pay_calculator/screens/main_shell.dart';
import 'package:dutch_pay_calculator/screens/settings_screen.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';

import 'support/layout_devices.dart';

const _button = ValueKey('miniapp-button');
const _sheet = ValueKey('miniapp-sheet');
const _scrim = ValueKey('miniapp-scrim');
const _tiles = [
  'tile-ladder',
  'tile-calculator',
  'tile-roulette',
  'tile-lottery',
  'tile-team',
];

class _PushCounter extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
  }
}

Widget _host({List<NavigatorObserver> observers = const []}) => MaterialApp(
  theme: AppTheme.light,
  navigatorObservers: observers,
  home: const MainShell(),
);

Future<void> _pumpShell(
  WidgetTester tester, {
  List<NavigatorObserver> observers = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(440, 956);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(observers: observers));
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(_button));
  await tester.pumpAndSettle();
  expect(find.byKey(_sheet), findsOneWidget);
}

Future<void> _openTile(WidgetTester tester, String tile) async {
  await _openSheet(tester);
  await tester.tap(find.byKey(ValueKey(tile)));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('miniapp-back')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAdsChannel();
  });

  testWidgets('아래 탭은 더치페이·미니앱·설정', (tester) async {
    await _pumpShell(tester);

    expect(find.text('더치페이'), findsOneWidget);
    expect(find.text('미니앱'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('계산기'), findsNothing);
    expect(find.text('사다리'), findsNothing);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    expect(find.byTooltip('미니앱 열기'), findsOneWidget);
    expect(find.byKey(_sheet), findsNothing);
    expect(find.byType(CalculatorScreen), findsOneWidget);
  });

  testWidgets('미니앱을 누르면 판과 칸 5개가 순서대로', (tester) async {
    await _pumpShell(tester);
    await _openSheet(tester);

    expect(find.byKey(_scrim), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byTooltip('미니앱 닫기'), findsOneWidget);
    final sheet = find.byKey(_sheet);
    expect(
      find.descendant(of: sheet, matching: find.text('미니앱')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('모임에서 바로 쓰는 도구')),
      findsOneWidget,
    );

    final rects = [
      for (final key in _tiles) tester.getRect(find.byKey(ValueKey(key))),
    ];
    // 3열 격자: 첫 줄 사다리 · 계산기 · 룰렛, 둘째 줄 제비뽑기 · 팀 나누기.
    expect(rects[0].top, rects[1].top);
    expect(rects[1].top, rects[2].top);
    expect(rects[0].left < rects[1].left, isTrue);
    expect(rects[1].left < rects[2].left, isTrue);
    expect(rects[3].top > rects[0].bottom - 1, isTrue);
    expect(rects[3].top, rects[4].top);
    expect(rects[3].left, rects[0].left);
    expect(rects[4].left, rects[1].left);
    for (final r in rects) {
      expect(r.height >= 44 && r.width >= 44, isTrue);
    }
    for (final label in ['사다리', '계산기', '룰렛', '제비뽑기', '팀 나누기']) {
      expect(
        find.descendant(of: sheet, matching: find.text(label)),
        findsOneWidget,
      );
    }
  });

  testWidgets('판 닫기 4가지: 버튼·막·아래로 쓸기·안드로이드 뒤로', (tester) async {
    await _pumpShell(tester);

    await _openSheet(tester);
    await tester.tap(find.byKey(_button));
    await tester.pumpAndSettle();
    expect(find.byKey(_sheet), findsNothing);

    await _openSheet(tester);
    await tester.tapAt(const Offset(220, 20));
    await tester.pumpAndSettle();
    expect(find.byKey(_sheet), findsNothing);

    await _openSheet(tester);
    await tester.drag(
      find.descendant(of: find.byKey(_sheet), matching: find.text('미니앱')),
      const Offset(0, 120),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_sheet), findsNothing);

    await _openSheet(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(_sheet), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('계산기 칸 → 계산기 화면 → 뒤로 → 더치페이 탭', (tester) async {
    await _pumpShell(tester);
    await _openTile(tester, 'tile-calculator');

    expect(find.text('간단한 계산을 바로 해요'), findsOneWidget);
    expect(find.byKey(_sheet), findsNothing);

    await _back(tester);
    expect(find.text('간단한 계산을 바로 해요'), findsNothing);
    expect(find.byType(CalculatorScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byKey(_sheet), findsNothing);
  });

  testWidgets('설정 탭에서 열고 뒤로 → 설정 탭 그대로', (tester) async {
    await _pumpShell(tester);
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await _openTile(tester, 'tile-calculator');
    expect(find.text('간단한 계산을 바로 해요'), findsOneWidget);

    await _back(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(CalculatorScreen), findsNothing);
  });

  testWidgets('사다리 칸 → 사다리 타기 화면, 뒤로 이름표 = 뒤로', (tester) async {
    await _pumpShell(tester);
    await _openTile(tester, 'tile-ladder');

    expect(find.widgetWithText(AppBar, '사다리 타기'), findsOneWidget);
    expect(find.byKey(const ValueKey('start')), findsOneWidget);
    expect(find.byTooltip('뒤로'), findsOneWidget);

    await _back(tester);
    expect(find.widgetWithText(AppBar, '사다리 타기'), findsNothing);
    expect(find.byType(CalculatorScreen), findsOneWidget);
  });

  testWidgets('칸 두 번 빠르게 → 화면 1개만 열린다', (tester) async {
    final counter = _PushCounter();
    await _pumpShell(tester, observers: [counter]);
    await _openSheet(tester);
    final before = counter.pushes;

    final tile = find.byKey(const ValueKey('tile-calculator'));
    await tester.tap(tile);
    await tester.tap(tile, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(counter.pushes - before, 1);
    expect(find.text('간단한 계산을 바로 해요'), findsOneWidget);
  });

  testWidgets('룰렛에서 넣은 항목이 나갔다 와도 남는다', (tester) async {
    await _pumpShell(tester);
    await _openTile(tester, 'tile-roulette');
    expect(find.text('누가 쏠지 돌려서 정해요'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('roulette-item-0')), '민수');
    await tester.pump();
    await _back(tester);

    await _openTile(tester, 'tile-roulette');
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('roulette-item-0')),
    );
    expect(field.controller?.text, '민수');
  });

  for (final d in kLayoutDevices) {
    testWidgets('판을 열어도 넘치지 않는다 ${d.name}', (tester) async {
      await pumpOnDevice(tester, d, _host());
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final sheetRect = tester.getRect(find.byKey(_sheet));
      final barTop = tester.getRect(find.byKey(_button)).top + 6;
      expect(sheetRect.bottom <= barTop + 0.01, isTrue);
      for (final key in _tiles) {
        final tile = find.byKey(ValueKey(key));
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        final r = tester.getRect(tile);
        expect(
          r.top >= sheetRect.top - 0.01 && r.bottom <= sheetRect.bottom + 0.01,
          isTrue,
          reason: '$key $r / sheet $sheetRect',
        );
        expect(tile.hitTestable(), findsOneWidget, reason: key);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
