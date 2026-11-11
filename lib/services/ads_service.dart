import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'iap_service.dart';

/// AdMob 초기화 + 광고 단위 ID 관리.
///
/// 출시 전 AdMob 콘솔에서 더치페이 앱 등록 + 배너 광고단위 생성 후,
/// 아래 _realIosBannerUnitId 만 교체하면 됨.
/// AppId 도 Info.plist 의 GADApplicationIdentifier 교체 필요.
class AdsService {
  static bool _initialized = false;

  /// 처음 본 시각. epoch 밀리초. 한 번 저장하면 덮어쓰지 않는다.
  static const firstSeenPrefsKey = 'ads_first_seen_ms';

  /// 설치 후 이 시간보다 짧으면 실제 광고를 요청하지 않는다.
  static const installGrace = Duration(hours: 72);

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('[AdsService] init failed: $e');
    }
  }

  /// 배너 광고 단위 ID. 출시판만 실제 ID 이고, 디버그·프로필 빌드는 구글 공식 시험 ID 다.
  /// iOS 는 출시판이라도 앱스토어에서 받은 설치만 실제 ID 다. TestFlight·개발 서명 설치는 시험 ID 다.
  /// 개발·실기기 시험이나 TestFlight 에서 실광고가 노출·클릭되면 무효 트래픽으로 게시자 계정이
  /// 정지된다(2026-11-04 29일 정지, T-261104-014 B안).
  static Future<String> bannerAdUnitId() async => bannerAdUnitIdFor(
    releaseMode: debugReleaseMode ?? kReleaseMode,
    ios: debugIos ?? Platform.isIOS,
    installerStore: await installerStore,
  );

  static Future<String?>? _installerStore;

  /// 설치 출처. iOS 는 앱스토어 설치면 `com.apple`, TestFlight·개발 서명 설치면 `com.apple.testflight` 다
  /// (package_info_plus 가 영수증 경로 `sandboxReceipt` 로 가른다). 읽지 못하면 null 이다.
  @visibleForTesting
  static Future<String?> get installerStore =>
      _installerStore ??= _readInstallerStore();

  static Future<String?> _readInstallerStore() async {
    try {
      return (await PackageInfo.fromPlatform()).installerStore;
    } catch (_) {
      return null;
    }
  }

  /// [bannerAdUnitId] 의 순수 함수판 — 빌드 모드·플랫폼·설치 출처 분기를 단위 시험으로 고정한다.
  ///
  /// iOS 는 [installerStore] 가 정확히 `com.apple`(앱스토어 설치)일 때만 실제 배너다.
  /// TestFlight·개발 서명·시뮬레이터·모름(null)은 시험 배너다. 안드로이드는 내부 테스트와
  /// 정식 출시가 같은 앱 묶음이라 설치 출처로 가를 수 없어 출시판이면 실제 배너다.
  @visibleForTesting
  static String bannerAdUnitIdFor({
    required bool releaseMode,
    required bool ios,
    required String? installerStore,
  }) {
    if (!usesRealBannerAdUnit(
      releaseMode: releaseMode,
      ios: ios,
      installerStore: installerStore,
    )) {
      return ios
          ? 'ca-app-pub-3940256099942544/2934735716' // 구글 공식 시험 배너 (iOS)
          : 'ca-app-pub-3940256099942544/6300978111'; // 구글 공식 시험 배너 (Android)
    }
    return ios ? _realIosBannerUnitId : _realAndroidBannerUnitId;
  }

  /// 실제 광고 단위를 쓰는 조건. 출시 빌드이고, iOS 는 설치 출처가 `com.apple` 일 때다.
  @visibleForTesting
  static bool usesRealBannerAdUnit({
    required bool releaseMode,
    required bool ios,
    required String? installerStore,
  }) {
    final appStoreInstall = !ios || installerStore == 'com.apple';
    return releaseMode && appStoreInstall;
  }

  /// `now` 가 `firstSeen` 보다 과거이거나, 둘의 차이가 [installGrace] 보다 짧으면 참이다.
  /// 72시간 0분은 유예가 아니다.
  @visibleForTesting
  static bool inInstallGrace({
    required DateTime now,
    required DateTime firstSeen,
  }) {
    final elapsed = now.difference(firstSeen);
    if (elapsed.isNegative) return true;
    return elapsed < installGrace;
  }

  /// 저장값이 있으면 그 시각이다. 없으면 설치 시각, 설치 시각도 없거나 읽기에 실패하면 [now] 다.
  /// 저장은 값이 없을 때만 한다.
  @visibleForTesting
  static Future<DateTime> resolveFirstSeen({
    required DateTime now,
    required int? storedMs,
    required Future<void> Function(int milliseconds) saveMs,
    required Future<DateTime?> Function() readInstallTime,
  }) async {
    if (storedMs != null) {
      return DateTime.fromMillisecondsSinceEpoch(storedMs);
    }
    DateTime chosen;
    try {
      chosen = await readInstallTime() ?? now;
    } catch (_) {
      chosen = now;
    }
    await saveMs(chosen.millisecondsSinceEpoch);
    return chosen;
  }

  /// 실제 광고를 내는 조건일 때만 설치 유예를 본다. 시험 광고 조건은 항상 거짓이다.
  static Future<bool> shouldSuppressRealAdsForInstallGrace() async {
    final releaseMode = debugReleaseMode ?? kReleaseMode;
    // 시험 광고 조건은 설치 시각을 읽지도, 저장하지도 않는다.
    if (!releaseMode) return false;
    final ios = debugIos ?? Platform.isIOS;
    final store = await installerStore;
    if (!usesRealBannerAdUnit(
      releaseMode: releaseMode,
      ios: ios,
      installerStore: store,
    )) {
      return false;
    }
    final now = currentTime;
    final firstSeen = await _readStoredFirstSeen(now);
    return inInstallGrace(now: now, firstSeen: firstSeen);
  }

  static Future<DateTime> _readStoredFirstSeen(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    return resolveFirstSeen(
      now: now,
      storedMs: prefs.getInt(firstSeenPrefsKey),
      saveMs: (milliseconds) => prefs.setInt(firstSeenPrefsKey, milliseconds),
      readInstallTime: debugReadInstallTime ?? _readInstallTime,
    );
  }

  static Future<DateTime?> _readInstallTime() async {
    final info = await PackageInfo.fromPlatform();
    return info.installTime;
  }

  @visibleForTesting
  static DateTime Function()? debugNow;

  @visibleForTesting
  static bool? debugReleaseMode;

  @visibleForTesting
  static bool? debugIos;

  /// null 이면 [PackageInfo.installTime] 을 읽는다. 예외를 던지면 현재 시각을 쓴다.
  @visibleForTesting
  static Future<DateTime?> Function()? debugReadInstallTime;

  /// null 이면 [BannerAd.load] 를 부른다. 시험은 여기서 로드를 대신한다.
  @visibleForTesting
  static Future<void> Function(BannerAd ad)? debugLoadBanner;

  @visibleForTesting
  static int bannerAdsCreatedForTest = 0;

  @visibleForTesting
  static String? lastRequestedBannerAdUnitId;

  static DateTime get currentTime => debugNow?.call() ?? DateTime.now();

  @visibleForTesting
  static void debugClearInstallerStoreCache() {
    _installerStore = null;
  }

  @visibleForTesting
  static void debugReset() {
    debugNow = null;
    debugReleaseMode = null;
    debugIos = null;
    debugReadInstallTime = null;
    debugLoadBanner = null;
    bannerAdsCreatedForTest = 0;
    lastRequestedBannerAdUnitId = null;
    _installerStore = null;
  }

  // iOS 운영 ID — 2026-05-12 AdMob 콘솔 발급 (dutch_banner_ios).
  static const _realIosBannerUnitId = 'ca-app-pub-7025432711849670/6556140410';

  // Android 운영 ID — 2026-06-16 AdMob 콘솔 발급 (dutch_banner_android).
  static const _realAndroidBannerUnitId =
      'ca-app-pub-7025432711849670/5996031899';
}

class AdaptiveBanner extends StatefulWidget {
  const AdaptiveBanner({
    super.key,
    this.contentGap = 0,
    this.reserveSpace = false,
  });

  /// 배너 칸이 보일 때 아래에 두는 세로 여백. 0 이면 자리를 더하지 않는다.
  final double contentGap;

  /// 참이면 광고 크기를 구한 뒤 로드가 끝나기 전에 그 높이의 빈 칸을 그린다.
  final bool reserveSpace;

  @override
  State<AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<AdaptiveBanner> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  AdSize? _reservedSize;
  bool _loadStarted = false;
  bool _releasedAd = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    if (IapService.adsRemoved.value) return;
    _loadStarted = true;
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!mounted || IapService.adsRemoved.value) return;
    final width = MediaQuery.of(context).size.width.truncate();
    final suppress = await AdsService.shouldSuppressRealAdsForInstallGrace();
    if (!mounted || IapService.adsRemoved.value || suppress) return;

    final AdSize? size;
    try {
      size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    } catch (e) {
      debugPrint('[AdaptiveBanner] size failed: $e');
      return;
    }
    if (size == null || !mounted || IapService.adsRemoved.value) return;

    if (widget.reserveSpace) {
      setState(() => _reservedSize = size);
    }

    final adUnitId = await AdsService.bannerAdUnitId();
    if (!mounted || IapService.adsRemoved.value) {
      _clearReservedSpace();
      return;
    }

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted || _releasedAd) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (failedAd, error) {
          debugPrint('[AdaptiveBanner] failed: ${error.message}');
          _dropAd(failedAd);
        },
      ),
    );
    AdsService.bannerAdsCreatedForTest++;
    AdsService.lastRequestedBannerAdUnitId = adUnitId;
    _bannerAd = ad;

    try {
      final customLoad = AdsService.debugLoadBanner;
      if (customLoad != null) {
        await customLoad(ad);
      } else {
        await ad.load();
      }
    } catch (e) {
      debugPrint('[AdaptiveBanner] load failed: $e');
      _dropAd(ad);
    }
  }

  void _clearReservedSpace() {
    if (!mounted || _reservedSize == null) return;
    setState(() => _reservedSize = null);
  }

  void _dropAd(Ad ad) {
    if (_releasedAd) return;
    _releasedAd = true;
    if (identical(_bannerAd, ad)) _bannerAd = null;
    ad.dispose();
    if (!mounted) return;
    setState(() {
      _loaded = false;
      _reservedSize = null;
    });
  }

  @override
  void dispose() {
    final ad = _bannerAd;
    _bannerAd = null;
    if (ad != null && !_releasedAd) {
      _releasedAd = true;
      ad.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: IapService.adsRemoved,
      builder: (context, removed, _) {
        if (removed) return const SizedBox.shrink();
        final ad = _bannerAd;
        if (widget.reserveSpace) {
          final size = _reservedSize;
          if (size == null) return const SizedBox.shrink();
          return _slot(
            size,
            showAd: _loaded && ad != null && !_releasedAd,
            ad: ad,
          );
        }
        if (!_loaded || ad == null) return const SizedBox.shrink();
        return _slot(ad.size, showAd: true, ad: ad);
      },
    );
  }

  Widget _slot(AdSize size, {required bool showAd, required BannerAd? ad}) {
    final box = SafeArea(
      top: false,
      child: SizedBox(
        key: const ValueKey('adaptive-banner-slot'),
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        child: showAd && ad != null
            ? AdWidget(ad: ad)
            : const SizedBox.shrink(),
      ),
    );
    if (widget.contentGap <= 0) return box;
    return Padding(
      padding: EdgeInsets.only(bottom: widget.contentGap),
      child: box,
    );
  }
}
