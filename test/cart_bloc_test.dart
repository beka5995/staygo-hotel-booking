import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

import 'package:final_project_android_hotelbooking/state/cart_bloc.dart';

void main() {
  test('Add hotels and calculate total', () async {
    final cart = CartBloc();
    final first = fixtureHotels[0];
    final second = fixtureHotels[1];

    cart.add(AddProductEvent(first));
    await Future<void>.delayed(Duration.zero);
    cart.add(AddProductEvent(second));
    await Future<void>.delayed(Duration.zero);

    expect(cart.state.count, 2);
    expect(cart.state.items.length, 2);
    expect(cart.state.containsHotel(first.id), true);
    expect(cart.state.containsHotel(second.id), true);

    expect(cart.state.totalPrice, first.pricePerNight + second.pricePerNight);

    await cart.close();
  });

  test('Change nights and update total', () async {
    final cart = CartBloc();
    final hotel = fixtureHotels[0];

    cart.add(AddProductEvent(hotel));
    await Future<void>.delayed(Duration.zero);

    expect(cart.state.items.first.nights, 1);
    expect(cart.state.totalPrice, hotel.pricePerNight);

    cart.add(ChangeNightsEvent(hotel.id, 2));
    await Future<void>.delayed(Duration.zero);

    expect(cart.state.items.first.nights, 3);
    expect(cart.state.totalPrice, hotel.pricePerNight * 3);

    cart.add(ChangeNightsEvent(hotel.id, -1));
    await Future<void>.delayed(Duration.zero);

    expect(cart.state.items.first.nights, 2);
    expect(cart.state.totalPrice, hotel.pricePerNight * 2);

    await cart.close();
  });

  test('Remove individual hotel', () async {
    final cart = CartBloc();
    final first = fixtureHotels[0];
    final second = fixtureHotels[1];

    cart.add(AddProductEvent(first));
    await Future<void>.delayed(Duration.zero);
    cart.add(AddProductEvent(second));
    await Future<void>.delayed(Duration.zero);

    cart.add(RemoveProductEvent(first.id));
    await Future<void>.delayed(Duration.zero);

    expect(cart.state.count, 1);
    expect(cart.state.containsHotel(first.id), false);
    expect(cart.state.containsHotel(second.id), true);
    expect(cart.state.totalPrice, second.pricePerNight);

    await cart.close();
  });

  test(
    'Duplicate add keeps one hotel, and remove clears the selection',
    () async {
      final cart = CartBloc();
      final hotel = fixtureHotels[0];

      cart.add(AddProductEvent(hotel));
      await Future<void>.delayed(Duration.zero);

      expect(cart.state.containsHotel(hotel.id), true);

      cart.add(AddProductEvent(hotel));
      await Future<void>.delayed(Duration.zero);
      expect(cart.state.count, 1);
      cart.add(RemoveProductEvent(hotel.id));
      await Future<void>.delayed(Duration.zero);

      expect(cart.state.containsHotel(hotel.id), false);
      expect(cart.state.count, 0);

      await cart.close();
    },
  );

  test('Clear All removes every hotel', () async {
    final cart = CartBloc();

    cart.add(AddProductEvent(fixtureHotels[0]));
    await Future<void>.delayed(Duration.zero);
    cart.add(AddProductEvent(fixtureHotels[1]));
    await Future<void>.delayed(Duration.zero);
    cart.add(AddProductEvent(fixtureHotels[2]));
    await Future<void>.delayed(Duration.zero);

    expect(cart.state.count, 3);

    cart.add(const ClearCartEvent());
    await Future<void>.delayed(Duration.zero);

    expect(cart.state.count, 0);
    expect(cart.state.items, isEmpty);
    expect(cart.state.totalPrice, 0);

    await cart.close();
  });

  test('Nights must stay between 1 and 30', () async {
    final cart = CartBloc();
    final hotel = fixtureHotels[0];

    cart.add(AddProductEvent(hotel));
    await Future<void>.delayed(Duration.zero);

    cart.add(ChangeNightsEvent(hotel.id, -1));
    await Future<void>.delayed(Duration.zero);
    expect(cart.state.items.first.nights, 1);

    cart.add(ChangeNightsEvent(hotel.id, 29));
    await Future<void>.delayed(Duration.zero);
    expect(cart.state.items.first.nights, 30);

    cart.add(ChangeNightsEvent(hotel.id, 1));
    await Future<void>.delayed(Duration.zero);
    expect(cart.state.items.first.nights, 30);

    await cart.close();
  });

  test('BLoC emits each changed cart state', () async {
    final cart = CartBloc();
    final hotel = fixtureHotels[0];

    int updates = 0;

    final subscription = cart.stream.listen((_) {
      updates++;
    });

    cart.add(AddProductEvent(hotel));
    await Future<void>.delayed(Duration.zero);
    expect(updates, 1);

    cart.add(ChangeNightsEvent(hotel.id, 1));
    await Future<void>.delayed(Duration.zero);
    expect(updates, 2);

    cart.add(RemoveProductEvent(hotel.id));
    await Future<void>.delayed(Duration.zero);
    expect(updates, 3);

    cart.add(AddProductEvent(hotel));
    await Future<void>.delayed(Duration.zero);
    cart.add(const ClearCartEvent());
    await Future<void>.delayed(Duration.zero);

    expect(updates, 5);
    await subscription.cancel();
    expect(cart.state.count, 0);

    await cart.close();
  });
  test('Unknown rates are excluded, refreshed rates preserve nights', () async {
    final cart = CartBloc();
    final hotel = hotelFixture(0, price: 0);
    cart.add(AddProductEvent(hotel));
    await Future<void>.delayed(Duration.zero);
    cart.add(ChangeNightsEvent(hotel.id, 2));
    await Future<void>.delayed(Duration.zero);
    expect(cart.state.unpricedCount, 1);
    expect(cart.state.totalPrice, 0);
    cart.add(
      UpdateHotelsEvent({hotel.id: hotel.copyWith(pricePerNight: 97.5)}),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cart.state.items.first.nights, 3);
    expect(cart.state.totalPrice, 292.5);
    expect(cart.state.unpricedCount, 0);
    await cart.close();
  });
}
