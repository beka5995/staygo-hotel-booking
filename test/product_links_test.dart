import 'package:flutter_test/flutter_test.dart';
import 'package:final_project/services/product_links.dart';

void main() {
  test('native and web routes refer to the same product', () {
    for (final value in [
      'narxoz://store/product/api_88',
      'sneakshop://product/api_88',
      '/product/api_88',
    ]) {
      expect(ProductLink.parse(Uri.parse(value))?.sneakerId, 'api_88');
    }
    expect(ProductLink.forSneaker('api_88'), 'narxoz://store/product/api_88');
    for (final value in [
      'narxoz://store/product/a%2Fb',
      'https://example.com/api_88',
      'narxoz://store/product/api_88?bad=1',
      '/product/api_0',
    ]) {
      expect(ProductLink.parse(Uri.parse(value)), isNull);
    }
  });
}
