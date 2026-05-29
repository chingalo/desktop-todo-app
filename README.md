# ProgramPilot (`dhis_todo`)

Flutter **desktop** app (macOS and Windows): Material 3 UI, offline todos, sign up / sign in, and optional DHIS2 program import with HTTP Basic authentication.

## Quick start

```bash
flutter pub get
dart run build_runner build   # after editing lib/data/database.dart tables
flutter analyze
flutter test
flutter test integration_test/   # desktop harness (builds macOS/Windows target)
flutter run -d macos             # or -d windows
```

## Package vs product name

- **Dart package:** `dhis_todo` (folder and `pubspec.yaml` name).
- **Product / UI name:** ProgramPilot.

## Data storage

SQLite via **Drift** (`lib/data/database.dart`). Database file: `program_pilot.sqlite` under application support. Unit tests use `AppDatabase(NativeDatabase.memory())`.

## Session storage

`lib/state/session_store.dart` defines `SessionStore`; production uses `SecureSessionStore` (Keychain / platform secure storage). Tests and integration tests use `InMemorySessionStore` in `lib/state/in_memory_session_store.dart` so CI and local harness runs do not require Keychain entitlements for sign-in flows.

## Integration tests

- Package: `integration_test` (see `pubspec.yaml` dev_dependencies).
- Entry: [`integration_test/app_test.dart`](integration_test/app_test.dart) — runs against the **real desktop harness** (macOS or Windows binary, not `flutter_tester`).
- Uses `assembleProgramPilotHarness(sessionStore: InMemorySessionStore())` so sign-in flows do not touch the Keychain (avoids entitlement `-34018` in the test binary).
- One test checks the signed-out auth shell; the other calls `AuthController.signUp` then asserts **Todos** + `NavigationRail` (full TabBarView taps are still unreliable in this harness, so the auth step uses the controller while the rest exercises the live widget tree).

```bash
flutter test integration_test/
```

CI runs this after `flutter test` in `.github/workflows/` (first run compiles the desktop runner and can take several minutes).

## CI release naming

On **push to `main`**, workflows patch the desktop product name from **`github.event.repository.name`** (the GitHub repository name, not the Dart package name):

- **Artifacts:** `<repository-name>-macos` and `<repository-name>-windows`.
- **macOS:** `PRODUCT_NAME` in `macos/Runner/Configs/AppInfo.xcconfig` is updated before `flutter build macos`; if the bundle is still `dhis_todo.app`, it is renamed to `<repository-name>.app` before upload.
- **Windows:** `BINARY_NAME` in `windows/CMakeLists.txt` is updated before `flutter build windows` so the built `.exe` matches the repository name.

PR builds do not patch names or upload artifacts.

## Branding and icons

Branding uses the **CHINGALO Family Information Systems** logo at [`assets/images/chingalo_receipt_logo.png`](assets/images/chingalo_receipt_logo.png) (1024×1024 source artwork).

### App icon (macOS and Windows)

Desktop launcher icons are generated from that asset via [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) (configured in `pubspec.yaml`):

| Platform | Output |
|----------|--------|
| **macOS** | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` (PNG sizes 16–1024) |
| **Windows** | `windows/runner/resources/app_icon.ico` |

Regenerate after changing the source image:

```bash
dart run flutter_launcher_icons
flutter clean
flutter build macos --release    # or flutter build windows --release
```

Icons are committed to the repo so CI (`windows_release.yml` and macOS workflows) picks them up automatically—no extra workflow steps.

Use a **square** master PNG (1024×1024 recommended). For sharper Dock/taskbar icons at small sizes, consider a cropped icon-only variant; the full logo with wordmark is what ships today.

### Receipt PDF logo

Official receipt PDFs (Settings → **Print official receipt**) embed the same asset in the header via `lib/services/official_receipt_pdf.dart`. Restart the app after asset changes so `rootBundle` reloads.

