import 'package:flutter/foundation.dart';

const hotelApiBase = String.fromEnvironment(
  'STAYGO_API_URL',
  defaultValue: kIsWeb
      ? 'http://127.0.0.1:8765/api'
      : 'https://data.xotelo.com/api',
);

String hotelImageUrl(String url) {
  if (!kIsWeb || url.startsWith('assets/') || url.isEmpty) return url;
  final base = Uri.parse(hotelApiBase);
  return base
      .replace(
        path: '${base.path.replaceFirst(RegExp(r'/$'), '')}/image',
        queryParameters: {'url': url},
      )
      .toString();
}
