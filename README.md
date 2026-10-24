# StayGo

**StayGo** is a hotel discovery application built with Flutter and Dart. It helps travelers explore accommodation options, compare hotel details, and keep interesting places in one convenient favorites list.

## Features

- **Hotel discovery:** Browse hotel cards with photos, destinations, ratings, and nightly prices.
- **Search and filters:** Find hotels by name or location and browse All, Beach, Resort, City, and Nature categories.
- **Hotel details:** View hotel descriptions, guest ratings, amenities, and prices, with a bookmark button on the main photo.
- **Favorites:** Save or remove hotels and access them from a dedicated tab.
- **Catalog layouts:** Switch between a two-column grid and a scrolling list.
- **Interactive catalog:** Pull to refresh to add a sample hotel, swipe left in list mode to remove a listing, restore it with **UNDO**, or use **Reset Catalog**.
- **Travel profile:** Complete a registration form with name, email, password confirmation, account type, and terms acceptance.
- **Booking preview:** Tap **Book now** to view a hotel summary in a bottom sheet.

## Main Screens

| Screen | Description |
| --- | --- |
| **Explore** | Hotel catalog, search bar, category filters, and grid/list toggle. |
| **Hotel Details** | Photo with bookmark overlay, hotel information, amenity tags, and booking preview. |
| **Favorites** | Saved hotels with direct access to their detail pages. |
| **Profile** | Current travel profile or an option to create one. |
| **Registration** | Input fields, validation messages, role selection, and terms checkbox. |

## Flutter Implementation

- **Layouts:** `Column`, `Row`, `Card`, `Expanded`, `Flexible`, `Stack`, `Wrap`, and scrollable views.
- **Interactive UI:** `StatefulWidget` and `setState()` for tab selection, favorites, search filters, and display mode.
- **Catalog widgets:** `GridView.builder`, `ListView.separated`, `RefreshIndicator`, and `Dismissible`.
- **Navigation:** `NavigationBar`, `IndexedStack`, `Navigator.push`, and `Navigator.pop`.
- **Forms:** `Form`, `GlobalKey<FormState>`, `TextEditingController`, and field validation.
- **Reusable components:** Separate widgets for hotel cards, list tiles, and network images.

The `HomeScreen` manages the in-memory hotel catalog, favorite IDs, and user profile. Child screens receive data and callbacks to keep the interface synchronized.

## Project Structure

```text
lib/
├── main.dart                     # Application entry point
├── data/
│   └── sample_hotels.dart        # Sample hotel listings
├── models/
│   ├── hotel.dart                # Hotel data model
│   └── user_profile.dart         # User profile model
├── screens/
│   ├── home_screen.dart          # Navigation and shared screen state
│   ├── discover_screen.dart      # Catalog, search, filters, and gestures
│   ├── hotel_screen.dart         # Hotel details and booking preview
│   ├── favorites_screen.dart     # Saved hotels
│   ├── profile_screen.dart       # Profile page
│   └── registration_screen.dart  # Registration and validation
├── theme/
│   └── app_theme.dart            # Colors and theme settings
└── widgets/
    ├── hotel_card.dart           # Grid card component
    ├── hotel_list_tile.dart      # List item component
    └── hotel_image.dart          # Network image with fallback

test/
└── widget_test.dart              # Flutter widget tests

android/                          # Android runner
web/                              # Web runner
ios/                              # iOS runner
linux/                            # Linux runner
macos/                            # macOS runner
windows/                          # Windows runner
pubspec.yaml                      # Packages and project configuration
analysis_options.yaml             # Dart analysis rules
README.md                         # Project documentation
```

## Getting Started

With Flutter installed, open the project folder and run:

```bash
flutter pub get
flutter run
```

To check the project:

```bash
flutter analyze
flutter test
```

> Hotel listings and prices are demonstration data. Favorites and profiles are kept in memory, and the booking button shows a preview rather than making a real reservation.

## Author

**Mashat Bekzhan**
