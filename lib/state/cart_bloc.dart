import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/trip_item.dart';
import '../models/hotel.dart';

sealed class CartEvent {
  const CartEvent();
}

final class AddProductEvent extends CartEvent {
  const AddProductEvent(this.product);
  final Hotel product;
}

final class RemoveProductEvent extends CartEvent {
  const RemoveProductEvent(this.productId);
  final String productId;
}

final class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}

final class ChangeNightsEvent extends CartEvent {
  const ChangeNightsEvent(this.productId, this.difference);
  final String productId;
  final int difference;
}

final class UpdateHotelsEvent extends CartEvent {
  UpdateHotelsEvent(Map<String, Hotel> products)
    : products = Map.unmodifiable(products);
  final Map<String, Hotel> products;
}

final class CartState extends Equatable {
  CartState(Iterable<TripItem> items) : items = List.unmodifiable(items);
  final List<TripItem> items;

  int get count => items.length;
  int get unpricedCount => items.where((item) => !item.hotel.hasPrice).length;
  double get totalPrice => items.fold(
    0.0,
    (sum, item) => sum + item.hotel.pricePerNight * item.nights,
  );
  bool containsHotel(String id) => items.any((item) => item.hotel.id == id);

  @override
  List<Object?> get props => [items];
}

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({List<TripItem> initialItems = const []})
    : super(CartState({for (final item in initialItems) item.hotel.id: item}.values)) {
    on<AddProductEvent>((event, emit) {
      if (state.containsHotel(event.product.id)) return;
      emit(CartState([...state.items, TripItem(hotel: event.product)]));
    });
    on<RemoveProductEvent>((event, emit) {
      emit(
        CartState(
          state.items.where((item) => item.hotel.id != event.productId),
        ),
      );
    });
    on<ClearCartEvent>((event, emit) => emit(CartState([])));
    on<ChangeNightsEvent>((event, emit) {
      final index = state.items.indexWhere(
        (item) => item.hotel.id == event.productId,
      );
      if (index < 0 || event.difference == 0) return;
      final items = [...state.items];
      final next = items[index].nights + event.difference;
      if (next < 1 || next > 30) return;
      items[index] = items[index].withNights(next);
      emit(CartState(items));
    });
    on<UpdateHotelsEvent>((event, emit) {
      emit(
        CartState(
          state.items.map((item) {
            final updated = event.products[item.hotel.id];
            if (updated == null || identical(updated, item.hotel)) return item;
            return TripItem(hotel: updated, nights: item.nights);
          }),
        ),
      );
    });
  }
}
