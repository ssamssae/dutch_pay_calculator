import 'dart:convert';
import 'dart:math';

import 'package:dutch_pay_calculator/miniapps/team/team_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TeamController> _controller([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return TeamController(
    await SharedPreferences.getInstance(),
    random: Random(7),
  );
}

void main() {
  test('처음 값 = 빈 이름 4개·2팀', () async {
    final controller = await _controller();
    expect(controller.names, ['', '', '', '']);
    expect(controller.labels, ['1번', '2번', '3번', '4번']);
    expect(controller.teamCount, 2);
    expect(controller.teams, isNull);
  });

  test('나누면 팀 인원 차 ≤ 1, 모두 정확히 한 번', () async {
    final controller = await _controller();
    for (
      var people = TeamController.minPeople;
      people <= TeamController.maxPeople;
      people++
    ) {
      while (controller.names.length < people) {
        controller.addPerson();
      }
      while (controller.names.length > people) {
        controller.removePerson(controller.names.length - 1);
      }
      for (var i = 0; i < people; i++) {
        controller.renamePerson(i, 'p$i');
      }
      for (
        var teams = TeamController.minTeams;
        teams <= min(TeamController.maxTeams, people);
        teams++
      ) {
        controller.setTeamCount(teams);
        controller.split();
        final result = controller.teams!;
        expect(result, hasLength(teams), reason: '$people명 $teams팀');
        final sizes = [for (final team in result) team.length];
        expect(
          sizes.reduce(max) - sizes.reduce(min),
          lessThanOrEqualTo(1),
          reason: '$people명 $teams팀 $sizes',
        );
        final members = [for (final team in result) ...team]..sort();
        final expected = [for (var i = 0; i < people; i++) 'p$i']..sort();
        expect(members, expected, reason: '$people명 $teams팀');
      }
    }
  });

  test('빈 이름은 N번', () async {
    final controller = await _controller();
    controller.renamePerson(0, '민수');
    expect(controller.labels[0], '민수');
    expect(controller.labels[2], '3번');
    controller.renamePerson(1, '   ');
    expect(controller.labels[1], '2번');
  });

  test('사람을 지우면 팀 수가 따라 준다', () async {
    final controller = await _controller();
    controller.removePerson(0);
    expect(controller.names, hasLength(3));
    controller.setTeamCount(3);
    expect(controller.teamCount, 3);

    controller.removePerson(0);
    expect(controller.names, hasLength(2));
    expect(controller.teamCount, 2);

    controller.removePerson(0);
    expect(controller.names, hasLength(TeamController.minPeople));
  });

  test('사람 수 범위', () async {
    final controller = await _controller();
    for (var i = 0; i < 40; i++) {
      controller.addPerson();
    }
    expect(controller.names, hasLength(TeamController.maxPeople));
  });

  test('팀 수 범위', () async {
    final controller = await _controller();
    controller.setTeamCount(1);
    expect(controller.teamCount, 2);
    controller.setTeamCount(7);
    expect(controller.teamCount, 4);

    for (var i = 0; i < 6; i++) {
      controller.addPerson();
    }
    controller.setTeamCount(7);
    expect(controller.teamCount, 6);
  });

  test('편집하면 지난 결과가 사라진다', () async {
    final controller = await _controller();
    void splitAgain() {
      controller.split();
      expect(controller.teams, isNotNull);
    }

    splitAgain();
    controller.renamePerson(0, '민수');
    expect(controller.teams, isNull);

    splitAgain();
    controller.addPerson();
    expect(controller.teams, isNull);

    splitAgain();
    controller.removePerson(0);
    expect(controller.teams, isNull);

    splitAgain();
    controller.setTeamCount(3);
    expect(controller.teams, isNull);
  });

  test('바꾼 값을 저장하고 다시 읽는다', () async {
    final controller = await _controller();
    controller.renamePerson(0, '민수');
    controller.addPerson();
    controller.setTeamCount(3);

    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString(TeamController.storageKey)!), {
      'names': ['민수', '', '', '', ''],
      'teams': 3,
    });

    final again = TeamController(prefs);
    expect(again.names, ['민수', '', '', '', '']);
    expect(again.teamCount, 3);
    expect(again.teams, isNull);
  });

  test('깨진 저장값이면 처음 값', () async {
    final broken = [
      jsonEncode({
        'names': ['a'],
        'teams': 2,
      }),
      jsonEncode({
        'names': ['a', 'b', 'c', 'd'],
        'teams': 7,
      }),
      jsonEncode({'names': List.filled(31, 'a'), 'teams': 2}),
      jsonEncode({
        'names': ['a', 'b', 'c'],
        'teams': 1,
      }),
      jsonEncode({
        'names': ['a', 'b', 3],
        'teams': 2,
      }),
      jsonEncode({
        'names': ['a', 'b'],
        'teams': '2',
      }),
      jsonEncode(['a', 'b']),
      '{oops',
    ];
    for (final raw in broken) {
      final controller = await _controller({TeamController.storageKey: raw});
      expect(controller.names, ['', '', '', ''], reason: raw);
      expect(controller.teamCount, 2, reason: raw);
    }
  });
}
