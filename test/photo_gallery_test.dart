import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_project/widgets/photo_gallery.dart';

void main() {
  testWidgets('sneaker carousel changes 1/3 to 2/3 and 3/3', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: PhotoGallery(
                photos: [
                  'assets/sneakers/nike_air_max/nike_air_max_1.jpg',
                  'assets/sneakers/nike_air_max/nike_air_max_2.jpg',
                  'assets/sneakers/nike_air_max/nike_air_max_3.jpg',
                ],
                heroTag: 'sneaker_image_p01',
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Next photo'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Next photo'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
  });
}
