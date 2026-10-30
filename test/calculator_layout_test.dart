import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dutch_pay_calculator/screens/calculator_screen.dart';
import 'package:dutch_pay_calculator/screens/main_shell.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';

import 'support/layout_devices.dart';

/// 논리 화면 크기. 테스트 뷰 배율은 1이라 물리 크기와 같다.
/// 안전 영역은 물리 픽셀이며, 배율 1에서는 논리 픽셀과 같다.
typedef _Device = ({
  String name,
  Size size,
  double textScale,
  FakeViewPadding padding,
});

/// 계산기 탭(하단 탭 포함 실제 셸)이 기기 크기마다 넘치지 않는지 본다.
/// 크기는 T-261017-008 지정값. 큰 글자는 더 좁은 아이폰 SE 세로.
const _zero = FakeViewPadding.zero;

const _devices = <_Device>[
  (name: 'iPhone SE 세로', size: Size(375, 667), textScale: 1, padding: _zero),
  (name: 'iPhone 6.9 세로', size: Size(440, 956), textScale: 1, padding: _zero),
  (name: 'iPhone SE 가로', size: Size(667, 375), textScale: 1, padding: _zero),
  (name: 'iPhone 6.9 가로', size: Size(956, 440), textScale: 1, padding: _zero),
  (
    name: 'iPhone 6.9 가로 안전영역',
    size: Size(956, 440),
    textScale: 1,
    // 가로 노치·홈 인디케이터. 사다리 검사의 6.7형 가로(좌우 59·아래 21)보다 조금 넓다.
    padding: FakeViewPadding(left: 62, right: 62, bottom: 21),
  ),
  (name: 'iPad 13 세로', size: Size(1032, 1376), textScale: 1, padding: _zero),
  (name: 'iPad 13 가로', size: Size(1376, 1032), textScale: 1, padding: _zero),
  (
    name: 'iPhone SE 세로 큰 글자',
    size: Size(375, 667),
    textScale: 1.3,
    padding: _zero,
  ),
];

/// 세로 화면 불변 비교 대상. 가로·큰 글자는 넘침 0만 확인한다.
const _portraitNames = <String>{'iPhone SE 세로', 'iPhone 6.9 세로', 'iPad 13 세로'};

/// 키 9를 열 번 누른 뒤(9,999,999,999원)의 세로 기준점.
/// 빈 금액 기준점과 달리 큰 글자 세로도 포함한다.
const _longAmountDevices = <_Device>[
  (name: 'iPhone SE 세로', size: Size(375, 667), textScale: 1, padding: _zero),
  (name: 'iPhone 6.9 세로', size: Size(440, 956), textScale: 1, padding: _zero),
  (
    name: 'iPhone SE 세로 큰 글자',
    size: Size(375, 667),
    textScale: 1.3,
    padding: _zero,
  ),
];

/// 토스톤 리디자인(T-261028-010) 세로 초기 화면의 주요 위젯 위치·크기.
/// 제목은 왼쪽 정렬, 금액 라벨은 채움칸 안쪽(여백 18×배율)으로 들어간 값이다.
/// 옛 기준(f8f7c28, 다크·가운데 제목)은 같은 커밋의 git 이력에 있다.
/// 형식: `left,top widthxheight`.
const _portraitBaseline = <String, String>{
  'iPhone SE 세로':
      'title 20.01,10.35 143.54x20.00\n'
      'amountLabel 35.02,76.30 43.22x14.00\n'
      'placeholder 35.02,92.80 242.37x27.00\n'
      'peopleLabel 20.01,150.09 32.42x14.00\n'
      'count 164.65,181.94 45.69x23.00\n'
      'key1 57.65,444.10 18.59x26.00\n'
      'tab 40.00,641.00 45.00x16.00',
  'iPhone 6.9 세로':
      'title 25.20,13.05 181.60x25.00\n'
      'amountLabel 44.10,109.32 53.60x18.00\n'
      'placeholder 44.10,130.47 304.65x34.00\n'
      'peopleLabel 25.20,236.05 40.20x18.00\n'
      'count 191.10,276.25 57.80x29.00\n'
      'key1 67.26,693.05 23.35x33.00\n'
      'tab 50.83,930.00 45.00x16.00',
  'iPad 13 세로':
      'title 25.20,13.05 181.60x25.00\n'
      'amountLabel 44.10,151.33 53.60x18.00\n'
      'placeholder 44.10,172.48 304.65x34.00\n'
      'peopleLabel 25.20,383.05 40.20x18.00\n'
      'count 487.10,423.25 57.80x29.00\n'
      'key1 165.92,1113.05 23.35x33.00\n'
      'tab 149.50,1350.00 45.00x16.00',
};

/// 토스톤 리디자인(T-261028-010)에서 9를 열 번 입력한 세로 화면.
/// 라벨은 자연 크기, 금액 글자만 채움칸 안쪽 폭까지 줄어든 값이다.
const _longAmountBaseline = <String, String>{
  'iPhone SE 세로':
      'amountLabel 35.02,78.44 43.22x14.00\n'
      'amount 35.02,94.94 304.97x22.73',
  'iPhone 6.9 세로':
      'amountLabel 44.10,113.30 53.60x18.00\n'
      'amount 44.10,134.45 351.80x26.05',
  'iPhone SE 세로 큰 글자':
      'amountLabel 35.02,75.65 55.23x19.00\n'
      'amount 35.02,97.15 304.97x22.50',
};

Widget _host() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  darkTheme: AppTheme.light,
  themeMode: ThemeMode.light,
  home: const MainShell(),
);

Finder _inCalculator(Finder matching) =>
    find.descendant(of: find.byType(CalculatorScreen), matching: matching);

/// 주요 위젯의 전역 위치·크기. 소수 둘째 자리까지.
String _geometry(WidgetTester tester) {
  final targets = <String, Finder>{
    'title': _inCalculator(find.text('더치페이 계산기')),
    'amountLabel': _inCalculator(find.text('총 금액')),
    'placeholder': _inCalculator(find.text('얼마를 나눌까요?')),
    'peopleLabel': _inCalculator(find.text('인원수')),
    'count': _inCalculator(find.text('1명')),
    'key1': _inCalculator(find.text('1')),
    'tab': find.text('더치페이'),
  };
  final lines = <String>[];
  for (final MapEntry(:key, :value) in targets.entries) {
    expect(value, findsOneWidget, reason: key);
    final box = tester.getRect(value);
    lines.add(
      '$key '
      '${box.left.toStringAsFixed(2)},${box.top.toStringAsFixed(2)} '
      '${box.width.toStringAsFixed(2)}x${box.height.toStringAsFixed(2)}',
    );
  }
  return lines.join('\n');
}

String _rectLine(String key, Rect box) =>
    '$key '
    '${box.left.toStringAsFixed(2)},${box.top.toStringAsFixed(2)} '
    '${box.width.toStringAsFixed(2)}x${box.height.toStringAsFixed(2)}';

/// 금액 칸의 「총 금액」 라벨과 그 아래 금액 글자.
/// 1인당 결과 카드의 같은 문자열은 제외한다.
String _longAmountGeometry(WidgetTester tester) {
  const amountText = '9,999,999,999원';
  final labelFinder = _inCalculator(find.text('총 금액'));
  expect(labelFinder, findsOneWidget);
  final column = find
      .ancestor(of: labelFinder, matching: find.byType(Column))
      .evaluate()
      .first;
  final amountFinder = find.descendant(
    of: find.byElementPredicate((element) => element == column),
    matching: find.text(amountText),
  );
  expect(amountFinder, findsOneWidget, reason: '금액 칸의 금액 글자');
  return '${_rectLine('amountLabel', tester.getRect(labelFinder))}\n'
      '${_rectLine('amount', tester.getRect(amountFinder))}';
}

Future<void> _pumpDevice(WidgetTester tester, _Device device) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = device.size;
  tester.view.padding = device.padding;
  tester.view.viewPadding = device.padding;
  tester.platformDispatcher.textScaleFactorTestValue = device.textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(_host());
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // 광고 크기 조회는 테스트에서 응답이 없다. 배너는 숨은 채로 둔다.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/google_mobile_ads'),
          (call) async => null,
        );
  });

  for (final device in _devices) {
    testWidgets('계산기 탭이 ${device.name} 에서 넘치지 않는다', (tester) async {
      await _pumpDevice(tester, device);

      expect(_inCalculator(find.text('총 금액')), findsOneWidget);
      expect(_inCalculator(find.text('인원수')), findsOneWidget);
      expect(find.text('더치페이'), findsOneWidget);
      expect(find.text('미니앱'), findsOneWidget);

      // 결과가 나타난 뒤에도 넘치면 안 된다.
      await tester.tap(_inCalculator(find.text('1')));
      await tester.pump();
      await tester.tap(_inCalculator(find.byIcon(Icons.add)));
      await tester.pump();
      expect(_inCalculator(find.text('1원')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  Rect zeroKeyRect(WidgetTester tester) => tester.getRect(
    find
        .ancestor(
          of: _inCalculator(find.text('0')),
          matching: find.byType(Material),
        )
        .first,
  );

  for (final device in kLayoutDevices) {
    testWidgets('미니앱 버튼이 0 키를 가리지 않는다 ${device.name}', (tester) async {
      await pumpOnDevice(tester, device, _host());
      final buttonRect = tester.getRect(
        find.byKey(const ValueKey('miniapp-button')),
      );
      expect(
        buttonRect.overlaps(zeroKeyRect(tester)),
        isFalse,
        reason: '$buttonRect / ${zeroKeyRect(tester)}',
      );
    });

    testWidgets('0 키 아래 끝을 눌러도 0 이 들어간다 ${device.name}', (tester) async {
      await pumpOnDevice(tester, device, _host());
      await tester.tap(_inCalculator(find.text('1')));
      await tester.pump();
      final zero = zeroKeyRect(tester);
      await tester.tapAt(Offset(zero.center.dx, zero.bottom - 1));
      await tester.pumpAndSettle();
      // 금액 칸과 1인당 결과 카드에 같은 금액이 함께 보인다.
      expect(_inCalculator(find.text('10원')), findsNWidgets(2));
      expect(_inCalculator(find.text('1원')), findsNothing);
      expect(find.byKey(const ValueKey('miniapp-sheet')), findsNothing);
    });
  }

  for (final device in _devices.where((d) => _portraitNames.contains(d.name))) {
    testWidgets('세로 배치 기준점 ${device.name}', (tester) async {
      await _pumpDevice(tester, device);
      final geometry = _geometry(tester);
      expect(geometry, _portraitBaseline[device.name], reason: geometry);
    });
  }

  for (final device in _longAmountDevices) {
    testWidgets('세로 긴 금액 기준점 ${device.name}', (tester) async {
      await _pumpDevice(tester, device);
      for (var i = 0; i < 10; i++) {
        await tester.tap(_inCalculator(find.text('9')));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      final geometry = _longAmountGeometry(tester);
      expect(geometry, _longAmountBaseline[device.name], reason: geometry);
    });
  }
}
