# StayGo — HotelBooking

A single Flutter application for discovering hotels and planning a trip. Explore, Favorites, Profile, hotel details and Trip List share the same network-backed hotel objects.

## Run

Requires Flutter with Dart **3.13.2 or newer**, and Chrome or an Android emulator.

**Android**, from the project folder:

```powershell
flutter pub get
flutter run
```

**Chrome on Windows** — one command starts a local web gateway and Flutter:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_web.ps1
```

Keep that terminal open. Stop with Ctrl+C. The script closes its gateway when Flutter exits. If port 8765 is occupied by a previous launch, stop that launch first. macOS/Linux: `bash run_web.sh`.

Alternative, two terminals from the project folder:

```powershell
# Terminal 1: keep this running
 dart run tool/hotel_proxy.dart
# Terminal 2
 flutter pub get
 flutter run -d chrome --dart-define=STAYGO_API_URL=http://127.0.0.1:8765/api
```

Xotelo does not send browser CORS headers. `tool/hotel_proxy.dart` forwards hotel requests and images for the local Chrome app; it has no catalog, cache, API key or offline data. Its upstream hosts are fixed. Android/iOS call Xotelo directly. A published web app needs a hosted gateway and its address supplied with `STAYGO_API_URL`; simply publishing static files to GitHub Pages will not host the Dart gateway. GitHub is not needed to run the app locally.

## Features

- Initial catalog loads six real hotel records from Xotelo. Destinations: Istanbul, Astana, Almaty, Dubai and Phuket. No bundled product catalog or offline substitute.
- Loading spinner, success and error with **Retry Connection**. HTTP 404, 429, server errors, malformed JSON, timeouts and network errors are handled.
- Real hotel name, city, property image and available review information. Search, category filters, two-column grid (`0.72`) and lazy separated list.
- Pull down **inside the hotel list/grid**, or press the refresh icon. The existing scrollable stays mounted during refresh. The app waits at least 1.5 seconds, requests the directory again and prepends the next unseen real result when one is available. It fetches up to 100 records as the catalog grows; it does not invent a new hotel if the source is exhausted.
- List view: swipe right to left, red delete background, stable hotel ID key, floating **UNDO** restoring the original index. Remove all visible hotels to show **Catalog is Empty → Reset Catalog**.
- Favorites, bottom tabs, complete object passed to detail screen; AppBar back and **Back to hotels** preserve root state.
- Adaptive detail screen: image Stack and bookmark, Row/Wrap labels and sticky full-width Expanded trip button.
- Gallery: PageView, Hero, page counter, animated dots, arrows, mouse drag and full-screen zoom. Xotelo supplies one property photograph. Two separately labeled **Travel inspiration** illustrations supplement the gallery. Missing property images show a placeholder, never a different hotel's picture.
- Global ChangeNotifier/Provider Trip List, live badge, add/remove toggles, nights 1–30, Clear All and estimated total synchronized across screens.
- Registration/sign-in: Form, controllers, real-time and submit validation, confirmation password, terms, role, success feedback. Local SQLite accounts and bcrypt hashing retained. Registration is local; it is not an account on Xotelo.
- Share sheet copies `narxoz://store/product/g293974-d17323488`. Native registration also accepts `staygo://hotel/<id>`. Browser route: `/#/hotel/<id>`. Link targets are resolved through the network after restarting.

## Internet and rates

The app checks OS connection events and makes a small real directory request every 8 seconds while active, with a 4-second timeout. When a check fails, Explore clears its visible catalog and shows Retry. Returning to the app triggers another check. Detection is asynchronous; allow about 12 seconds after disabling the network. Retry always makes a fresh HTTP request. No local catalog fallback is used. Previously saved Favorites/Trip List are in-memory user selections and can remain visible; they are not proof that the directory is online.

List results have no reliable USD price. The app separately requests `/rates` in USD for **one night, 14 days from today**, and uses the lowest positive returned rate. Numeric parsing accepts both integer and double values. Missing/failed tariffs show **Price on request** and are excluded from the trip total. The total is a budget estimate, not a quote for an arbitrary number of consecutive nights or a confirmed reservation. Prices and availability can change. No payments or reservations are submitted.

Directory and rates: [Xotelo documentation](https://xotelo.com/), API base `https://data.xotelo.com/api`. Property images are URLs supplied by Xotelo. The main hero is AI-generated artwork in `assets/branding/`; it is not a specific hotel listing.

## Coursework map

| Lab | Implementation |
| --- | --- |
| 5 | `screens/hotel_screen.dart`, `widgets/hotel_gallery.dart` |
| 6 | `screens/registration_screen.dart`, `database/local_auth.dart` |
| 7 | `screens/home_screen.dart`, `screens/hotel_screen.dart` |
| 8 | `screens/discover_screen.dart`, `state/hotel_store.dart` |
| 9 | `providers/cart_provider.dart`, `screens/trip_list_screen.dart`, Provider above MaterialApp |
| 10 | `services/hotel_places_service.dart`, `models/hotel.dart`, `models/hotel_rate.dart`, gallery and share links |

## Validation

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web
```

Or run `powershell -ExecutionPolicy Bypass -File .\check_project.ps1`.

Tests use mocked responses, not the live directory or an offline fallback in the app. They cover numeric conversion, HTTP errors, rates, real refresh logic, offline invalidation, UNDO/reset, cart synchronization, navigation, gallery and responsive layouts. See `PROJECT_CHECK.md` for what was actually verified before delivery. Validation here passed: Flutter analyze, all 32 tests and a web release build. Re-run the commands after local changes. Native device execution and Chrome end-to-end interaction still require local checks; no precompiled application is included.

For native link verification with the app installed:

```powershell
adb shell am start -a android.intent.action.VIEW -d "narxoz://store/product/g293974-d17323488"
```

Favorites and Trip List live for the app session. SQLite preserves accounts and the active account. This is a student travel planner without a production booking backend.
