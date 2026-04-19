# 더치페이 계산기

금액과 인원수만 입력하면 1인당 나눠낼 금액과 남는 돈을 바로 알려주는 Flutter 기반 모바일 앱.

## 주요 기능

- **금액 입력**: 커스텀 숫자 키패드 (최대 10자리)로 빠른 입력
- **인원수 조정**: +/- 버튼으로 1~100명 범위 선택
- **계산 결과**: 1인당 금액 + 나머지 금액 (몇 원 누가 낼래?) 표시
- **다크 테마** 고정, Safe Area 반응형 UI (작은 폰부터 큰 폰까지 자동 스케일)

## 개발

```sh
flutter pub get
flutter run
```

### WSL (Windows) 에서 빌드

WSL bash 에서 `flutter` 를 직접 호출하면 CRLF/경로 문제가 생기므로 PowerShell 로 래핑해서 실행한다.

```sh
powershell.exe -NoProfile -Command "cd C:\dev\dutch_pay_calculator; flutter pub get"
powershell.exe -NoProfile -Command "cd C:\dev\dutch_pay_calculator; flutter run"
```

### 테스트

```sh
flutter test
```

## 버전

현재 버전은 `pubspec.yaml` 의 `version:` 필드를 참고 (iOS 는 `CFBundleShortVersionString`, Android 는 `versionName`).

## 라이선스

Private project. `publish_to: 'none'` 로 pub.dev 업로드 차단되어 있음.
