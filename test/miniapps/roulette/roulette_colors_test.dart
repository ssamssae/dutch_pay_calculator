// T-261103-023 — 룰렛 칸을 알록달록하게, 위 화살표를 눈에 띄게.
//
// ■왜
//   대종님 2026-11-03 18:31 텔레그램(룰렛 사진, 청록 세 톤 원판): 「룰렛 색깔을 좀
//   다르게 알록달록 해줘 그리고 위에 화살표도 검은색이나 그렇게 좀 눈에 띄게」.
//
// ■무엇을 지키나
//   (a) 2~16칸 어느 원판이든 맞닿은 두 칸(마지막↔첫 칸 포함)은 색이 다르다
//   (b) 칸 색은 청록 한 계열이 아니라 서로 다른 색이 여럿 쓰인다
//   (c) 화살표는 검정에 가까운 색이다
import 'package:dutch_pay_calculator/miniapps/roulette/roulette_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('(a) 맞닿은 두 칸은 색이 다르다 — 마지막 칸과 첫 칸 포함', () {
    for (var count = 2; count <= 16; count++) {
      for (var i = 0; i < count; i++) {
        final next = (i + 1) % count;
        expect(
          RouletteWheel.sliceColor(i, count),
          isNot(RouletteWheel.sliceColor(next, count)),
          reason: '$count칸 원판의 $i·$next 칸',
        );
      }
    }
  });

  test('(b) 5칸 원판은 다섯 칸 모두 다른 색이다', () {
    final colors = {for (var i = 0; i < 5; i++) RouletteWheel.sliceColor(i, 5)};
    expect(colors, hasLength(5));
  });

  test('(c) 화살표는 검정에 가까운 어두운 색이다', () {
    expect(
      ThemeData.estimateBrightnessForColor(RouletteWheel.pointerColor),
      Brightness.dark,
    );
    expect(RouletteWheel.pointerColor.computeLuminance(), lessThan(0.05));
  });
}
