// Local web gateway. No dependencies beyond the Dart SDK included with Flutter.
// Xotelo has no browser CORS headers. Android/iOS call Xotelo directly.
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8765 : int.parse(args.first);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  stdout.writeln('StayGo web gateway: http://127.0.0.1:$port/api');
  await for (final request in server) {
    handle(request, client);
  }
}

Future<void> handle(HttpRequest request, HttpClient client) async {
  final response = request.response;
  final origin = request.headers.value('origin');
  final parsedOrigin = origin == null ? null : Uri.tryParse(origin);
  final localOrigin =
      parsedOrigin != null &&
      parsedOrigin.scheme == 'http' &&
      (parsedOrigin.host == 'localhost' || parsedOrigin.host == '127.0.0.1');
  response.headers.set('Cache-Control', 'no-store, max-age=0');
  response.headers.set('Vary', 'Origin');
  if (localOrigin) {
    response.headers.set('Access-Control-Allow-Origin', origin!);
    response.headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    response.headers.set(
      'Access-Control-Allow-Headers',
      'Cache-Control, Pragma',
    );
  }
  if (origin != null && !localOrigin) {
    response.statusCode = HttpStatus.forbidden;
    await response.close();
    return;
  }
  if (request.method == 'OPTIONS') {
    response.statusCode = 204;
    await response.close();
    return;
  }
  if (request.method != 'GET' ||
      !{'/api/list', '/api/rates', '/api/image'}.contains(request.uri.path)) {
    response.statusCode = 404;
    await response.close();
    return;
  }
  response.headers.contentType = ContentType.json;
  try {
    // The upstream host is fixed: this is not an arbitrary URL proxy.
    const allowed = {
      'location_key',
      'offset',
      'limit',
      'sort',
      'hotel_key',
      'chk_in',
      'chk_out',
      'currency',
    };
    final query = Map<String, String>.fromEntries(
      request.uri.queryParameters.entries.where((e) => allowed.contains(e.key)),
    );
    final Uri url;
    if (request.uri.path == '/api/image') {
      final image = Uri.tryParse(request.uri.queryParameters['url'] ?? '');
      if (image == null ||
          image.scheme != 'https' ||
          image.host != 'dynamic-media-cdn.tripadvisor.com' ||
          image.userInfo.isNotEmpty ||
          image.port != 443) {
        response.statusCode = HttpStatus.badRequest;
        await response.close();
        return;
      }
      url = image;
    } else {
      url = Uri.https('data.xotelo.com', request.uri.path, query);
    }
    final upstreamRequest = await client
        .getUrl(url)
        .timeout(const Duration(seconds: 12));
    upstreamRequest.headers.set('Cache-Control', 'no-cache');
    final upstream = await upstreamRequest.close().timeout(
      const Duration(seconds: 12),
    );
    final body = await upstream
        .fold<List<int>>(<int>[], (buffer, bytes) => buffer..addAll(bytes))
        .timeout(const Duration(seconds: 12));
    response.statusCode = upstream.statusCode;
    if (request.uri.path == '/api/image') {
      response.headers.contentType =
          upstream.headers.contentType ?? ContentType('image', 'jpeg');
    }
    response.add(body);
  } catch (_) {
    response.statusCode = HttpStatus.badGateway;
    response.write(
      jsonEncode({
        'error': {'message': 'Cannot reach the hotel directory'},
        'result': null,
      }),
    );
  }
  try {
    await response.close();
  } catch (_) {
    /* Browser cancelled a timed out request. */
  }
}
