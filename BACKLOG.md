# BACKLOG (더치페이)

향후 개선 후보. 우선순위 P0 (긴급) → P2 (언젠가).

작성: 2026-05-14 (WSL parkinglot dynamic loop, wsl/parkinglot-loop-2026-05-14)

## P0

- ~~**`GADApplicationIdentifier`** Info.plist 추가~~ — 2026-05-12 이슈 (issues/`2026-05-12-dutchpay-gad-application-identifier-missing.md`). 광고 SDK 식별자 누락으로 런타임 경고/오작동 가능. `ios/Runner/Info.plist` 에 `<key>GADApplicationIdentifier</key><string>ca-app-pub-XXX~YYY</string>` 박기. **(close 2026-05-15: 이미 commit `3c5daa7` 에 적용됨 — `ca-app-pub-7025432711849670~7679626181`. BACKLOG 만 stale 했음.)**
- 광고 통합 검증 hook — Info.plist 의 GADApplicationIdentifier 부재 시 빌드 차단 또는 lint 경고.

## P1

- ~~iOS-only 운영 정책 명시 (README 상단)~~ — `feedback_app_release_strategy.md`. 약먹자와 동일 정책. **(close 2026-05-15: README 배포 정책 섹션 추가, 본 PR 에서 동봉.)**
- privacy-dutchpay.html (`~/daejong-page/privacy-dutchpay.html`) 정기 갱신 패턴 (분기 1회 점검).

## P2

- 1.0.x → 1.1 기능 추가 — 강대종 사용 피드백 채집 후 결정.
- 더치페이 사용 통계 채집 — 1주일치 본인 사용 패턴 추출 후 UX 다듬기.

## 출처

- 메모리: `project_yakmukja_dutchpay_ios_review_submitted.md`, `feedback_app_release_strategy.md`
- 이슈: `2026-05-12-dutchpay-gad-application-identifier-missing.md`
