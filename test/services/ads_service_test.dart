// T-261104-014 B안: 실광고 단위는 앱스토어·플레이 출시판에서만 쓴다.
// 2026-11-04 구글 게시자 계정이 무효 트래픽으로 29일 정지됐다. 디버그·프로필 빌드와
// iOS TestFlight·개발 서명 설치는 구글 공식 시험 배너만 쓰게 고정한다.
import 'package:dutch_pay_calculator/services/ads_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _publisher = 'ca-app-pub-7025432711849670/';
const _googleTest = 'ca-app-pub-3940256099942544/';
const _iosReal = 'ca-app-pub-7025432711849670/6556140410';
const _iosTest = 'ca-app-pub-3940256099942544/2934735716';
const _androidReal = 'ca-app-pub-7025432711849670/5996031899';
const _androidTest = 'ca-app-pub-3940256099942544/6300978111';

void main() {
  group('bannerAdUnitIdFor', () {
    test('디버그·프로필은 모든 플랫폼·설치 출처에서 구글 공식 시험 배너다', () {
      for (final ios in [true, false]) {
        for (final store in [
          'com.apple',
          'com.apple.testflight',
          'com.android.vending',
          null,
        ]) {
          final id = AdsService.bannerAdUnitIdFor(
            releaseMode: false,
            ios: ios,
            installerStore: store,
          );
          expect(id, startsWith(_googleTest), reason: 'ios=$ios $store');
          expect(id, isNot(contains(_publisher)), reason: 'ios=$ios $store');
        }
      }
      expect(
        AdsService.bannerAdUnitIdFor(
          releaseMode: false,
          ios: true,
          installerStore: 'com.apple',
        ),
        _iosTest,
      );
      expect(
        AdsService.bannerAdUnitIdFor(
          releaseMode: false,
          ios: false,
          installerStore: null,
        ),
        _androidTest,
      );
    });

    test('iOS 출시판은 앱스토어 설치(com.apple)만 나눠요 실제 배너다', () {
      expect(
        AdsService.bannerAdUnitIdFor(
          releaseMode: true,
          ios: true,
          installerStore: 'com.apple',
        ),
        _iosReal,
      );
    });

    test('iOS 출시판이라도 TestFlight·개발 서명·시뮬레이터·모름은 시험 배너다', () {
      for (final store in [
        'com.apple.testflight',
        'com.apple.simulator',
        null,
        '',
      ]) {
        expect(
          AdsService.bannerAdUnitIdFor(
            releaseMode: true,
            ios: true,
            installerStore: store,
          ),
          _iosTest,
          reason: '$store',
        );
      }
    });

    test('안드로이드 출시판은 설치 출처와 상관없이 나눠요 실제 배너다', () {
      for (final store in ['com.android.vending', null]) {
        expect(
          AdsService.bannerAdUnitIdFor(
            releaseMode: true,
            ios: false,
            installerStore: store,
          ),
          _androidReal,
          reason: '$store',
        );
      }
    });
  });

  group('AdsService', () {
    setUpAll(() {
      PackageInfo.setMockInitialValues(
        appName: '나눠요',
        packageName: 'com.daejongkang.dutchPayCalculator',
        version: '1.4.0',
        buildNumber: '22',
        buildSignature: '',
        installerStore: 'com.apple.testflight',
      );
    });

    test('설치 출처는 package_info_plus 값을 그대로 읽는다', () async {
      expect(await AdsService.installerStore, 'com.apple.testflight');
    });

    test('시험 실행(디버그 모드)에서 쓰는 배너 ID 는 시험 배너다', () async {
      expect(kReleaseMode, isFalse);
      expect(await AdsService.bannerAdUnitId(), startsWith(_googleTest));
    });
  });
}
