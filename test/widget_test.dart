import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project_android_hotelbooking/state/preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_project_android_hotelbooking/main.dart';
import 'package:final_project_android_hotelbooking/state/hotel_store.dart';
import 'package:final_project_android_hotelbooking/screens/registration_screen.dart';

import 'support/fixtures.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  Future<HotelStore> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = HotelStore(
      service: fixtureService(),
      refreshDelay: const Duration(milliseconds: 1500),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
    await tester.pumpWidget(
      MyApp(
        preferences: await PreferencesStore.load(),
        store: store,
        enablePlatformServices: false,
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 360),
    const Size(1440, 900),
  ]) {
    testWidgets('Catalog and details fit $size without layout exceptions', (
      tester,
    ) async {
      await open(tester, size: size);
      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Test Stay 0').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Stay 0').first);
      await tester.pumpAndSettle();
      expect(find.text('Hotel details'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
    });
  }

  testWidgets(
    'Pull-to-refresh retains its scrollable and prepends a network stay',
    (tester) async {
      final store = await open(tester);
      await tester.drag(find.byType(GridView), const Offset(0, 300));
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(store.hotels, hasLength(7));
      expect(store.hotels.first.id, 'g293974-d106');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('List swipes right to left and UNDO restores the original item', (
    tester,
  ) async {
    final store = await open(tester);
    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    final id = store.hotels.first.id;
    await tester.drag(find.byKey(ValueKey(id)), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(store.hotels, hasLength(5));
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(store.hotels.first.id, id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Offline clears catalog and Retry loads it without restarting', (
    tester,
  ) async {
    final store = await open(tester);
    store.setNetworkAvailable(false);
    await tester.pumpAndSettle();
    expect(find.text('Unable to load hotels'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    await tester.tap(find.text('Retry Connection'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets(
    'Cart removes on a second screen and immediately updates catalog',
    (tester) async {
      await open(tester);
      await tester.tap(find.text('Add to Trip').first);
      await tester.pumpAndSettle();
      expect(find.text('Remove from Trip'), findsOneWidget);
      await tester.tap(find.byTooltip('Trip List'));
      await tester.pumpAndSettle();
      expect(find.text('Estimated total'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove item'));
      await tester.pumpAndSettle();
      expect(find.text('Your trip list is empty'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Remove from Trip'), findsNothing);
    },
  );

  testWidgets(
    'Favorite survives tab navigation and details open without duplicate heroes',
    (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Save to favorites').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Stay 0'));
      await tester.pumpAndSettle();
      expect(find.text('Hotel details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Registration validates fields and terms before submission', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegistrationScreen()));
    final button = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Please accept the Terms and Conditions'), findsOneWidget);
    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
  });
}
