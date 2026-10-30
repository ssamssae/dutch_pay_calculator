import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dutch_pay_calculator/services/ads_service.dart';
import 'package:dutch_pay_calculator/widgets/mini_app_scaffold.dart';

import '../support/layout_devices.dart';

void main() {
  setUp(mockAdsChannel);

  testWidgets('MiniAppScaffold: 제목·설명·뒤로·배너·bottom 순서', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MiniAppScaffold(
                      title: '룰렛',
                      subtitle: '누가 쏠지 돌려서 정해요',
                      body: Text('body'),
                      bottom: Text('bottom'),
                    ),
                  ),
                ),
                child: const Text('첫 화면'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('첫 화면'));
    await tester.pumpAndSettle();

    expect(find.text('룰렛'), findsOneWidget);
    expect(find.text('누가 쏠지 돌려서 정해요'), findsOneWidget);
    expect(find.byTooltip('뒤로'), findsOneWidget);
    expect(find.byKey(const ValueKey('miniapp-back')), findsOneWidget);
    expect(find.byType(AdaptiveBanner), findsOneWidget);
    expect(
      tester.getRect(find.text('body')).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(AdaptiveBanner)).top),
    );
    expect(
      tester.getRect(find.byType(AdaptiveBanner)).bottom,
      lessThanOrEqualTo(tester.getRect(find.text('bottom')).top),
    );

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('첫 화면'), findsOneWidget);
    expect(find.byType(MiniAppScaffold), findsNothing);
  });

  testWidgets('MiniAppScaffold: bottom 이 없으면 배너까지만 그린다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiniAppScaffold(title: '계산기', subtitle: '설명', body: Text('body')),
      ),
    );

    expect(find.byType(AdaptiveBanner), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  for (final device in kLayoutDevices) {
    testWidgets('MiniAppScaffold 가 ${device.name} 에서 넘치지 않는다', (tester) async {
      await pumpOnDevice(
        tester,
        device,
        const MaterialApp(
          home: MiniAppScaffold(
            title: '룰렛',
            subtitle: '누가 쏠지 돌려서 정해요',
            body: Text('body'),
            bottom: Text('bottom'),
          ),
        ),
      );
      expect(find.text('룰렛'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
