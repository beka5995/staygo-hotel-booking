import 'dart:io';

import 'package:final_project_android_hotelbooking/database/journal_database.dart';
import 'package:final_project_android_hotelbooking/main.dart';
import 'package:final_project_android_hotelbooking/services/journal_photo.dart';
import 'package:final_project_android_hotelbooking/services/staygo_links.dart';
import 'package:final_project_android_hotelbooking/state/hotel_store.dart';
import 'package:final_project_android_hotelbooking/state/preferences_store.dart';
import 'package:final_project_android_hotelbooking/widgets/hotel_result_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as image;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fixtures.dart';

void main() {
  Future<HotelStore> open(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = HotelStore(service: fixtureService());
    final preferences = await PreferencesStore.load();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      preferences.dispose();
    });
    await tester.pumpWidget(
      MyApp(
        preferences: preferences,
        store: store,
        enablePlatformServices: false,
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('Central Add puts one hotel in Trip List and Favorites', (
    tester,
  ) async {
    final store = await open(tester);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to Favorites'));
    await tester.tap(find.text('Add selected'));
    await tester.pumpAndSettle();

    expect(store.favorites.single.id, store.hotels.first.id);
    await tester.tap(find.byTooltip('Trip List'));
    await tester.pumpAndSettle();
    expect(find.text(store.hotels.first.name), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Add to Trip'), findsOneWidget);
    expect(store.favorites, hasLength(1));
  });

  test('Explore accepts native and web hotel links', () {
    for (final url in [
      'narxoz://store/product/g293974-d107',
      'staygo://hotel/g293974-d107',
      'http://localhost:7359/#/hotel/g293974-d107',
    ]) {
      expect(hotelIdFromSearch(url), 'g293974-d107');
    }
    expect(
      hotelIdFromSearch('https://stay.example.com/#/hotel/invalid'),
      isNull,
    );
  });

  testWidgets('Explore finds a hotel beyond Home and opens its copied link', (
    tester,
  ) async {
    final store = await open(tester);
    expect(store.hotels, hasLength(6));
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    final search = find.widgetWithText(TextField, 'Name or hotel link');
    await tester.enterText(search, 'Test Stay 7');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(HotelResultTile, 'Test Stay 7'), findsOneWidget);

    await tester.enterText(search, 'narxoz://store/product/g293974-d107');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open hotel'));
    await tester.pumpAndSettle();
    expect(find.text('Hotel details'), findsOneWidget);
    expect(find.text('Test Stay 7'), findsOneWidget);
  });

  testWidgets('Journal opens from the one-line label on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester);

    await tester.tap(find.text('Journal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.widgetWithText(AppBar, 'Photo Journal'), findsOneWidget);
    expect(find.text('Front'), findsOneWidget);
    expect(find.text('Rear'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Journal keeps the photo and location after reopening SQLite', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    final path = await Directory.systemTemp.createTemp('staygo-journal-');
    await databaseFactory.setDatabasesPath(path.path);
    const journal = JournalDatabase();
    try {
      final photo = optimizeJournalPhoto(
        image.encodePng(image.Image(width: 1200, height: 400)),
      );
      expect(image.decodeJpg(photo)?.width, 1080);
      final time = DateTime(2026, 11, 24, 12);
      final saved = await journal.save(
        photo: photo,
        caption: 'First stay',
        takenAt: time,
        location: Position(
          latitude: 43.2389,
          longitude: 76.8897,
          timestamp: time,
          accuracy: 12,
          altitude: 840,
          altitudeAccuracy: 3,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      await (await journal.open()).close();
      final restored = (await journal.read()).single;
      expect(restored.id, saved.id);
      expect(restored.caption, 'First stay');
      expect(restored.takenAt, time);
      expect(restored.coordinates, '43.23890, 76.88970');
      expect(restored.accuracy, 12);
      expect(restored.photo, orderedEquals(photo));
      await journal.delete(saved.id);
      expect(await journal.read(), isEmpty);
    } finally {
      await (await journal.open()).close();
      await path.delete(recursive: true);
    }
  });
}
