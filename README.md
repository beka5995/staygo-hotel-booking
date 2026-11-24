# StayGo — HotelBooking

A single Flutter application for discovering hotels and planning a trip. Home, Explore, Favorites, Profile, hotel details and Trip List share the same network-backed hotel objects.

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
 dart tool/hotel_proxy.dart
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
- Home has Grid and List views with direct Trip List and favorites actions.
- Explore searches the directory loaded for the selected city and opens copied hotel links.
- Add lets you select a hotel and save it to Trip List, Favorites, or both.
- Stay details receive the complete hotel object. The back button preserves catalog state.
- Adaptive detail screen: image Stack and bookmark, Row/Wrap labels and sticky full-width Expanded trip button.
- Gallery: PageView, Hero, page counter, animated dots, arrows, mouse drag and full-screen zoom. Xotelo supplies one property photograph. Two separately labeled **Travel inspiration** illustrations supplement the gallery. Missing property images show a placeholder, never a different hotel's picture.
- Global CartBloc Trip List, live badge, add/remove toggles, nights 1–30, Clear All and estimated total synchronized across screens.
- Registration/sign-in: Form, controllers, real-time and submit validation, confirmation password, terms, role, success feedback. Local SQLite accounts and bcrypt hashing retained. Registration is local; it is not an account on Xotelo.
- Share sheet copies `narxoz://store/product/g293974-d17323488`. Native registration also accepts `staygo://hotel/<id>`. Browser route: `/#/hotel/<id>`. Link targets are resolved through the network after restarting.

## Internet and rates

The app checks OS connection events and makes a small real directory request every 8 seconds while active, with a 4-second timeout. When a check fails, Home and Explore show a retry action. Returning to the app triggers another check. Detection is asynchronous; allow about 12 seconds after disabling the network. Retry always makes a fresh HTTP request. No local catalog fallback is used. Previously saved Favorites/Trip List are local user selections and can remain visible after restart; they are not proof that the directory is online.

Hotel cards appear as soon as the directory arrives. Rates load independently in parallel; each card and an already open detail screen update when its rate arrives. Pending rates show Checking price…. List results have no reliable USD price. The app separately requests `/rates` in USD for **one night, 14 days from today**, and uses the lowest positive returned rate. Numeric parsing accepts both integer and double values. Missing/failed tariffs show **Price on request** and are excluded from the trip total. The total is a budget estimate, not a quote for an arbitrary number of consecutive nights or a confirmed reservation. Prices and availability can change. No payments or reservations are submitted.

Directory and rates: [Xotelo documentation](https://xotelo.com/), API base `https://data.xotelo.com/api`. Property images are URLs supplied by Xotelo. The main hero is AI-generated artwork in `assets/branding/`; it is not a specific hotel listing.

## Photo Journal

Open **Journal** in the bottom bar. Choose Front or Rear and tap Take Photo,
or pick an existing image from Gallery. Tap Fetch GPS, enter a caption and save.
The photo, coordinates, timestamp and accuracy are stored locally and are also
visible from **Profile → Photo Journal** after signing in.

For Chrome, use the localhost address opened by the web script and allow camera
and location access. For the Android emulator, set Front and Rear to Webcam0
in Device Manager and set a location in Extended Controls → Location.

## Validation

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web
```

Or run `powershell -ExecutionPolicy Bypass -File .\check_project.ps1`.

Catalog tests use mocked HTTP responses and cover offline handling, refresh, navigation and responsive layouts.

For native link verification with the app installed:

```powershell
adb shell am start -a android.intent.action.VIEW -d "narxoz://store/product/g293974-d17323488"
```

Favorites and Trip List are saved locally, including the number of nights. SQLite preserves accounts and the active account.


## Account and shopping state

Register or sign in from Profile. After signing in, the app opens the catalog.
Accounts are stored locally in SQLite. AuthCubit handles the asynchronous login
states. CartBloc receives add, remove and clear events and shares the current
selections, count and total across screens.

Open Notes from the top bar to manage your display name, theme and notes.
The app stores these settings, favorites and shopping selections on the device.
