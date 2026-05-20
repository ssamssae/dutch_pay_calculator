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
}
