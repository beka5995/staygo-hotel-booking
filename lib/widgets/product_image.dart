import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (url.startsWith('assets/')) {
      image = Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      image = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                width: width,
                height: height,
                alignment: Alignment.center,
                color: const Color(0xFFF2F2F0),
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
      );
    }
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: ColoredBox(color: const Color(0xFFF4F4F3), child: image),
    );
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: const Color(0xFFF0F0F0),
        alignment: Alignment.center,
        child:
            const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      );
}
