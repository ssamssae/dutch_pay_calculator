import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob 초기화 + 광고 단위 ID 관리.
///
/// 출시 전 AdMob 콘솔에서 더치페이 앱 등록 + 배너 광고단위 생성 후,
/// 아래 _realIosBannerUnitId 만 교체하면 됨.
/// AppId 도 Info.plist 의 GADApplicationIdentifier 교체 필요.
class AdsService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('[AdsService] init failed: $e');
    }
  }

  static String get bannerAdUnitId {
    if (kDebugMode) return _testBannerUnitId;
    if (Platform.isIOS) return _realIosBannerUnitId;
    return _testBannerUnitId;
  }

  static String get _testBannerUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    return 'ca-app-pub-3940256099942544/2934735716';
  }

  static const _realIosBannerUnitId = 'ca-app-pub-7025432711849670/6556140410';
}

class AdaptiveBanner extends StatefulWidget {
  const AdaptiveBanner({super.key});

  @override
  State<AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<AdaptiveBanner> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  AdSize? _size;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) _loadAd();
  }

  Future<void> _loadAd() async {
    final mq = MediaQuery.of(context);
    final width = mq.size.width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: AdsService.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdaptiveBanner] failed: ${error.message}');
          ad.dispose();
        },
      ),
    );

    setState(() => _size = size);
    await ad.load();
    if (!mounted) {
      ad.dispose();
      return;
    }
    _bannerAd = ad;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    if (!_loaded || _bannerAd == null || size == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: SizedBox(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
