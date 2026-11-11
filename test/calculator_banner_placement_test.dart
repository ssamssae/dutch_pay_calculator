import 'dart:async';

import 'package:dutch_pay_calculator/screens/calculator_screen.dart';
import 'package:dutch_pay_calculator/services/ads_service.dart';
import 'package:dutch_pay_calculator/services/iap_service.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'support/layout_devices.dart';

const _adsChannel = MethodChannel('plugins.flutter.io/google_mobile_ads');

Widget _host() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  darkTheme: AppTheme.light,
  themeMode: ThemeMode.light,
  home: const CalculatorScreen(),
);

void main() {
  setUp(() {
    AdsService.debugReset();
    IapService.adsRemoved.value = false;
    mockAdsChannel();
  });

  tearDown(() {
    AdsService.debugReset();
    IapService.adsRemoved.value = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_adsChannel, null);
  });

  testWidgets('배너는 키패드보다 위에 있고 둘 사이에 내용 영역이 있다', (tester) async {
    final device = kLayoutDevices.firstWhere(
      (item) => item.name == 'iPhone SE 세로',
    );
    await pumpOnDevice(tester, device, _host());

    final banner = tester.getRect(
      find.byKey(const ValueKey('calculator-banner')),
    );
    final content = tester.getRect(
      find.byKey(const ValueKey('calculator-content')),
    );
    final keypad = tester.getRect(
      find.byKey(const ValueKey('calculator-keypad')),
    );

    expect(banner.bottom, lessThanOrEqualTo(content.top));
    expect(content.bottom, lessThanOrEqualTo(keypad.top));
    expect(banner.top, lessThan(keypad.top));
  });

  testWidgets('광고 칸과 가장 가까운 버튼 사이에 세로 여백 8 이상이 있다', (tester) async {
    final gate = Completer<void>();
    AdsService.debugLoadBanner = (_) => gate.future;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_adsChannel, (call) async {
          if (call.method == 'AdSize#getLargeAnchoredAdaptiveBannerAdSize') {
            return 50;
          }
          return null;
        });

    final device = kLayoutDevices.firstWhere(
      (item) => item.name == 'iPhone SE 세로',
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = device.size;
    tester.view.padding = device.padding;
    tester.view.viewPadding = device.padding;
    tester.platformDispatcher.textScaleFactorTestValue = device.textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_host());
    await tester.pump();

    final slot = tester.getRect(
      find.byKey(const ValueKey('adaptive-banner-slot')),
    );
    final button = tester.getRect(find.byTooltip('1명 줄이기'));
    final content = tester.getRect(
      find.byKey(const ValueKey('calculator-content')),
    );
    final keypad = tester.getRect(
      find.byKey(const ValueKey('calculator-keypad')),
    );

    expect(button.top - slot.bottom, greaterThanOrEqualTo(8));
    expect(slot.bottom, lessThanOrEqualTo(content.top));
    expect(content.bottom, lessThanOrEqualTo(keypad.top));
    expect(find.byType(AdWidget), findsNothing);

    gate.complete();
    await tester.pump();
  });
}
