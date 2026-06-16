import 'package:flutter/material.dart';

/// 더치페이 디자인 시스템 (다크 프리미엄 — 폰 테마와 무관하게 항상 다크).
/// 포인트 = 청록 네온(#3DE0C8), 베이스 = 딥네이비 (Revolut 결).
///
/// [AppColors] = 현재 화면에서 직접 참조하는 다크 팔레트 (별칭 레이어).
/// [DarkColors] = 명시적 다크 프리미엄 상수 클래스 (ThemeData 빌드 + 신규 위젯용).
class AppColors {
  AppColors._();

  // 베이스 (다크 프리미엄, 딥네이비)
  static const bg = Color(0xFF0A1422); // scaffold 딥네이비
  static const surface = Color(0xFF13203A); // 카드 (한 톤 밝은 네이비)
  static const shadow = Color(0x33000000); // black 20% — 다크 위 그림자
  static const divider = Color(0x14FFFFFF); // white 8% 구분선/보더
  static const fill = Color(0xFF1A2D4A); // 옅은 다크 채움 (elevated)

  // 포인트 (더치페이 = 청록 네온, 다크 위 대비)
  static const primary = Color(0xFF3DE0C8);
  static const primaryDark = Color(0xFF3DE0C8); // 라벨/공유버튼용
  static Color get primarySoft => primary.withValues(alpha: 0.16);

  // 텍스트
  static const textStrong = Color(0xFFF5F7FA);
  static const textBody = Color(0xFF8A98B0); // 회청
  static const textFaint = Color(0xFF4A5568);

  // 상태
  static const danger = Color(0xFFEF4444);
}

/// 다크 프리미엄 팔레트 — 명시적 상수 클래스 (ThemeData + 컴포넌트 스타일용).
/// AppColors 와 동일한 값이지만 의미 기반 이름 사용.
class DarkColors {
  DarkColors._();

  // 배경: 딥네이비→블랙 그라데이션
  static const bgDeep = Color(0xFF0A1422);
  static const bgBlack = Color(0xFF05080F);

  // 카드/표면
  static const surface = Color(0xFF13203A);
  static const surfaceElevated = Color(0xFF1A2D4A);

  // 악센트: 청록 네온
  static const accent = Color(0xFF3DE0C8);
  static Color get accentSoft =>
      const Color(0xFF3DE0C8).withValues(alpha: 0.12);
  static Color get accentBorder =>
      const Color(0xFF3DE0C8).withValues(alpha: 0.35);
  static Color get accentGlow =>
      const Color(0xFF3DE0C8).withValues(alpha: 0.20);

  // 텍스트
  static const textPrimary = Color(0xFFF5F7FA);
  static const textSecondary = Color(0xFF8A98B0);
  static const textFaint = Color(0xFF4A5568);

  // 구분선: 화이트 8%
  static const divider = Color(0x14FFFFFF);
  static const shadow = Color(0x33000000);

  // 상태
  static const danger = Color(0xFFEF4444);

  // 키패드 splash/highlight
  static Color get splashLight =>
      const Color(0xFFFFFFFF).withValues(alpha: 0.06);
  static Color get highlightLight =>
      const Color(0xFFFFFFFF).withValues(alpha: 0.03);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: DarkColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: DarkColors.surface,
      primary: DarkColors.accent,
      onPrimary: DarkColors.bgDeep,
      onSurface: DarkColors.textPrimary,
      error: DarkColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DarkColors.bgDeep,
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: DarkColors.textPrimary,
        displayColor: DarkColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: DarkColors.bgDeep,
        foregroundColor: DarkColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
