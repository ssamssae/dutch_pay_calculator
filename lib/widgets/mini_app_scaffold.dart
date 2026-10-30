import 'package:flutter/material.dart';

import '../services/ads_service.dart';
import '../theme/app_theme.dart';

/// 미니앱 화면 왼쪽 위 「뒤로」 버튼.
class MiniAppBackButton extends StatelessWidget {
  const MiniAppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('miniapp-back'),
      tooltip: '뒤로',
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => Navigator.maybePop(context),
    );
  }
}

/// 미니앱 화면 틀: 제목 · 설명 AppBar, 본문, 광고 배너, 맨 아래 버튼.
class MiniAppScaffold extends StatelessWidget {
  const MiniAppScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final Widget body;

  /// 배너 아래 맨 아래 띠(보통 `TossBottomButton`).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TossColors.bgDeep,
      appBar: AppBar(
        leading: const MiniAppBackButton(),
        centerTitle: false,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.4,
                color: TossColors.textPrimary,
                height: 1.05,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: TossColors.textFaint,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            const AdaptiveBanner(),
            ?bottom,
          ],
        ),
      ),
    );
  }
}
