# Janitor Log — dutch_pay_calculator

`night-runner` / repo-janitor 세션의 작업 기록.

---
## 2026-04-19 (janitor/2026-04-19)
- 처리한 작업 2개
  1. **실패하던 widget smoke test 수정** + 더치페이 핵심 동작 widget test 7개 추가 (총 8/8 pass)
     - 기존 smoke test 가 `SplashScreen` 의 `Future.delayed(1500ms)` 미해소로 'A Timer is still pending' 에러
     - `pumpAndSettle` 로 splash → main 전환을 끝까지 소진하도록 수정
     - 추가 커버리지: 키패드 입력 + 콤마 포맷, ⌫/C 버튼, +/- 인원수 (1~100 경계), 10,000/3 = 3,333+1원 잔여 메시지, 나머지 0 케이스, 금액 0 일 때 계산하기 비활성
     - 커밋: `6b18ec0`
  2. **transitive dep 패치 업그레이드**: `vm_service` 15.0.2 → 15.1.0 (lockfile only, direct deps 변동 없음)
     - 커밋: `29be982`
- 변경 파일
  - `test/widget_test.dart` (10 → 148 lines)
  - `pubspec.lock` (vm_service sha + version)
- 베이스라인 검증
  - `flutter analyze` — No issues found
  - `flutter test` — 8/8 passed
- 다음 권장 작업
  - 상위 transitive (meta 1.18.2, vector_math 2.3.0, test_api 0.7.11) 는 Flutter SDK 제약으로 막힘. SDK 자체 업데이트 시점에 같이 풀린다.
  - `lib/main.dart` 가 521 줄 단일 파일. 추후 `MainScreen`/`SplashScreen`/`_buildKeyButton` 등을 `lib/screens/`, `lib/widgets/` 로 분리하면 위젯별 단위 테스트가 더 쉬워진다 (이번 라운드는 스코프 외).
  - 계산 로직(`_calculate`, `_formatNumber`)을 별도 pure-Dart helper 로 추출하면 widget test 없이도 빠른 unit test 가 가능 (소형 리팩토링 후보).
