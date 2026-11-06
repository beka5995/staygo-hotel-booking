import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:final_project_android_hotelbooking/data/sample_hotels.dart';
import 'package:final_project_android_hotelbooking/models/hotel.dart';
import 'package:final_project_android_hotelbooking/providers/cart_provider.dart';
import 'package:final_project_android_hotelbooking/screens/discover_screen.dart';
import 'package:final_project_android_hotelbooking/services/hotel_places_service.dart';

void main() {
  test('Each destination retains a featured hotel with three photos', () {
    for (final city in hotelCities) {
      final featured = sampleHotels.where(
        (hotel) => hotel.city.toLowerCase().contains(city.name.toLowerCase()),
      );
      expect(featured, isNotEmpty, reason: city.name);
      for (final hotel in featured) {
        expect(hotel.gallery, hasLength(3));
        expect(hotel.assetPhotos, hasLength(3));
      }
    }
  });

  testWidgets('A hotel is visible even if the live city request fails',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final featured = sampleHotels.where(
      (hotel) => hotel.city.contains('Phuket'),
    ).toList();
    await tester.pumpWidget(
      ChangeNotifierProvider<CartProvider>(
        create: (_) => CartProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: DiscoverScreen(
              hotels: featured,
              favoriteIds: const {},
              onHotelTap: (Hotel hotel) {},
              onFavoriteTap: (Hotel hotel) {},
              onRefresh: () async {},
              onDismiss: (Hotel hotel) {},
              onReset: () {},
              onlineMode: true,
              onlineLoading: false,
              onlineError: 'Too many requests',
              selectedCity: hotelCities.last,
              onBrowseCity: (HotelCity city) {},
              onShowFeatured: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Palm Garden Suites'), findsOneWidget);
    expect(find.text('Unable to load hotels'), findsNothing);
  });
}
