
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project_android_hotelbooking/data/sample_hotels.dart';
import 'package:final_project_android_hotelbooking/providers/cart_provider.dart';

void main() {
  test('Add hotels and calculate total', () {
    final cart = CartProvider();
    final first = sampleHotels[0];
    final second = sampleHotels[1];

    cart.toggleHotel(first);
    cart.toggleHotel(second);

    expect(cart.itemCount, 2);
    expect(cart.items.length, 2);
    expect(cart.containsHotel(first.id), true);
    expect(cart.containsHotel(second.id), true);

    expect(
      cart.totalPrice,
      first.pricePerNight + second.pricePerNight,
    );

    cart.dispose();
  });

  test('Change nights and update total', () {
    final cart = CartProvider();
    final hotel = sampleHotels[0];

    cart.toggleHotel(hotel);

    expect(cart.items.first.nights, 1);
    expect(cart.totalPrice, hotel.pricePerNight);

    cart.changeNights(hotel.id, 2);

    expect(cart.items.first.nights, 3);
    expect(cart.totalPrice, hotel.pricePerNight * 3);

    cart.changeNights(hotel.id, -1);

    expect(cart.items.first.nights, 2);
    expect(cart.totalPrice, hotel.pricePerNight * 2);

    cart.dispose();
  });

  test('Remove individual hotel', () {
    final cart = CartProvider();
    final first = sampleHotels[0];
    final second = sampleHotels[1];

    cart.toggleHotel(first);
    cart.toggleHotel(second);

    cart.removeHotel(first.id);

    expect(cart.itemCount, 1);
    expect(cart.containsHotel(first.id), false);
    expect(cart.containsHotel(second.id), true);
    expect(cart.totalPrice, second.pricePerNight);

    cart.dispose();
  });

  test('Toggle adds and removes hotel', () {
    final cart = CartProvider();
    final hotel = sampleHotels[0];

    cart.toggleHotel(hotel);

    expect(cart.containsHotel(hotel.id), true);

    cart.toggleHotel(hotel);

    expect(cart.containsHotel(hotel.id), false);
    expect(cart.itemCount, 0);

    cart.dispose();
  });

  test('Clear All removes every hotel', () {
    final cart = CartProvider();

    cart.toggleHotel(sampleHotels[0]);
    cart.toggleHotel(sampleHotels[1]);
    cart.toggleHotel(sampleHotels[2]);

    expect(cart.itemCount, 3);

    cart.clear();

    expect(cart.itemCount, 0);
    expect(cart.items, isEmpty);
    expect(cart.totalPrice, 0);

    cart.dispose();
  });

  test('Nights must stay between 1 and 30', () {
    final cart = CartProvider();
    final hotel = sampleHotels[0];

    cart.toggleHotel(hotel);

    cart.changeNights(hotel.id, -1);
    expect(cart.items.first.nights, 1);

    cart.changeNights(hotel.id, 29);
    expect(cart.items.first.nights, 30);

    cart.changeNights(hotel.id, 1);
    expect(cart.items.first.nights, 30);

    cart.dispose();
  });

  test('ChangeNotifier updates listeners', () {
    final cart = CartProvider();
    final hotel = sampleHotels[0];

    int updates = 0;

    cart.addListener(() {
      updates++;
    });

    cart.toggleHotel(hotel);
    expect(updates, 1);

    cart.changeNights(hotel.id, 1);
    expect(updates, 2);

    cart.removeHotel(hotel.id);
    expect(updates, 3);

    cart.toggleHotel(hotel);
    cart.clear();

    expect(updates, 5);
    expect(cart.itemCount, 0);

    cart.dispose();
  });
}
