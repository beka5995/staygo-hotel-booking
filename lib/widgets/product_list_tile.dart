import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/price.dart';
import 'product_image.dart';

class ProductListTile extends StatelessWidget {
  final Product product;
  final bool favorite;
  final bool inCart;
  final VoidCallback? onCartToggle;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const ProductListTile({
    super.key,
    required this.product,
    required this.favorite,
    this.inCart = false,
    this.onCartToggle,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Hero(
                tag: 'sneaker_image_${product.id}',
                child: ProductImage(
                  url: product.imageUrl,
                  width: 82,
                  height: 86,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF2AA40),
                          size: 15,
                        ),
                        Text(
                          '${product.rating}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: onFavorite,
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      size: 21,
                      color: favorite ? const Color(0xFFE25448) : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    formatPrice(product.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  if (onCartToggle != null) ...[
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 29,
                      width: 96,
                      child: OutlinedButton(
                        onPressed: onCartToggle,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: inCart
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : null,
                        ),
                        child: Text(
                          inCart ? 'Remove' : 'Add to Cart',
                          maxLines: 1,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
