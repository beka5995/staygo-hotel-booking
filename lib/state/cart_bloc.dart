import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

sealed class CartEvent {
  const CartEvent();
}

final class AddProductEvent extends CartEvent {
  const AddProductEvent(this.product, {this.size});
  final Product product;
  final int? size;
}

final class RemoveProductEvent extends CartEvent {
  const RemoveProductEvent(this.productId, {this.size});
  final String productId;
  final int? size;
}

final class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}

final class ChangeQuantityEvent extends CartEvent {
  const ChangeQuantityEvent(this.item, this.difference);
  final CartItem item;
  final int difference;
}

final class UpdateProductsEvent extends CartEvent {
  UpdateProductsEvent(Map<String, Product> products)
      : products = Map.unmodifiable(products);
  final Map<String, Product> products;
}

final class CartState extends Equatable {
  CartState(Iterable<CartItem> items) : items = List.unmodifiable(items);
  final List<CartItem> items;

  int get count => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);
  bool containsProduct(String id) => items.any((item) => item.product.id == id);

  @override
  List<Object?> get props => [items];
}

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({List<CartItem> initialItems = const []})
      : super(CartState({
          for (final item in initialItems) (item.product.id, item.size): item
        }.values)) {
    on<AddProductEvent>((event, emit) {
      final size = event.size ??
          (event.product.sizes.contains(42) ? 42 : event.product.sizes.first);
      final index = state.items.indexWhere(
        (item) => item.product.id == event.product.id && item.size == size,
      );
      final items = [...state.items];
      final cartItem = CartItem(
        product: event.product,
        size: size,
        quantity: index < 0 ? 1 : items[index].quantity + 1,
      );
      if (index < 0) {
        items.add(cartItem);
      } else {
        items[index] = cartItem;
      }
      emit(CartState(items));
    });
    on<RemoveProductEvent>((event, emit) {
      emit(
        CartState(
          state.items.where(
            (item) =>
                item.product.id != event.productId ||
                (event.size != null && item.size != event.size),
          ),
        ),
      );
    });
    on<ClearCartEvent>((event, emit) => emit(CartState(const [])));
    on<ChangeQuantityEvent>((event, emit) {
      final index = state.items.indexWhere(
        (item) =>
            item.product.id == event.item.product.id &&
            item.size == event.item.size,
      );
      if (index < 0 || event.difference == 0) return;
      final items = [...state.items];
      final next = items[index].quantity + event.difference;
      if (next <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].withQuantity(next);
      }
      emit(CartState(items));
    });
    on<UpdateProductsEvent>((event, emit) {
      emit(
        CartState(
          state.items.map((item) {
            final updated = event.products[item.product.id];
            if (updated == null || identical(updated, item.product)) {
              return item;
            }
            return CartItem(
              product: updated,
              size: item.size,
              quantity: item.quantity,
            );
          }),
        ),
      );
    });
  }
}
