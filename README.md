# StayGo

StayGo is a Flutter app for discovering hotels, comparing accommodation details and planning a trip. The same project opens in Android Studio, runs on Android and supports Flutter Web.

## Explore

The **Explore** tab includes six featured stays with photos, descriptions, nightly planning rates and amenities. Search by name or destination, filter by category, switch between grid and list views, save favorites and add featured stays to **Trip List**. A live badge shows the number of hotels selected. Choose nights (1–30), remove individual items or clear the list, and see the total update across screens.

Explore also lets you browse locations in **Almaty, Istanbul, Dubai and Phuket**. Tapping a city immediately shows a matching featured stay, while the app checks for additional hotel listings online. A busy or unavailable server does not clear the screen: saved featured stays remain visible. The app caches successful searches in memory for five minutes to avoid unnecessary repeated requests, and pull-to-refresh reloads the city. Featured remains available without a connection.

Public hotel records generally do not contain reliable room rates, reviews, booking availability or verified photography. To provide a smooth experience, external listings include three **clearly labeled destination illustrations**, not photographs of the actual property. Only featured stays with planning rates can be added to Trip List. Featured stays have three different travel photographs with three distinct locally packaged illustrations as offline fallbacks.

## Hotel details

Every stay has a three-page gallery, an animated page indicator and page counter. On Android you can swipe; in Chrome you can drag with the mouse or use the previous/next arrows. Matching image tags animate between the hotel card and detail page. The **Share** action opens a bottom sheet to copy a link such as `staygo://hotel/ocean`. On Android the custom scheme is registered for opening a featured hotel from outside the app. Hotel locations found through OpenStreetMap share their public OpenStreetMap page.

The featured images and prices are illustrative planning content, **not verified inventory, reservation availability or payment offers**. This app does not make or confirm bookings. The featured gallery photos represent travel destinations rather than verified photos of one real property. Offline illustrations are stored in `assets/stays/`.

## Your account

Profile supports registration, sign-in, sign-out and a local session stored in SQLite. Form validation and the existing bcrypt-based password handling are preserved. Favorites and the trip list are kept in application state; they are not synced with an external booking service.

## Run in Android Studio

1. Extract `StayGo_AndroidStudio_Ready.zip` and open the **StayGo** folder in **Android Studio → Open** (select the folder containing `pubspec.yaml`).
2. Ensure the Flutter and Dart plugins are installed, and an Android emulator is running.
3. In the Android Studio terminal, run:

   ```bash
   flutter pub get
   flutter run
   ```

4. For checks and packaging:

   ```bash
   flutter analyze
   flutter test
   flutter build apk --debug
   flutter build web --release
   ```

The APK appears in `build/app/outputs/flutter-apk/` after successful build. The ZIP contains **source files**, not a precompiled APK. Android Studio/Flutter will recreate generated files and local SDK paths when you run it.

### Open a shared hotel on Android

With the application installed and the emulator running:

```bash
adb shell am start -a android.intent.action.VIEW -d "staygo://hotel/ocean"
```

External opening of links should be tested on the target Android device. iOS scheme registration is included but iOS execution has not been verified.

## Technical notes

- Flutter / Dart, Provider, sqflite, bcrypt, http.
- `HotelPlacesService`: keyless GET request to `https://overpass.private.coffee/api/interpreter`, timeout of 10 seconds, JSON parsing and HTTP error handling. Network responses can vary and this publicly hosted service may be rate-limited or temporarily unavailable. The app requests hotel records only on user action, not repeatedly in the background.
- HTTP behavior and model parsing can be exercised using `http/testing.dart` mock clients.
- Featured hotel data lives in `lib/data/sample_hotels.dart` and may be replaced with verified inventory when a booking backend becomes available.
- Place records © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), Open Database License. Credit can be found under Profile → About StayGo as well as here. Overpass is an external read-only query service.
- Profile data is local to each device. No online booking confirmations or payments are made.

## Project layout

`lib/` has models, screens, Provider, SQLite, services and reusable UI widgets. `test/` contains widget tests and tests for the network service, gallery and shared links. `android/`, `ios/` and `web/` contain platform runners.


## Hotel photos

The six featured hotel profiles use three locally bundled, location-themed illustrative hotel images each (`assets/stays/`). They work without an internet connection. These are illustrative images of fictional property listings, not verified photographs of an actual hotel or evidence of room availability. The hotel titles, prices and ratings are sample content.

For a real accommodation listing, use property-owner-provided/verified images, confirmed pricing and booking information. Live place search results use location-themed illustrations when verified property photos are unavailable.
