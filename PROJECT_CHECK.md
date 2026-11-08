# Source and runtime verification — 8 November 2026

## Changes

One network-backed catalog replaces the bundled featured hotels and Overpass fallback. Provider Trip List, favorites, registration, city selection, list/grid, refresh, swipe/UNDO, empty reset, details, gallery and deep links are integrated. A new AI-generated StayGo hero is included. No GitHub repository was changed.

## Completed checks

- All five city requests returned HTTP 200 with actual hotel names: Istanbul, Astana, Almaty, Dubai and Phuket.
- A live rates request returned USD rates; the app selects the minimum positive rate and accepts integer/double JSON numbers.
- The Dart web gateway was actually started and returned HTTP 200 for directory JSON, rates JSON and a property JPEG, with CORS headers for the local Flutter origin and no-store caching. An image request to a non-allowlisted host returned HTTP 400.
- Dart analyzer checked the gateway, Hotel and HotelRate models: no issues.
- Flutter **3.47.2 / Dart 3.13.2** was installed for validation. `flutter pub get` succeeded.
- `flutter analyze`: **No issues found**.
- `flutter test`: **32 tests passed**. This includes 320×568, 390×844, 800×360 and 1440×900 widget layouts without layout exceptions, refresh, swipe/UNDO, offline/Retry, cart synchronization, gallery, navigation and registration validation.
- `flutter build web --no-web-resources-cdn`: **succeeded**; Wasm dry run also succeeded.
- Dart formatter parsed the project's Dart files. Relative/package-local imports, bundled image paths, Android XML, iOS plist and web JSON were checked.
- Fixed the registration Form to retain every field while scrolling, so submit-time validation checks off-screen fields too.
- Existing account database schema and bcrypt handling retained; no migration or data deletion added.

## Remaining environment checks

A real Chrome end-to-end run was attempted, but the environment prevents Chrome from creating its required process socket (Operation not permitted). Consequently, browser clicking, web SQLite registration and actual OS airplane-mode events were not verified end to end here. The web build, widget tests and live gateway requests were verified separately. Native Android/iOS builds, device execution and external deep-link opening also remain target-device checks; source configuration is not a device verification.

## Local acceptance check

Run `check_project.ps1`, then `run_web.ps1` in PowerShell. Inspect Explore → List/Grid → pull-to-refresh → swipe/UNDO → remove all/reset. Open a stay, navigate gallery, copy Share link, save a favorite, add to Trip List, change nights and remove it there; check that the Explore toggle updates. Register with both invalid and valid inputs. Disable internet, allow about 12 seconds, check that Explore clears and offers Retry; reconnect and Retry. Also check a narrow phone layout and a wide browser window.

The property API has one photo per record; additional gallery images are labeled travel inspiration. Unknown prices are excluded from the budget. The app does not execute reservations or payments.
