import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

/// 앱 평가 — App Store / Play Store 리뷰 페이지를 연다.
///
/// 수동 '앱 평가하기' 버튼은 자동 프롬프트(requestReview)가 아니라 스토어
/// 리뷰 페이지로 직접 보낸다(약먹자와 동일 정책).
class AppReviewService {
  /// iOS App Store 숫자 id (더치페이 계산기). Android 는 패키지로 자동.
  static const String appStoreId = '6762072499';

  /// 웹 버전에서 쓰는 App Store 링크.
  static final Uri appStoreUri = Uri.parse(
    'https://apps.apple.com/app/id$appStoreId',
  );

  /// 스토어 리뷰 페이지 열기. 실패 시 false.
  static Future<bool> openReview() async {
    try {
      // 웹은 in_app_review 를 쓰지 않고 App Store 페이지를 새 탭으로 연다.
      if (kIsWeb) {
        return await launchUrl(appStoreUri, webOnlyWindowName: '_blank');
      }
      await InAppReview.instance.openStoreListing(appStoreId: appStoreId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
