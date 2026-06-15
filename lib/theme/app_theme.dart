import 'package:flutter/material.dart';

/// 더치페이 디자인 시스템 (라이트). 약먹자와 같은 구조, 포인트 컬러만 다름(인디고).
class AppColors {
  AppColors._();

  // 베이스
  static const bg = Color(0xFFF7F8FA); // scaffold 오프화이트
  static const surface = Color(0xFFFFFFFF); // 카드
  static const shadow = Color(0x14000000); // black 8% — 옅은 그림자
  static const divider = Color(0x14000000); // 키패드 구분선
  static const fill = Color(0xFFF1F3F5); // 옅은 회색 채움

  // 포인트 (더치페이 = 인디고)
  static const primary = Color(0xFF4F6DF5);
  static const primaryDark = Color(0xFF3B53D6); // 텍스트/대비용
  static Color get primarySoft => primary.withValues(alpha: 0.12);

  // 텍스트
  static const textStrong = Color(0xFF1A1D24);
  static const textBody = Color(0xFF4B5563);
  static const textFaint = Color(0xFF9CA3AF);

  // 상태
  static const danger = Color(0xFFEF4444);
}

/// 다크 프리미엄 팔레트 (Revolut 결, 청록 네온 #3DE0C8)
class DarkColors {
  DarkColors._();

  // 배경: 딥네이비→블랙 그라데이션
  static const bgDeep = Color(0xFF0A1422);
  static const bgBlack = Color(0xFF05080F);

  // 카드/표면: 한 톤 밝은 네이비, 살짝 글래스 느낌
  static const surface = Color(0xFF13203A);
  static const surfaceElevated = Color(0xFF1A2D4A);

  // 악센트: 청록 네온
  static const accent = Color(0xFF3DE0C8);
  static Color get accentSoft => const Color(0xFF3DE0C8).withValues(alpha: 0.12);
  static Color get accentBorder => const Color(0xFF3DE0C8).withValues(alpha: 0.35);
  static Color get accentGlow => const Color(0xFF3DE0C8).withValues(alpha: 0.20);

  // 텍스트
  static const textPrimary = Color(0xFFF5F7FA); // 화이트
  static const textSecondary = Color(0xFF8A98B0); // 회청
  static const textFaint = Color(0xFF4A5568); // 희미

  // 구분선: 화이트 8%
  static const divider = Color(0x14FFFFFF);
  static const shadow = Color(0x33000000);

  // 상태
  static const danger = Color(0xFFEF4444);

  // 키패드 splashColor
  static Color get splashLight => const Color(0xFFFFFFFF).withValues(alpha: 0.06);
  static Color get highlightLight => const Color(0xFFFFFFFF).withValues(alpha: 0.03);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.surface,
      primary: AppColors.primary,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: Typography.blackMountainView.apply(
        bodyColor: AppColors.textStrong,
        displayColor: AppColors.textStrong,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textStrong,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: DarkColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: DarkColors.surface,
      primary: DarkColors.accent,
      error: DarkColors.danger,
      onSurface: DarkColors.textPrimary,
      onPrimary: DarkColors.bgDeep,
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
