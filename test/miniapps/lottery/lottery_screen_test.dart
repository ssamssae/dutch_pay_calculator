import 'dart:math';

import 'package:dutch_pay_calculator/miniapps/lottery/lottery_controller.dart';
import 'package:dutch_pay_calculator/miniapps/lottery/lottery_screen.dart';
import 'package:dutch_pay_calculator/services/ads_service.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/layout_devices.dart';

Future<LotteryController> _controller({Random? random}) async {
  SharedPreferences.setMockInitialValues({});
  return LotteryController(
    await SharedPreferences.getInstance(),
    random: random ?? Random(7),
  );
}

Widget _app(LotteryController controller) {
  return MaterialApp(
    theme: AppTheme.light,
    debugShowCheckedModeBanner: false,
    home: LotteryScreen(controller: controller),
  );
}

/// 첫 화면의 「열기」 버튼으로 [LotteryScreen] 을 띄운다.
Widget _launcher(LotteryController controller) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LotteryScreen(controller: controller),
              ),
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
}

String _buttonLabel(WidgetTester tester) {
  return tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('shuffle')),
          matching: find.byType(Text),
        ),
      )
      .data!;
}

String _count(WidgetTester tester, String id) {
  return tester.widget<Text>(find.byKey(ValueKey('count-$id'))).data!;
}

Color _ticketColor(WidgetTester tester, int index) {
  return tester.widget<Material>(find.byKey(ValueKey('ticket-$index'))).color!;
}

void main() {
  setUp(mockAdsChannel);

  Future<void> pumpScreen(
    WidgetTester tester,
    LotteryController controller,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
  }

  testWidgets('섞기 → 카드 4장, 누르면 당첨/꽝, 상태 글', (tester) async {
    final log = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      log.add(call);
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final controller = await _controller();
    addTearDown(controller.dispose);
    await pumpScreen(tester, controller);

    expect(find.text('제비뽑기'), findsOneWidget);
    expect(find.text('당첨 제비를 하나씩 뽑아요'), findsOneWidget);
    expect(_count(tester, 'total'), '4장');
    expect(_count(tester, 'winners'), '당첨 1장');
    expect(_buttonLabel(tester), '섞기');
    expect(find.byKey(const ValueKey('ticket-0')), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('lottery-status'))).data,
      '남은 제비 4장 · 남은 당첨 1장',
    );

    await tester.tap(find.byKey(const ValueKey('shuffle')));
    await tester.pump();

    expect(controller.board, isNotNull);
    expect(controller.board, hasLength(4));
    for (var i = 0; i < 4; i++) {
      expect(find.byKey(ValueKey('ticket-$i')), findsOneWidget);
      expect(_ticketColor(tester, i), TossColors.accentSoft);
      expect(
        find.descendant(
          of: find.byKey(ValueKey('ticket-$i')),
          matching: find.text('제비'),
        ),
        findsOneWidget,
      );
    }
    expect(find.byKey(const ValueKey('ticket-4')), findsNothing);

    final win = controller.board![0];
    await tester.tap(find.byKey(const ValueKey('ticket-0')));
    await tester.pump();

    final face = win ? '당첨' : '꽝';
    final ticket = find.byKey(const ValueKey('ticket-0'));
    expect(
      find.descendant(of: ticket, matching: find.text(face)),
      findsOneWidget,
    );
    expect(
      _ticketColor(tester, 0),
      win ? TossColors.accent : TossColors.surfaceElevated,
    );
    expect(
      tester
          .widget<Text>(find.descendant(of: ticket, matching: find.text(face)))
          .style!
          .color,
      win ? Colors.white : TossColors.textFaint,
    );
    expect(controller.revealed, {0});
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('lottery-status'))).data,
      '남은 제비 3장 · 남은 당첨 ${win ? 0 : 1}장',
    );

    final haptics = log.where(
      (call) =>
          call.method == 'HapticFeedback.vibrate' &&
          call.arguments == 'HapticFeedbackType.mediumImpact',
    );
    expect(haptics, hasLength(1));

    await tester.tap(ticket);
    await tester.pump();
    expect(controller.revealed, {0});
    expect(haptics, hasLength(1));
  });

  testWidgets('섞은 뒤 버튼 = 다시 섞기', (tester) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    await pumpScreen(tester, controller);

    expect(_buttonLabel(tester), '섞기');

    await tester.tap(find.byKey(const ValueKey('shuffle')));
    await tester.pump();

    expect(_buttonLabel(tester), '다시 섞기');
    expect(find.byKey(const ValueKey('ticket-3')), findsOneWidget);
  });

  testWidgets('섞기를 빠르게 두 번 눌러도 한 번만 섞는다', (tester) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));

    var notified = 0;
    controller.addListener(() => notified++);
    await tester.tap(find.byKey(const ValueKey('shuffle')));
    await tester.tap(find.byKey(const ValueKey('shuffle')));
    await tester.pump();
    expect(notified, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('shuffle')));
    await tester.pump();
    expect(notified, 2);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('나갔다 와도 판이 남는다', (tester) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_launcher(controller));

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shuffle')));
    await tester.pumpAndSettle();
    final board = controller.board;
    expect(board, isNotNull);

    await tester.tap(find.byKey(const ValueKey('ticket-1')));
    await tester.pumpAndSettle();
    final face = board![1] ? '당첨' : '꽝';
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ticket-1')),
        matching: find.text(face),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.byType(LotteryScreen), findsNothing);

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(controller.board, same(board));
    expect(controller.revealed, {1});
    expect(_buttonLabel(tester), '다시 섞기');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ticket-1')),
        matching: find.text(face),
      ),
      findsOneWidget,
    );
    expect(_ticketColor(tester, 0), TossColors.accentSoft);
    expect(find.byKey(const ValueKey('ticket-3')), findsOneWidget);
  });

  for (final device in kLayoutDevices) {
    testWidgets('20장 넘치지 않는다 ${device.name}', (tester) async {
      final controller = await _controller();
      addTearDown(controller.dispose);
      controller.setTotal(20);
      controller.setWinners(7);
      controller.shuffle();

      await pumpOnDevice(tester, device, _app(controller));

      expect(find.text('제비뽑기'), findsOneWidget);
      expect(find.text('당첨 제비를 하나씩 뽑아요'), findsOneWidget);
      expect(find.byType(AdaptiveBanner), findsOneWidget);
      expect(
        tester.getRect(find.byType(AdaptiveBanner)).bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(const ValueKey('shuffle'))).top,
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('ticket-19')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ticket-19')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
