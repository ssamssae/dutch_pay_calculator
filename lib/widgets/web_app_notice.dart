import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_review_service.dart';
import '../theme/app_theme.dart';

/// 웹 버전 전용 안내 띠 — 앱 설치를 권한다. (kIsWeb 일 때만 사용)
class WebAppNotice extends StatelessWidget {
  const WebAppNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DarkColors.surface,
      child: InkWell(
        onTap: () => launchUrl(
          AppReviewService.appStoreUri,
          webOnlyWindowName: '_blank',
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.phone_iphone,
                size: 18,
                color: DarkColors.accent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '웹 버전이에요. 앱으로 받으면 더 편해요.',
                  style: TextStyle(fontSize: 13, color: DarkColors.textPrimary),
                ),
              ),
              Text(
                'App Store',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DarkColors.accent,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: DarkColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
