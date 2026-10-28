import 'package:flutter/material.dart';

/// 더치페이 디자인 시스템 — 토스톤 라이트 (T-261028-010).
///
/// 2026-10-28 대종님 승인 목업(https://claude.ai/artifact/DviySYkv8cnuH8QUesXEAQ)으로
/// 다크 프리미엄(딥네이비+네온 청록, 항상 다크)에서 흰 바탕·Pretendard·둥근 카드의
/// 토스톤으로 전환. 브랜드 청록은 유지하되, 흰 바탕에서 읽히도록 글자·버튼용은
/// 한 단계 진한 [TossColors.accent]를 쓰고 네온 원색은 [TossColors.accentNeon]에 둔다.
///
/// [AppColors] = 화면에서 직접 참조하는 별칭 레이어.
/// [TossColors] = 명시적 상수 클래스 (ThemeData 빌드 + 위젯용). 멤버 이름은 옛
/// DarkColors 와 같게 유지해 화면 코드의 치환을 이름 바꾸기로 끝냈다.
class AppColors {
  AppColors._();

  // 베이스 (흰 바탕)
  static const bg = Color(0xFFFFFFFF); // scaffold
  static const surface = Color(0xFFFFFFFF); // 카드 (바탕과 같아 테두리로 구분)
  static const shadow = Color(0x14000000); // black 8% — 라이트 위 그림자
  static const divider = Color(0xFFF2F4F6); // 구분선/카드 테두리
  static const fill = Color(0xFFF2F4F6); // 옅은 채움 (칩·비활성)

  // 포인트 (더치페이 = 청록; 글자·버튼용은 진한 값)
  static const primary = Color(0xFF17A58F);
  static const primaryDark = Color(0xFF17A58F); // 라벨/공유버튼용
  static const primarySoft = Color(0xFFE3FAF6);

  // 텍스트
  static const textStrong = Color(0xFF191F28);
  static const textBody = Color(0xFF4E5968);
  static const textFaint = Color(0xFF8B95A1);

  // 상태
  static const danger = Color(0xFFF04452);
}

/// 토스톤 라이트 팔레트 — 명시적 상수 클래스 (ThemeData + 컴포넌트 스타일용).
/// AppColors 와 동일한 값이지만 의미 기반 이름 사용.
class TossColors {
  TossColors._();

  // 배경: 흰 바탕. (bgDeep 은 옛 이름 — scaffold 바탕을 뜻한다)
  static const bgDeep = Color(0xFFFFFFFF);
  static const bgBlack = Color(0xFFF2F4F6); // 한 톤 가라앉힌 면 (옛 그라데이션 끝)

  // 카드/표면
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF2F4F6); // 칩·비활성 버튼·채움칸

  // 악센트: 청록 (글자·버튼용 진한 값) + 네온 원색(브랜드 식별용)
  static const accent = Color(0xFF17A58F);
  static const accentNeon = Color(0xFF3DE0C8);
  static const accentSoft = Color(0xFFE3FAF6); // 결과 카드 바탕
  static const accentBorder = Color(0xFFBDEFE6); // 결과 카드 테두리
  static Color get accentGlow => accent.withValues(alpha: 0.12);

  // 텍스트
  static const textPrimary = Color(0xFF191F28);
  static const textSecondary = Color(0xFF4E5968);
  static const textFaint = Color(0xFF8B95A1);
  static const textQuaternary = Color(0xFFB0B8C1); // 자리표시 글자

  // 구분선: 연회색 (divider = 면 구분, border = 흰 카드 테두리)
  static const divider = Color(0xFFF2F4F6);
  static const border = Color(0xFFE5E8EB);
  static const keyFill = Color(0xFFF9FAFB); // 키패드 키 바탕
  static const shadow = Color(0x14000000);

  // 상태
  static const danger = Color(0xFFF04452);

  // 키패드 splash/highlight (라이트 위라 검정 기반)
  static Color get splashLight => const Color(0xFF000000).withValues(alpha: 0.06);
  static Color get highlightLight =>
      const Color(0xFF000000).withValues(alpha: 0.03);
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'Pretendard';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: TossColors.accent,
      brightness: Brightness.light,
    ).copyWith(
      surface: TossColors.surface,
      primary: TossColors.accent,
      onPrimary: Colors.white,
      onSurface: TossColors.textPrimary,
      error: TossColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: TossColors.bgDeep,
      textTheme: Typography.blackMountainView.apply(
        fontFamily: fontFamily,
        bodyColor: TossColors.textPrimary,
        displayColor: TossColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: TossColors.bgDeep,
        foregroundColor: TossColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: TossColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
