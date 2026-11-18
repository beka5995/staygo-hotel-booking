import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/price.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool favorite;
  final bool inCart;
  final VoidCallback? onCartToggle;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const ProductCard({
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
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'sneaker_image_${product.id}',
                    child: ProductImage(
                      url: product.imageUrl,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  if (product.isNew)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Color(0xFF242424),
                          borderRadius: BorderRadius.all(Radius.circular(7)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          child: Text(
                            'NEW',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 3,
                    top: 3,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xE6FFFFFF),
                      ),
                      iconSize: 20,
                      onPressed: onFavorite,
                      icon: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                        color:
                            favorite ? const Color(0xFFE25448) : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
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
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF2AA40),
                        size: 14,
                      ),
                      Text(
                        ' ${product.rating}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          formatPrice(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onCartToggle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 7),
                child: SizedBox(
                  height: 29,
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
                      inCart ? 'Remove from bag' : 'Add to Cart',
                      maxLines: 1,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
