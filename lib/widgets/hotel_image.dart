import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HotelImage extends StatelessWidget {
  const HotelImage({super.key, required this.url, this.height, this.width});

  final String url;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholder();
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
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
