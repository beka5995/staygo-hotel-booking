import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HotelImage extends StatelessWidget {
  const HotelImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fallbackAsset,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? height;
  final double? width;
  final String? fallbackAsset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _fallback();
      },
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    if (fallbackAsset != null) {
      return Image.asset(
        fallbackAsset!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFBFDAD9), Color(0xFFDFECE9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.hotel_rounded, size: 54, color: AppTheme.teal),
      ),
    );
  }
}
