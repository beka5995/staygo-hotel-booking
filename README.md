# StayGo

StayGo is a hotel discovery app built with Flutter. It helps travelers explore accommodation options, compare hotel information, and save places they like in one convenient interface.

## Features

- **Hotel discovery:** Browse a sample catalog with hotel photos, locations, ratings, and nightly prices.
- **Search and categories:** Search by hotel name or location, and explore Beach, Resort, City, and Nature categories.
- **Hotel details:** View photos, descriptions, amenities, ratings, and price information.
- **Favorites:** Bookmark hotels and manage saved places across screens.
- **Profile:** Create a temporary travel profile using a registration form with field validation.
- **Flexible catalog:** Switch between a two-column grid and a scrolling list.
- **Catalog interactions:** Pull to refresh, swipe to remove a hotel in list mode, undo removal, or reset the catalog.
- **Booking preview:** Open an informational preview from the Book Now button.

## Main Screens

- **Explore:** Hotel cards, search, category filters, and grid/list controls.
- **Hotel Details:** Large hotel image, information, amenities, favorite action, and booking preview.
- **Favorites:** Hotels saved by the user.
- **Profile & Registration:** Personal details and a validated account form.

## Flutter Implementation

- `Column`, `Row`, `Card`, and `Expanded` organize the main layouts.
- `Stack` places controls and information over hotel images.
- `GridView` and `ListView` provide alternative catalog layouts.
- `StatefulWidget` and `setState()` update interactive parts of the interface.
- Shared state in the home screen keeps hotel listings, favorites, and profile data synchronized through callbacks.
- Scrollable and adaptive layouts accommodate different screen sizes.

## Technologies

- Flutter and Dart
- Material Design
- StatefulWidget and setState
- Navigator
- Form and input validation

## Project Structure

```text
lib/
  main.dart
  data/
    sample_hotels.dart
  models/
    hotel.dart
    user_profile.dart
  screens/
    home_screen.dart
    discover_screen.dart
    hotel_screen.dart
    favorites_screen.dart
    profile_screen.dart
    registration_screen.dart
  theme/
    app_theme.dart
  widgets/
    hotel_card.dart
    hotel_list_tile.dart
    hotel_image.dart
```

## Getting Started

From the project folder, run:

```bash
flutter pub get
flutter run
```

## Author

**Mashat Bekzhan**

> Hotel listings are sample data. Favorites, profile information, and catalog changes are stored in memory; booking is currently a preview.
