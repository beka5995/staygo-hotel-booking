import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_project_android_hotelbooking/services/staygo_links.dart';
import 'package:final_project_android_hotelbooking/widgets/hotel_gallery.dart';

import 'support/fixtures.dart';

void main() {
  test('Share sheet uses the laboratory deep link; both schemes and web routes parse', () {
    final hotel = hotelFixture(0);
    expect(hotelShareLink(hotel), 'narxoz://store/product/g293974-d100');
    for (final link in [
      hotelShareLink(hotel),
      'staygo://hotel/g293974-d100',
      '/hotel/g293974-d100',
    ]) {
      expect(hotelIdFromLink(link), hotel.id);
    }
    for (final link in [
      'narxoz://store/product/1',
      'staygo://hotel',
      'https://other.test/hotel/g293974-d100',
    ]) {
      expect(hotelIdFromLink(link), isNull);
    }
  });
  testWidgets('Gallery swipes, counts pages and labels inspiration images', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HotelGallery(hotel: hotelFixture(0))),
      ),
    );
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Hotel photo'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('Travel inspiration'), findsOneWidget);
    await tester.tap(find.byTooltip('Next photo'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
  });
  testWidgets('Wide gallery is bounded and opens a full screen viewer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HotelGallery(hotel: hotelFixture(0))),
      ),
    );
    expect(tester.getSize(find.byType(PageView)).width, lessThanOrEqualTo(820));
    await tester.tap(find.byTooltip('View photo full screen'));
    await tester.pumpAndSettle();
    expect(find.text('Test Stay 0'), findsOneWidget);
    await tester.tap(find.byTooltip('Next full screen photo'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
