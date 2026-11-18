import '../utils/stored_json.dart';

class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String description;
  final double price;
  final double rating;
  final String imageUrl;
  final List<int> sizes;
  final bool isNew;
  final List<String> photos;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.sizes,
    this.isNew = false,
    this.photos = const [],
    this.stock = 99,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final name = json['title'];
    final price = json['price'];
    final rating = json['rating'];
    final category = json['category'];
    if (rawId is! int ||
        rawId <= 0 ||
        name is! String ||
        name.trim().isEmpty ||
        price is! num ||
        !price.isFinite ||
        price < 0 ||
        rating is! num ||
        !rating.isFinite ||
        rating < 0 ||
        rating > 5 ||
        (category != 'mens-shoes' && category != 'womens-shoes')) {
      throw const FormatException('Invalid product information');
    }
    bool validImage(String url) {
      final uri = Uri.tryParse(url);
      return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    }

    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages
            .whereType<String>()
            .where(validImage)
            .toList(growable: false)
        : <String>[];
    final thumbnail = json['thumbnail'];
    final image = thumbnail is String && validImage(thumbnail)
        ? thumbnail
        : images.isEmpty
            ? ''
            : images.first;
    final rawStock = json['stock'];
    return Product(
      id: 'api_$rawId',
      name: name.trim(),
      brand: json['brand'] is String ? json['brand'] as String : '',
      category: category == 'mens-shoes' ? 'Men' : 'Women',
      description:
          json['description'] is String ? json['description'] as String : '',
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      imageUrl: image,
      photos: images.isEmpty && image.isNotEmpty ? [image] : images,
      sizes: category == 'mens-shoes'
          ? const [39, 40, 41, 42, 43, 44, 45]
          : const [36, 37, 38, 39, 40, 41],
      stock: rawStock is num && rawStock.isFinite
          ? rawStock.toInt().clamp(0, 99999).toInt()
          : 0,
    );
  }
  Map<String, dynamic> toSavedJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'category': category,
        'description': description,
        'price': price,
        'rating': rating,
        'imageUrl': imageUrl,
        'sizes': sizes,
        'isNew': isNew,
        'photos': photos,
        'stock': stock,
      };
  factory Product.fromSavedJson(Map<String, dynamic> json) {
    final sizes = json['sizes'];
    if (sizes is! List ||
        sizes.isEmpty ||
        sizes.any((v) => v is! int || v <= 0) ||
        json['isNew'] is! bool) {
      throw const FormatException('Invalid saved product');
    }
    return Product(
      id: StoredJson.text(json, 'id', required: true),
      name: StoredJson.text(json, 'name', required: true),
      brand: StoredJson.text(json, 'brand'),
      category: StoredJson.text(json, 'category'),
      description: StoredJson.text(json, 'description'),
      price: StoredJson.number(json, 'price'),
      rating: StoredJson.number(json, 'rating', maximum: 5),
      imageUrl: StoredJson.text(json, 'imageUrl'),
      sizes: sizes.cast<int>(),
      isNew: json['isNew'] as bool,
      photos: StoredJson.strings(json, 'photos'),
      stock: StoredJson.integer(json, 'stock'),
    );
  }
}
