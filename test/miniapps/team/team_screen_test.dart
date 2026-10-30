import 'dart:math';

import 'package:dutch_pay_calculator/miniapps/team/team_controller.dart';
import 'package:dutch_pay_calculator/miniapps/team/team_screen.dart';
import 'package:dutch_pay_calculator/services/ads_service.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/layout_devices.dart';

Future<TeamController> _controller() async {
  SharedPreferences.setMockInitialValues({});
  return TeamController(
    await SharedPreferences.getInstance(),
    random: Random(3),
  );
}

Widget _app(TeamController controller) {
  return MaterialApp(
    theme: AppTheme.light,
    debugShowCheckedModeBanner: false,
    home: TeamScreen(controller: controller),
  );
}

/// 첫 화면의 「열기」 버튼으로 [TeamScreen] 을 띄운다.
Widget _launcher(TeamController controller) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TeamScreen(controller: controller),
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
          of: find.byKey(const ValueKey('split')),
          matching: find.byType(Text),
        ),
      )
      .data!;
}

void main() {
  setUp(mockAdsChannel);

  testWidgets('나누기 → 팀 카드가 팀 수만큼, 이름이 다 들어 있다', (tester) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));

    expect(find.text('팀 나누기'), findsOneWidget);
    expect(find.text('무작위로 공평하게 팀을 나눠요'), findsOneWidget);
    expect(_buttonLabel(tester), '나누기');
    expect(find.byKey(const ValueKey('team-0')), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('person-0')), '민수');
    await tester.enterText(find.byKey(const ValueKey('person-1')), '지영');
    await tester.pump();
    expect(controller.names.take(2), ['민수', '지영']);

    await tester.tap(find.byKey(const ValueKey('person-add')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('plus-teams')));
    await tester.pump();
    expect(controller.names, hasLength(5));
    expect(controller.teamCount, 3);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('count-teams'))).data,
      '3팀',
    );

    await tester.tap(find.byKey(const ValueKey('split')));
    await tester.pumpAndSettle();

    expect(_buttonLabel(tester), '다시 나누기');
    for (var t = 0; t < 3; t++) {
      final card = find.byKey(ValueKey('team-$t'));
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('${t + 1}팀')),
        findsOneWidget,
      );
    }
    expect(find.byKey(const ValueKey('team-3')), findsNothing);
    for (final label in ['민수', '지영', '3번', '4번', '5번']) {
      final inCards = [
        for (var t = 0; t < 3; t++)
          ...tester.widgetList(
            find.descendant(
              of: find.byKey(ValueKey('team-$t')),
              matching: find.text(label),
            ),
          ),
      ];
      expect(inCards, hasLength(1), reason: label);
    }
  });

  testWidgets('나누기를 빠르게 두 번 눌러도 한 번만 나눈다', (tester) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));

    var notified = 0;
    controller.addListener(() => notified++);
    await tester.tap(find.byKey(const ValueKey('split')));
    await tester.tap(find.byKey(const ValueKey('split')));
    await tester.pump();
    expect(notified, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('split')));
    await tester.pump();
    expect(notified, 2);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('2명이면 빼기가, 30명이면 추가가 꺼진다', (tester) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    controller
      ..removePerson(0)
      ..removePerson(0);
    await tester.pumpWidget(_app(controller));

    IconButton remove(int i) =>
        tester.widget<IconButton>(find.byKey(ValueKey('person-remove-$i')));
    expect(remove(0).onPressed, isNull);
    expect(remove(1).onPressed, isNull);

    while (controller.names.length < TeamController.maxPeople) {
      controller.addPerson();
    }
    await tester.pump();
    final add = tester.widget<TextButton>(
      find.byKey(const ValueKey('person-add')),
    );
    expect(add.onPressed, isNull);
    expect(remove(0).onPressed, isNotNull);
  });

  testWidgets('지우면 남은 이름 칸이 그대로 따라온다', (tester) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    for (var i = 0; i < 4; i++) {
      controller.renamePerson(i, 'p$i');
    }
    await tester.pumpWidget(_app(controller));

    await tester.tap(find.byKey(const ValueKey('person-remove-1')));
    await tester.pump();

    expect(controller.names, ['p0', 'p2', 'p3']);
    for (var i = 0; i < 3; i++) {
      final field = tester.widget<TextField>(find.byKey(ValueKey('person-$i')));
      expect(field.controller!.text, controller.names[i]);
    }
  });

  testWidgets('나갔다 와도 결과가 남는다', (tester) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_launcher(controller));

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('person-0')), '민수');
    await tester.tap(find.byKey(const ValueKey('split')));
    await tester.pumpAndSettle();
    final teams = controller.teams;
    expect(teams, isNotNull);

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.byType(TeamScreen), findsNothing);

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(controller.teams, same(teams));
    expect(find.byKey(const ValueKey('team-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-1')), findsOneWidget);
    expect(_buttonLabel(tester), '다시 나누기');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('person-0')))
          .controller!
          .text,
      '민수',
    );
  });

  for (final device in kLayoutDevices) {
    testWidgets('30명 넘치지 않는다 ${device.name}', (tester) async {
      final controller = await _controller();
      addTearDown(controller.dispose);
      while (controller.names.length < TeamController.maxPeople) {
        controller.addPerson();
      }
      for (var i = 0; i < TeamController.maxPeople; i++) {
        controller.renamePerson(i, '아주긴이름을가진사람${i + 1}번째참가자');
      }
      controller.setTeamCount(TeamController.maxTeams);
      controller.split();

      await pumpOnDevice(tester, device, _app(controller));
      expect(find.text('팀 나누기'), findsOneWidget);
      expect(find.byType(AdaptiveBanner), findsOneWidget);
      expect(
        tester.getRect(find.byType(AdaptiveBanner)).bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(const ValueKey('split'))).top,
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('person-29')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
