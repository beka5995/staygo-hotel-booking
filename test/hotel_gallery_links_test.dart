import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project_android_hotelbooking/data/sample_hotels.dart';
import 'package:final_project_android_hotelbooking/models/hotel.dart';
import 'package:final_project_android_hotelbooking/services/staygo_links.dart';
import 'package:final_project_android_hotelbooking/widgets/hotel_gallery.dart';

void main() {
  test('Curated stays have three distinct gallery images', () {
    expect(sampleHotels, hasLength(6));
    for (final hotel in sampleHotels) {
      expect(hotel.gallery, hasLength(3));
      expect(hotel.assetPhotos, hasLength(3));
      expect(hotel.gallery.toSet(), hasLength(3));
      expect(hotel.gallery.every((path) => path.startsWith('assets/stays/')), isTrue);
      expect(hotel.imageUrl, hotel.gallery.first);
      expect(hotel.hasPrice, isTrue);
    }
  });

  test('Deep links identify the hotel without a store route', () {
    final hotel = sampleHotels.first;
    expect(hotelShareLink(hotel), 'staygo://hotel/ocean');
    expect(hotelIdFromLink('staygo://hotel/ocean'), 'ocean');
    expect(hotelIdFromLink('/hotel/ocean'), 'ocean');
    expect(hotelIdFromLink('narxoz://store/product/1'), isNull);
    expect(hotelIdFromLink('staygo://hotel'), isNull);
  });

  test('Locations share the public source, not an invented hotel price', () {
    const place = Hotel(
      id: 'osm-node-50',
      name: 'Example',
      city: 'Almaty',
      pricePerNight: 0,
      rating: 0,
      imageUrl: '',
      description: '',
      category: 'Hotel',
      amenities: [],
      sourceUrl: 'https://www.openstreetmap.org/node/50',
    );
    expect(hotelShareLink(place), place.sourceUrl);
    expect(place.gallery, isEmpty);
    expect(place.hasPrice, false);
  });

  testWidgets('Hotel gallery swipes between three photos', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HotelGallery(hotel: sampleHotels.first)),
    ));
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-340, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-340, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
  });
  testWidgets('Photo arrows move through the complete gallery', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HotelGallery(hotel: sampleHotels.first)),
    ));
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Next photo'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Next photo'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous photo'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('Wide screens show a readable gallery and enlarged photos',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HotelGallery(hotel: sampleHotels.first)),
    ));

    final gallerySize = tester.getSize(find.byType(PageView).first);
    expect(gallerySize.width, lessThanOrEqualTo(820));
    expect(gallerySize.height, greaterThan(450));
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.tap(find.byTooltip('View photo full screen'));
    await tester.pumpAndSettle();
    expect(find.text('Ocean Hotel'), findsOneWidget);
    await tester.tap(find.byTooltip('Next full screen photo'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
  });

}
