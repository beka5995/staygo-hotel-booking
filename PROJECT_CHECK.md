# StayGo source verification

This document describes changes to the source package and checks that still need an installed Flutter SDK or emulator.

## Source improvements

- Existing navigation, local sign-in/registration, SQLite, favorites, grid/list catalog, swipe/remove/undo, refresh, and Provider-backed Trip List kept in place.
- Hotel locations are fetched from a less heavily rate-limited Overpass instance. Each city first shows a matching featured stay and keeps it visible when the external server is unavailable. Successful city results are cached for five minutes.
- Added service-level handling for 200, 404, 429, 5xx, timeouts, invalid JSON and connection failures, with retry in the Explore screen.
- Added a three-page gallery with PageView.builder, Hero, counter, animated dots, mouse drag, and previous/next arrows. Featured stays use different photo URLs and locally bundled illustrations as offline fallbacks; external listings show three labeled destination illustrations instead of falsely identifying stock photos as the property.
- Added a share bottom sheet, clipboard copy and a custom staygo://hotel/<id> route for featured hotels.
- Removed the non-working booking confirmation placeholder and inactive profile settings dialogs.
- Kept source code and user-facing interface free of instructional labels and the unrelated product marketplace.
- Added mock-client service tests, gallery and link tests, and updated the existing hotel-detail test for the new button.

## Verification in this environment

- ZIP integrity, archived file inventory, key file presence and token-level Dart delimiter balance: checked.
- `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk`, and emulator interaction: **not run** (Flutter and Android SDK are not installed in this execution environment).
- Network calls against the real Overpass server: **not run** (outgoing network requests are unavailable here).
- Shared-link opening on Android/iOS: **not run**, registration and Dart route parsing included.

## Manual checks before delivery

1. Open in Android Studio and run `flutter pub get` then `flutter analyze` and `flutter test`.
2. Start the emulator and browse Featured → Hotel Details. Swipe the gallery through 1/3 → 2/3 → 3/3, use Share and Copy, add to Trip List, change nights and return to Explore to verify the live badge.
3. Tap Phuket or Almaty. Even if the external service fails, a featured stay must stay visible. Open its detail page, verify three images and arrows. Refresh and confirm the screen does not become blank. The dedicated error/retry state is still used if no stays are available at all.
4. Verify registering, signing out, relaunching and signing in again with SQLite intact.
5. Run `flutter build apk --debug`. Test a link with ADB as shown in README.md.

The original rubric's fixed Fake Store endpoint and product-specific UI have not been implemented because the requested application is hotel-focused; if assessment requires that exact endpoint, it must be addressed separately. External hotel records contain no verified booking prices or room photos.
