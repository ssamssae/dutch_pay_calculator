import 'package:dutch_pay_calculator/services/ads_service.dart';
import 'package:dutch_pay_calculator/services/iap_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _iosReal = 'ca-app-pub-7025432711849670/6556140410';
const _androidReal = 'ca-app-pub-7025432711849670/5996031899';
const _adsChannel = MethodChannel('plugins.flutter.io/google_mobile_ads');

void _setPackage({String? installerStore, DateTime? installTime}) {
  PackageInfo.setMockInitialValues(
    appName: '나눠요',
    packageName: 'com.daejongkang.dutchPayCalculator',
    version: '1.4.1',
    buildNumber: '23',
    buildSignature: '',
    installerStore: installerStore,
    installTime: installTime,
  );
  AdsService.debugClearInstallerStoreCache();
}

void main() {
  final first = DateTime.utc(2026, 11, 1);

  setUp(() {
    AdsService.debugReset();
    IapService.adsRemoved.value = false;
    SharedPreferences.setMockInitialValues({});
    _setPackage(installerStore: 'com.apple');
  });

  tearDown(() {
    AdsService.debugReset();
    IapService.adsRemoved.value = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_adsChannel, null);
  });

  group('inInstallGrace', () {
    test('71시간 59분은 유예다', () {
      final now = first.add(const Duration(hours: 71, minutes: 59));
      expect(AdsService.inInstallGrace(now: now, firstSeen: first), isTrue);
    });

    test('72시간 0분은 유예가 아니다', () {
      final now = first.add(const Duration(hours: 72));
      expect(AdsService.inInstallGrace(now: now, firstSeen: first), isFalse);
    });

    test('현재 시각이 처음 본 시각보다 과거면 유예다', () {
      final now = first.subtract(const Duration(minutes: 1));
      expect(AdsService.inInstallGrace(now: now, firstSeen: first), isTrue);
    });
  });

  group('resolveFirstSeen', () {
    test('저장값이 있으면 그 값을 쓰고 덮어쓰지 않는다', () async {
      final stored = DateTime.utc(2024, 5, 6, 7, 8, 9);
      var saves = 0;
      var reads = 0;
      final seen = await AdsService.resolveFirstSeen(
        now: DateTime.utc(2026, 11, 11),
        storedMs: stored.millisecondsSinceEpoch,
        saveMs: (_) async => saves++,
        readInstallTime: () async {
          reads++;
          return DateTime.utc(2020);
        },
      );
      expect(seen.millisecondsSinceEpoch, stored.millisecondsSinceEpoch);
      expect(saves, 0);
      expect(reads, 0);
    });

    test('저장값이 없으면 설치 시각을 골라 저장한다', () async {
      final install = DateTime.utc(2020, 1, 2, 3, 4, 5);
      int? saved;
      final seen = await AdsService.resolveFirstSeen(
        now: DateTime.utc(2026, 11, 11),
        storedMs: null,
        saveMs: (milliseconds) async => saved = milliseconds,
        readInstallTime: () async => install,
      );
      expect(seen.millisecondsSinceEpoch, install.millisecondsSinceEpoch);
      expect(saved, install.millisecondsSinceEpoch);
    });

    test('설치 시각이 없으면 현재 시각을 저장한다', () async {
      final now = DateTime.utc(2026, 11, 11, 1, 2, 3);
      int? saved;
      final seen = await AdsService.resolveFirstSeen(
        now: now,
        storedMs: null,
        saveMs: (milliseconds) async => saved = milliseconds,
        readInstallTime: () async => null,
      );
      expect(seen.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(saved, now.millisecondsSinceEpoch);
    });

    test('설치 시각 읽기에 실패하면 현재 시각을 저장한다', () async {
      final now = DateTime.utc(2026, 11, 11, 4, 5, 6);
      int? saved;
      final seen = await AdsService.resolveFirstSeen(
        now: now,
        storedMs: null,
        saveMs: (milliseconds) async => saved = milliseconds,
        readInstallTime: () async => throw StateError('install time'),
      );
      expect(seen.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(saved, now.millisecondsSinceEpoch);
    });
  });

  group('shouldSuppressRealAdsForInstallGrace', () {
    test('저장값이 있으면 설치 시각이 달라도 저장값을 유지한다', () async {
      final stored = DateTime.utc(2024, 1, 2);
      final now = DateTime.utc(2026, 11, 11);
      SharedPreferences.setMockInitialValues({
        AdsService.firstSeenPrefsKey: stored.millisecondsSinceEpoch,
      });
      _setPackage(
        installerStore: 'com.apple',
        installTime: DateTime.utc(2026, 11, 11),
      );
      AdsService.debugReleaseMode = true;
      AdsService.debugIos = true;
      AdsService.debugNow = () => now;

      expect(await AdsService.shouldSuppressRealAdsForInstallGrace(), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(AdsService.firstSeenPrefsKey),
        stored.millisecondsSinceEpoch,
      );
    });

    test('저장값이 없으면 package_info_plus 설치 시각을 저장한다', () async {
      final install = DateTime.utc(2020, 3, 4);
      final now = DateTime.utc(2026, 11, 11);
      _setPackage(installerStore: 'com.apple', installTime: install);
      AdsService.debugReleaseMode = true;
      AdsService.debugIos = true;
      AdsService.debugNow = () => now;

      expect(await AdsService.shouldSuppressRealAdsForInstallGrace(), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(AdsService.firstSeenPrefsKey),
        install.millisecondsSinceEpoch,
      );

      _setPackage(installerStore: 'com.apple', installTime: now);
      expect(await AdsService.shouldSuppressRealAdsForInstallGrace(), isFalse);
      expect(
        prefs.getInt(AdsService.firstSeenPrefsKey),
        install.millisecondsSinceEpoch,
      );
    });

    test('설치 시각이 없으면 현재 시각을 저장하고 유예다', () async {
      final now = DateTime.utc(2026, 11, 11, 8);
      _setPackage(installerStore: 'com.apple');
      AdsService.debugReleaseMode = true;
      AdsService.debugIos = true;
      AdsService.debugNow = () => now;

      expect(await AdsService.shouldSuppressRealAdsForInstallGrace(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(AdsService.firstSeenPrefsKey),
        now.millisecondsSinceEpoch,
      );
    });

    test('안드로이드 출시판도 설치 후 72시간 안이면 유예다', () async {
      final now = DateTime.utc(2026, 11, 11, 9);
      AdsService.debugReleaseMode = true;
      AdsService.debugIos = false;
      AdsService.debugNow = () => now;
      _setPackage(
        installerStore: 'com.android.vending',
        installTime: now.subtract(const Duration(hours: 71, minutes: 59)),
      );

      expect(await AdsService.shouldSuppressRealAdsForInstallGrace(), isTrue);
    });

    test('디버그·TestFlight 는 유예를 보지 않고 처음 본 시각도 쓰지 않는다', () async {
      final now = DateTime.utc(2026, 11, 11);
      AdsService.debugNow = () => now;

      AdsService.debugReleaseMode = false;
      AdsService.debugIos = true;
      _setPackage(installerStore: 'com.apple', installTime: now);
      expect(await AdsService.shouldSuppressRealAdsForInstallGrace(), isFalse);

      AdsService.debugReleaseMode = true;
      _setPackage(installerStore: 'com.apple.testflight', installTime: now);
      expect(await AdsService.shouldSuppressRealAdsForInstallGrace(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AdsService.firstSeenPrefsKey), isNull);
    });

    test('72시간이 지나면 유예가 아니고 광고 단위 ID 는 그대로다', () async {
      final now = first.add(const Duration(hours: 72));
      SharedPreferences.setMockInitialValues({
        AdsService.firstSeenPrefsKey: first.millisecondsSinceEpoch,
      });
      AdsService.debugReleaseMode = true;
      AdsService.debugIos = true;
      AdsService.debugNow = () => now;
      _setPackage(installerStore: 'com.apple', installTime: DateTime.utc(2020));

      expect(await AdsService.shouldSuppressRealAdsForInstallGrace(), isFalse);
      expect(
        await AdsService.bannerAdUnitId(),
        AdsService.bannerAdUnitIdFor(
          releaseMode: true,
          ios: true,
          installerStore: 'com.apple',
        ),
      );
      expect(await AdsService.bannerAdUnitId(), _iosReal);

      AdsService.debugIos = false;
      AdsService.debugClearInstallerStoreCache();
      expect(await AdsService.bannerAdUnitId(), _androidReal);
    });
  });

  group('AdaptiveBanner 유예', () {
    final calls = <String>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_adsChannel, (call) async {
            calls.add(call.method);
            if (call.method == 'AdSize#getLargeAnchoredAdaptiveBannerAdSize') {
              return 50;
            }
            return null;
          });
    });

    Future<void> pumpBanner(WidgetTester tester) {
      return tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AdaptiveBanner(contentGap: 8, reserveSpace: true),
                Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('유예 중에는 광고 객체를 만들지 않고 자리도 차지하지 않는다', (tester) async {
      final now = DateTime.utc(2026, 11, 11, 12);
      SharedPreferences.setMockInitialValues({
        AdsService.firstSeenPrefsKey: now
            .subtract(const Duration(hours: 71, minutes: 59))
            .millisecondsSinceEpoch,
      });
      AdsService.debugNow = () => now;
      AdsService.debugReleaseMode = true;
      AdsService.debugIos = true;
      _setPackage(installerStore: 'com.apple');
      var loadCalled = false;
      AdsService.debugLoadBanner = (_) async => loadCalled = true;

      await pumpBanner(tester);
      await tester.pump();

      expect(AdsService.bannerAdsCreatedForTest, 0);
      expect(AdsService.lastRequestedBannerAdUnitId, isNull);
      expect(loadCalled, isFalse);
      expect(calls, isEmpty);
      expect(find.byKey(const ValueKey('adaptive-banner-slot')), findsNothing);
      expect(tester.getSize(find.byType(AdaptiveBanner)).height, 0);
    });

    testWidgets('유예가 끝나면 광고 단위 ID 가 지금과 같다', (tester) async {
      final now = first.add(const Duration(hours: 72));
      SharedPreferences.setMockInitialValues({
        AdsService.firstSeenPrefsKey: first.millisecondsSinceEpoch,
      });
      AdsService.debugNow = () => now;
      AdsService.debugReleaseMode = true;
      AdsService.debugIos = true;
      _setPackage(installerStore: 'com.apple', installTime: DateTime.utc(2020));
      String? requested;
      AdsService.debugLoadBanner = (ad) async => requested = ad.adUnitId;

      await pumpBanner(tester);
      await tester.pump();

      expect(requested, _iosReal);
      expect(AdsService.lastRequestedBannerAdUnitId, _iosReal);
      expect(
        requested,
        AdsService.bannerAdUnitIdFor(
          releaseMode: true,
          ios: true,
          installerStore: 'com.apple',
        ),
      );
      expect(calls, isNot(contains('loadBannerAd')));
    });

    testWidgets('불러오기에 실패하면 자리를 비운다', (tester) async {
      final now = first.add(const Duration(hours: 72));
      SharedPreferences.setMockInitialValues({
        AdsService.firstSeenPrefsKey: first.millisecondsSinceEpoch,
      });
      AdsService.debugNow = () => now;
      AdsService.debugReleaseMode = true;
      AdsService.debugIos = true;
      _setPackage(installerStore: 'com.apple');
      AdsService.debugLoadBanner = (_) async => throw StateError('load failed');

      await pumpBanner(tester);
      await tester.pump();

      expect(find.byKey(const ValueKey('adaptive-banner-slot')), findsNothing);
      expect(tester.getSize(find.byType(AdaptiveBanner)).height, 0);
    });

    testWidgets('광고 제거 구매가 먼저다', (tester) async {
      final now = first.add(const Duration(hours: 72));
      IapService.adsRemoved.value = true;
      AdsService.debugNow = () => now;
      AdsService.debugReleaseMode = true;
      AdsService.debugIos = true;
      _setPackage(installerStore: 'com.apple');

      await pumpBanner(tester);
      await tester.pump();

      expect(AdsService.bannerAdsCreatedForTest, 0);
      expect(tester.getSize(find.byType(AdaptiveBanner)).height, 0);
      expect(calls, isEmpty);
    });
  });
}
