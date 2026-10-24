# StayGo 

StayGo is a Flutter hotel discovery app. Browse places to stay, compare hotel details, save favorites, and set up a personal travel profile. The same project supports Android and iOS.

## What works now

- **Discover:** Explore a sample catalog of hotels with images, ratings, locations and prices per night.
- **Search & filter:** Find a hotel by name/location and browse Beach, Resort, City or Nature categories.
- **Two catalog layouts:** Switch between a scrollable list and a two-column grid.
- **Hotel details:** View photos, descriptions, ratings, amenities and prices. Save a hotel using the bookmark button.
- **Favorites:** Add or remove hotels; the saved list stays in sync when changing screens.
- **Profile setup:** Register with name, email, password, confirmation, Terms checkbox and a role. Form errors appear as you type and on submission.
- **Gestures:** Pull down to simulate loading a new hotel (1.5-second delay). In list mode, swipe left on a hotel to remove it and use **UNDO** to restore it. If all hotels are removed, choose **Reset Catalog**.
- **Navigation:** Use Explore, Favorites and Profile tabs. Hotel detail screens have a top and in-page back button.

The **Book now** action currently opens an informational booking preview. Payments, real reservations, account authentication and cloud data are **not** implemented yet. Profile, favorites and catalog changes live in memory and reset when the app restarts. Hotel images load online and show a placeholder when offline.

## Planned features (for the final stage)

These **three features are plans only**. They are not implemented in the current version and will be added near the end of the project.

1. **Smart Hotel Match** — Help users find hotels that suit their budget, guest count, and preferred amenities. Display a simple match percentage based on the selected filters.
2. **Group Trip Voting** — Let friends create a poll with a few hotel options, vote, and see which hotel the group prefers.
3. **Split Stay Cost** — Calculate the total stay cost using the nightly rate and number of nights, then split the amount between travelers.

Other possible later improvements: REST API integration, database storage, BLoC state management and actual booking functionality.

## Run the app

Requirements: Flutter SDK, Dart, and Android Studio or VS Code with the Flutter extension.

```bash
flutter pub get
flutter run
```

For Android, start an emulator or connect a phone with USB debugging enabled. For iOS, an iOS simulator or device with the necessary Apple build tools is required (macOS + Xcode).

### Check the project

```bash
flutter analyze
flutter test
```

## Project structure

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

The home screen owns the current catalog, saved IDs and profile data. Other screens receive the data and callbacks they need. This keeps the example straightforward and makes it easier to replace the sample data with an API later.

## Try it out

1. Open **Explore**, tap a hotel and check its details.
2. Tap the bookmark or heart and see the hotel appear in **Favorites**.
3. Switch between the grid and list using the buttons above the catalog.
4. Pull down to insert a new item at the start of the catalog.
5. In list mode, swipe a hotel left, then tap **UNDO** on the message.
6. Open **Profile** > **Create account**, test the validation messages and fill out the form.

## Notes

All hotel listings and prices are **demonstration data**. They are not live hotel offers. This project is still in active development.
