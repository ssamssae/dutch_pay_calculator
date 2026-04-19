# dutch_pay_calculator — Build & Run notes

A Flutter app. Repo lives in two places:
- Mac (primary dev): `~/dutch_pay_calculator` (Flutter SDK is WSL-friendly there)
- Windows desktop / WSL Ubuntu (worker): `/mnt/c/dev/dutch_pay_calculator` (this clone)

## WSL-side build commands

The Flutter SDK on this Windows host is at `C:\src\flutter` and was installed via the official
Windows installer — its shell scripts have CRLF line endings. **Calling `flutter` directly from
WSL bash fails** with `shared.sh: line 5: $'\r': command not found`.

Always invoke flutter through PowerShell with `cd` to a Windows-native path:

```bash
# Flutter analyze
powershell.exe -NoProfile -Command "cd C:\dev\dutch_pay_calculator; flutter analyze"

# Flutter test
powershell.exe -NoProfile -Command "cd C:\dev\dutch_pay_calculator; flutter test"

# Flutter pub get
powershell.exe -NoProfile -Command "cd C:\dev\dutch_pay_calculator; flutter pub get"

# Build APK (release) for Galaxy S24
powershell.exe -NoProfile -Command "cd C:\dev\dutch_pay_calculator; flutter build apk --release"

# Run on connected Galaxy S24 (use /arun skill)
/arun /mnt/c/dev/dutch_pay_calculator
```

Pure-Dart ops (formatting, analysis on individual files) can use `dart` similarly via the
PowerShell wrapper.

## Mac-side build commands

Standard Flutter — no wrapper needed:

```bash
flutter analyze
flutter test
flutter run
```

## Repo conventions

- Branch policy: feature branches → PR → squash merge to `main`.
- Janitor-style automated commits land on `janitor/YYYY-MM-DD` branches; never push directly to `main`.
- Versioning: `pubspec.yaml`'s `version:` is the source of truth (currently `1.0.0+2`). Bump with each release.

## Tests

- Unit/widget tests live in `test/`. Run with `flutter test` (via PowerShell on WSL, see above).
- No integration tests yet.
