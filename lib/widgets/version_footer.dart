import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/app_theme.dart';

/// 버전 푸터. 버전은 package_info_plus 로 런타임에 pubspec 버전을 조회한다
/// (dart-define APP_VERSION 의존 제거 → 'vdev' footgun 방지).
class VersionFooter extends StatelessWidget {
  const VersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '';
        final label = version.isEmpty ? '마이너스베타스튜디오' : 'v$version · 마이너스베타스튜디오';
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: DarkColors.textFaint,
                letterSpacing: -0.1,
              ),
            ),
          ),
        );
      },
    );
  }
}
