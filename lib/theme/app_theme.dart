import 'package:flutter/material.dart';

/// 더치페이 디자인 시스템 (다크 고정 — 폰 테마와 무관하게 항상 다크).
/// 약먹자와 같은 구조, 포인트 컬러만 다름(인디고).
class AppColors {
  AppColors._();

  // 베이스 (다크)
  static const bg = Color(0xFF0F1115); // scaffold 딥 다크
  static const surface = Color(0xFF1A1D24); // 카드
  static const shadow = Color(0x40000000); // black 25% — 다크 위 그림자
  static const divider = Color(0x1FFFFFFF); // white 12% 구분선/보더
  static const fill = Color(0xFF252A33); // 옅은 다크 채움

  // 포인트 (더치페이 = 인디고, 다크 위 대비 위해 밝게)
  static const primary = Color(0xFF5C7CFA);
  static const primaryDark = Color(0xFF7B93FF); // 라벨/공유버튼용 (밝은 인디고)
  static Color get primarySoft => primary.withValues(alpha: 0.16);

  // 텍스트
  static const textStrong = Color(0xFFF1F3F8);
  static const textBody = Color(0xFFC2C8D2);
  static const textFaint = Color(0xFF858C99);

  // 상태
  static const danger = Color(0xFFFF6B6B);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.surface,
      primary: AppColors.primary,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: Typography.whiteMountainView.apply(
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
}
