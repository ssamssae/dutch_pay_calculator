// T-261103-022 — 사다리 아래 결과 가리기(눌러서 확인)·가운데 가로줄 직접 긋기.
//
// ■왜
//   대종님 2026-11-03 18:2x 텔레그램(사다리 화면 사진): 「사다리 아래쪽 제비뽑기처럼
//   터치해서 확인하게 바꿔줘」「미리 답을 알 수 있잖아」「가운데 선을 추가할 수 있게
//   해줘 터치해서」. 결과 칸이 처음부터 보이면 사다리를 눈으로 따라가 답을 미리 안다.
//
// ■무엇을 지키나
//   (a) 결과 칸은 처음에 「?」로 가려지고, 누르면 그 칸만 열린다
//   (b) 「모두 보기」는 경로를 다 그린 뒤 결과 칸도 모두 연다
//   (c) 사다리를 타기 전 가운데를 누르면 가로줄이 하나 늘고, 탄 뒤에는 늘지 않는다
//   (d) 「결과 복사」는 연 결과만 복사한다(복사로 미리 답을 알 수 없게)
//   (e) 가로줄 긋기 규칙: 이미 있거나 같은 행 이웃과 붙는 자리는 막는다
import 'package:dutch_pay_calculator/ladder/ladder.dart';
import 'package:dutch_pay_calculator/ladder/ladder_painter.dart';
import 'package:dutch_pay_calculator/ladder/ladder_round.dart';
import 'package:dutch_pay_calculator/ladder/ladder_setup.dart';
import 'package:dutch_pay_calculator/screens/ladder_screen.dart';
import 'package:dutch_pay_calculator/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _setup = LadderSetup(
  players: const ['김태상', '강대종'],
  results: const [ResultSlot('12호차', 1), ResultSlot('14호차', 1)],
);

int _rungTotal(Ladder ladder) => [
  for (final row in ladder.rungs)
    for (final on in row)
      if (on) 1,
].length;

/// 화면에 그려진 사다리(LadderPainter.ladder).
Ladder _ladderOf(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.painter)
    .whereType<LadderPainter>()
    .single
    .ladder;

Future<void> _pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: LadderScreen(setup: _setup, seed: 7),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Ladder.canAddRung·withRung', () {
    final ladder = Ladder(
      columns: 3,
      rungs: [
        [true, false],
        [false, false],
        [false, true],
      ],
    );

    test('빈 자리에 하나 더 긋는다', () {
      expect(ladder.canAddRung(1, 0), isTrue);
      final next = ladder.withRung(1, 0);
      expect(next.rungs[1], [true, false]);
      expect(ladder.rungs[1], [false, false], reason: '원래 사다리는 그대로');
    });

    test('이미 있거나 이웃과 붙는 자리는 막는다', () {
      expect(ladder.canAddRung(0, 0), isFalse, reason: '이미 있음');
      expect(ladder.canAddRung(0, 1), isFalse, reason: '왼쪽 가로줄과 붙음');
      expect(ladder.canAddRung(2, 0), isFalse, reason: '오른쪽 가로줄과 붙음');
      expect(() => ladder.withRung(0, 1), throwsStateError);
    });

    test('LadderRound.withRung 은 이름·결과 칸 순서를 그대로 둔다', () {
      final round = LadderRound.start(_setup, 7);
      final rows = round.ladder.rows;
      final free = [
        for (var r = 0; r < rows; r++)
          if (round.ladder.canAddRung(r, 0)) r,
      ];
      final next = round.withRung(free.first, 0);
      expect(next.names, round.names);
      expect(next.bottom, round.bottom);
      expect(_rungTotal(next.ladder), _rungTotal(round.ladder) + 1);
    });
  });

  testWidgets('(a) 결과 칸은 처음에 가려져 있고 누르면 그 칸만 열린다', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('12호차'), findsNothing);
    expect(find.text('14호차'), findsNothing);
    expect(find.text('?'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('result-cell-0')));
    await tester.pumpAndSettle();

    final opened = LadderRound.start(_setup, 7).bottom[0];
    expect(find.text(opened), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('(b) 모두 보기는 경로를 다 그린 뒤 결과 칸도 모두 연다', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('reveal-all')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('?'), findsNWidgets(2), reason: '타는 중에는 아직 가려 둔다');

    await tester.pumpAndSettle();
    expect(find.text('?'), findsNothing);
    expect(find.textContaining('→ 12호차'), findsOneWidget);
    expect(find.textContaining('→ 14호차'), findsOneWidget);
  });

  testWidgets('(c) 타기 전에는 가운데를 눌러 가로줄을 긋고, 탄 뒤에는 못 긋는다', (tester) async {
    await _pumpScreen(tester);
    final board = find.byKey(const ValueKey('ladder-board'));
    final before = _rungTotal(_ladderOf(tester));

    // 두 세로줄 사이 한가운데(가로 50%)를 위에서 여러 높이로 눌러 본다.
    final box = tester.getRect(board);
    var added = 0;
    for (final y in [0.2, 0.5, 0.8]) {
      await tester.tapAt(
        Offset(box.left + box.width * 0.5, box.top + box.height * y),
      );
      await tester.pump();
      added = _rungTotal(_ladderOf(tester)) - before;
      if (added > 0) break;
    }
    expect(added, 1, reason: '빈 행 하나에 가로줄 하나');

    // 사다리를 타면 판이 시작돼 더 긋지 않는다.
    await tester.tap(find.byKey(const ValueKey('name-0')));
    await tester.pumpAndSettle();
    final started = _rungTotal(_ladderOf(tester));
    await tester.tapAt(
      Offset(box.left + box.width * 0.5, box.top + box.height * 0.35),
    );
    await tester.pump();
    expect(_rungTotal(_ladderOf(tester)), started);
    expect(find.text('가로줄은 사다리를 타기 전에만 그을 수 있어요'), findsOneWidget);
  });

  testWidgets('(d) 결과 복사는 연 결과만 복사한다', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pumpScreen(tester);

    // 아무것도 안 열었으면 복사하지 않는다.
    await tester.tap(find.byKey(const ValueKey('copy')));
    await tester.pumpAndSettle();
    expect(copied, isEmpty);
    expect(find.text('아직 확인한 결과가 없어요'), findsOneWidget);
    // 안내 띠가 아래 버튼을 덮으므로 닫고 이어 간다.
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // 0번 참가자가 타고, 도착한 칸을 연 뒤에는 그 사람 줄만 복사한다.
    final round = LadderRound.start(_setup, 7);
    await tester.tap(find.byKey(const ValueKey('name-0')));
    await tester.pumpAndSettle();
    final end = round.ladder.endColumn(0);
    await tester.tap(find.byKey(ValueKey('result-cell-$end')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('copy')));
    await tester.pumpAndSettle();
    expect(copied, ['김태상 → ${round.resultFor(0)}']);
  });
}
