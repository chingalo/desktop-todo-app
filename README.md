# ProgramPilot (`dhis_todo`)

Flutter **desktop** app (macOS and Windows): Material 3 UI, offline todos, sign up / sign in, and optional DHIS2 program import with HTTP Basic authentication.

Full repository documentation (layout, CI, testing, security) lives in the [parent README](../README.md).

## Quick start

```bash
flutter pub get
dart run build_runner build   # after editing lib/data/database.dart tables
flutter analyze
flutter test
flutter run -d macos          # or -d windows
```

## Package vs product name

- **Dart package:** `dhis_todo` (folder and `pubspec.yaml` name).
- **Product / UI name:** ProgramPilot.

## Data storage

SQLite via **Drift** (`lib/data/database.dart`). Database file: `program_pilot.sqlite` under application support. Tests use `AppDatabase(NativeDatabase.memory())`.

## Session storage

`lib/state/session_store.dart` defines `SessionStore`; production uses `SecureSessionStore` (Keychain / platform secure storage). Tests inject `InMemorySessionStore` from `test/support/`.
