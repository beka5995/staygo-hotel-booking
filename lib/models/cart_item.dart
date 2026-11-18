import 'package:equatable/equatable.dart';

import '../utils/stored_json.dart';
import 'product.dart';

class CartItem extends Equatable {
  final Product product;
  final int size;
  final int quantity;

  const CartItem({
    required this.product,
    required this.size,
    required this.quantity,
  });

  CartItem withQuantity(int newQuantity) {
    return CartItem(product: product, size: size, quantity: newQuantity);
  }

  @override
  List<Object?> get props => [product, size, quantity];

  Map<String, dynamic> toSavedJson() => {
    'product': product.toSavedJson(),
    'size': size,
    'quantity': quantity,
  };
  factory CartItem.fromSavedJson(Map<String, dynamic> json) {
    final product = Product.fromSavedJson(StoredJson.object(json, 'product'));
    final size = StoredJson.integer(json, 'size', minimum: 1);
    if (!product.sizes.contains(size)) {
      throw const FormatException('Invalid saved size');
    }
    return CartItem(
      product: product,
      size: size,
      quantity: StoredJson.integer(json, 'quantity', minimum: 1),
    );
  }
}
