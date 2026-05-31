# 더치페이 Android 출시 정책 확정 (audit D5)

- **Task**: T-260515-12 (audit-2026-05-15 D5)
- **결정일**: 2026-05-31
- **결정**: **iOS-only 유지. Android 출시 보류(deferred) — 영구 미배포 아님.**
- **노드**: 🖥 데스크탑 (desktop3060ti)

---

## 결론 (TL;DR)

더치페이는 **iOS 단독 출시**를 유지한다. Android Play Console 등록은 계속 **보류**한다.
이는 신규 결정이 아니라 **기존 정책의 재확인**이다 (강대종 2026-05-02 결정).

멀티 OS 코드(`android/` 트리 + `Platform.isAndroid` 분기)는 **현행 유지(삭제 X)** 한다.
"영구 미배포면 Android 트리 정리" 분기는 발동하지 않는다 — 본 건은 *영구 미배포*가 아니라 *비용 기반 보류*이기 때문.

---

## 근거

### 1. 정책은 이미 확정돼 있음 (재확인일 뿐)
- 강대종 2026-05-02 14:11~12 KST 발화 (msg 10971+10972): "약먹자는 안드로이드 출시 안할거야" + "토큰 2만원이라 핵심 앱만 출시 예정".
- 메모리 `feedback_app_release_strategy.md`: 비핵심 앱은 Android skip. **더치페이는 비핵심(Android skip 권장) 풀에 명시적으로 등재.**
- 비용 구조: Apple Developer Program $99/년 이미 결제 → iOS marginal 비용 0. Google Play Console 일회성 $25(₩30K) → 비핵심 앱 ROI 0.
- `README.md` 배포 정책 섹션이 이미 iOS-only 명시 (PR #7, 2026-05-15).

### 2. 코드 상태가 "Android = 프로덕션 미대상"을 뒷받침
- **릴리스 매니페스트에 INTERNET 권한 부재**: `android/app/src/main/AndroidManifest.xml` 에 `INTERNET` 없음 (debug/profile 매니페스트에만 있음). AdMob(`google_mobile_ads`) 사용 앱인데 릴리스 빌드는 광고 로드 불가 → 애초에 Play 출시 준비 안 됨.
- **Android 광고 유닛 = Google 테스트 ID**: `lib/services/ads_service.dart` 의 Android 분기는 `ca-app-pub-3940256099942544/6300978111` (구글 공식 테스트 배너) 반환. 실 수익 유닛 없음. iOS 분기만 운영 ID(`...7025432711849670`) 보유.
- 결론: Android 코드는 **개발/테스트용 스캐폴드**일 뿐, 수익·배포 경로가 구성된 적 없음.

### 3. "보류" vs "영구 미배포" 판정
- 강대종 표현은 "보류" + "핵심 앱만 출시 *예정*" — 비용·우선순위 기반 deferral 이지, 아키텍처상 영구 배제 아님.
- Play 등록비는 일회성 $25이고, 앱은 Android 에서 정상 동작. 더치페이가 향후 핵심 앱 풀로 승격되면 재개 가능.
- 따라서 **영구 미배포 아님 → Android 트리 삭제 트리거 미발동.**

---

## 멀티 OS 코드 처분 (cleanup 판정)

**현행 유지 (삭제·정리 작업 없음).** audit D5 의 "별 cleanup 사이클"은 사실상 no-op.

`android/` 트리를 **삭제하지 않는** 이유:
1. **재개 가능한 보류** — 영구 결정이 아니므로 삭제는 과한 비가역 조치.
2. **크로스플랫폼 개발 동선** — 데스크탑/WSL 등 비-Mac 노드에서 `flutter run`(Android 에뮬레이터)으로 빠른 dev 이터레이션 가능. 트리 삭제 시 이 동선 상실.
3. **유지비 거의 0** — 기본 Flutter 스캐폴드라 관리 부담 없음.
4. 글로벌 룰 "정리는 삭제 아닌 보관 이동(가역)" 정신과 일치.

`Platform.isAndroid` 분기도 유지 — 크로스플랫폼 dev 빌드 시 크래시 방지용 가드 역할.

---

## 재개 시 체크리스트 (정책이 Android 출시로 뒤집힐 경우)

더치페이가 핵심 앱 풀로 승격되면 다음을 수행:
1. `android/app/src/main/AndroidManifest.xml` 에 `<uses-permission android:name="android.permission.INTERNET"/>` 추가.
2. 실 AdMob Android 앱 + 배너 유닛 발급 → `ads_service.dart` Android 분기를 운영 ID 로 교체.
3. Google Play Console 등록(₩30K) + 앱 서명 키 구성.
4. 개인정보처리방침 URL (`~/daejong-page/privacy-dutchpay.html` 재사용 가능) Play 리스팅 연결.
5. AAB 빌드 → 내부 테스트 → 프로덕션 심사 제출.

---

## audit D5 종결

- D5 = **iOS-only 정책 재확인 + 멀티 OS 코드 현행 유지** 로 종결.
- 후속 cleanup 사이클 **불필요** (트리 삭제·분기 정리 미발동).
- 본 결정으로 T-260515-12 close.
