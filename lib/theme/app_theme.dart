import 'package:flutter/material.dart';

/// 더치페이 디자인 시스템 (다크 프리미엄 — 폰 테마와 무관하게 항상 다크).
/// 포인트 = 청록 네온(#3DE0C8), 베이스 = 딥네이비 (Revolut 결).
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

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.surface,
      primary: AppColors.primary,
      onPrimary: AppColors.bg, // 청록 네온 위 텍스트/아이콘은 딥네이비 (대비)
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
