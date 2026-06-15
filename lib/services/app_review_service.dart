import 'package:in_app_review/in_app_review.dart';

/// 앱 평가 — App Store / Play Store 리뷰 페이지를 연다.
///
/// 수동 '앱 평가하기' 버튼은 자동 프롬프트(requestReview)가 아니라 스토어
/// 리뷰 페이지로 직접 보낸다(약먹자와 동일 정책).
class AppReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// iOS App Store 숫자 id (더치페이 계산기). Android 는 패키지로 자동.
  static const String _appStoreId = '6762072499';

  /// 스토어 리뷰 페이지 열기. 실패 시 false.
  static Future<bool> openReview() async {
    try {
      await _inAppReview.openStoreListing(appStoreId: _appStoreId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
