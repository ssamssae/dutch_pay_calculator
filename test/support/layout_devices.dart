import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 논리 화면 크기. 테스트 뷰 배율은 1이라 물리 크기와 같다.
/// 안전 영역은 물리 픽셀이며, 배율 1에서는 논리 픽셀과 같다.
typedef LayoutDevice = ({
  String name,
  Size size,
  double textScale,
  FakeViewPadding padding,
});

const _zero = FakeViewPadding.zero;

/// 배치 테스트 공용 8개 크기. `calculator_layout_test.dart` 와 같은 값 · 이름.
const List<LayoutDevice> kLayoutDevices = [
  (name: 'iPhone SE 세로', size: Size(375, 667), textScale: 1, padding: _zero),
  (name: 'iPhone 6.9 세로', size: Size(440, 956), textScale: 1, padding: _zero),
  (name: 'iPhone SE 가로', size: Size(667, 375), textScale: 1, padding: _zero),
  (name: 'iPhone 6.9 가로', size: Size(956, 440), textScale: 1, padding: _zero),
  (
    name: 'iPhone 6.9 가로 안전영역',
    size: Size(956, 440),
    textScale: 1,
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

/// [device] 크기 · 글자 배율 · 안전 영역으로 [app] 을 띄운다.
Future<void> pumpOnDevice(
  WidgetTester tester,
  LayoutDevice device,
  Widget app,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = device.size;
  tester.view.padding = device.padding;
  tester.view.viewPadding = device.padding;
  tester.platformDispatcher.textScaleFactorTestValue = device.textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// 광고 크기 조회는 테스트에서 응답이 없다. 배너는 숨은 채로 둔다.
void mockAdsChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/google_mobile_ads'),
        (call) async => null,
      );
}
