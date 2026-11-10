# LAB 11 verification — 10 November 2026

- Environment: Flutter 3.47.2, Dart 3.13.2.
- flutter pub get: passed.
- flutter analyze: No issues found.
- flutter test: 53 tests passed, including notes/settings, restored selections and navigation.
- flutter build web --no-pub --no-web-resources-cdn: passed; Wasm dry run passed.
- Real-file persistence: actual SharedPreferences Linux backend, separate write/read/delete-verification Flutter processes. Favorites and cart/trip options survived process restart, and cleared selections stayed cleared. This used an isolated on-disk file, not the in-memory mock backend. Previous LAB11 checks also verified theme, name and notes with separate processes.
- Native tests used the installed system SQLite library via a temporary test-only configuration, avoiding a native binary download. That Linux configuration is not included in this project.
- Light/dark Notes and dark catalog screenshots at phone size were inspected with real fonts. Catalog screenshot records are fixtures; live API photographs were not verified by this image review. Responsive tests cover narrow and wide layouts, including the Notes action and preserved tab on Back.
- Saved malformed selections are skipped safely. Rapid changes, removal and restored options are covered.
- Hotel rates: tests cover cards shown before pending rates, detail price updates, stale replies after going offline, and delete/undo during rate requests.

Native Android/iOS builds, target-device force-kill and browser end-to-end clicking were not executed here. Complete the cold restart demonstration on your phone/emulator using LAB11_RU.md. Local preference snapshots do not replace the live catalog or provide account/device synchronization. Network photos can be unavailable offline.

No GitHub repository was changed. No passwords/tokens were added to SharedPreferences. Existing SQLite authentication schema and API endpoints are retained. UPDATE_RU.md explains how to preserve existing debug browser data during an update.
