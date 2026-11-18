import 'package:flutter_test/flutter_test.dart';

import 'fixtures/catalog.dart';

import 'package:final_project/state/cart_bloc.dart';

void main() {
  test(
    'cart totals and individual removal use the selected shoe size',
    () async {
      final cart = CartBloc();
      final shoe = sampleProducts.first;
      cart.add(AddProductEvent(shoe, size: 42));
      await Future<void>.delayed(Duration.zero);
      cart.add(AddProductEvent(shoe, size: 42));
      await Future<void>.delayed(Duration.zero);
      cart.add(AddProductEvent(shoe, size: 43));
      await Future<void>.delayed(Duration.zero);
      expect(cart.state.count, 3);
      expect(cart.state.items.length, 2);
      expect(cart.state.totalPrice, closeTo(shoe.price * 3, 0.000001));
      expect(cart.state.containsProduct(shoe.id), isTrue);

      final line = cart.state.items.first;
      cart.add(RemoveProductEvent(line.product.id, size: line.size));
      await Future<void>.delayed(Duration.zero);
      expect(cart.state.count, 1);
      expect(cart.state.totalPrice, shoe.price);
      cart.add(const ClearCartEvent());
      await Future<void>.delayed(Duration.zero);
      expect(cart.state.count, 0);
      expect(cart.state.totalPrice, 0);
      await cart.close();
    },
  );

  test('catalog toggle and cart removal update the same state', () async {
    final cart = CartBloc();
    final shoe = sampleProducts[1];
    var changes = 0;
    final subscription = cart.stream.listen((_) => changes++);

    cart.add(AddProductEvent(shoe));
    await Future<void>.delayed(Duration.zero);
    expect(cart.state.containsProduct(shoe.id), isTrue);
    expect(cart.state.count, 1);

    cart.add(RemoveProductEvent(shoe.id));
    await Future<void>.delayed(Duration.zero);
    expect(cart.state.containsProduct(shoe.id), isFalse);
    expect(cart.state.count, 0);
    expect(changes, 2);
    await subscription.cancel();
    await cart.close();
  });

  test('removing one size keeps the other size in the bag', () async {
    final cart = CartBloc();
    final shoe = sampleProducts.first;
    cart.add(AddProductEvent(shoe, size: 41));
    await Future<void>.delayed(Duration.zero);
    cart.add(AddProductEvent(shoe, size: 42));
    await Future<void>.delayed(Duration.zero);
    final line = cart.state.items.first;
    cart.add(RemoveProductEvent(line.product.id, size: line.size));
    await Future<void>.delayed(Duration.zero);
    expect(cart.state.containsProduct(shoe.id), isTrue);
    expect(cart.state.count, 1);
    await cart.close();
  });
}
