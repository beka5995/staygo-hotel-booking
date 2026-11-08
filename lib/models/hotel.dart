class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    required this.city,
    required this.pricePerNight,
    required this.rating,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.amenities,
    this.reviewCount = 0,
    this.photos = const [],
    this.assetPhotos = const [],
    this.address,
    this.sourceUrl,
    this.rateDate,
  });

  final String id;
  final String name;
  final String city;
  final double pricePerNight;
  final double rating;
  final String imageUrl;
  final String description;
  final String category;
  final List<String> amenities;
  final int reviewCount;
  final List<String> photos;
  final List<String> assetPhotos;
  final String? address;
  final String? sourceUrl;
  final DateTime? rateDate;

  bool get hasPrice => pricePerNight > 0;
  bool get hasRating => rating > 0;
  String get priceLabel =>
      hasPrice ? '\$${pricePerNight.toStringAsFixed(2)}' : 'Price on request';
  List<String> get gallery => [
    ...photos,
    if (photos.isEmpty && imageUrl.isNotEmpty) imageUrl,
    ...assetPhotos,
  ];
  bool isInspirationPhoto(int index) =>
      index >= (photos.isEmpty && imageUrl.isNotEmpty ? 1 : photos.length);

  factory Hotel.fromJson(
    Map<String, dynamic> json, {
    required String city,
    List<String> inspirationPhotos = const [],
  }) {
    final id = json['key'];
    final name = json['name'];
    if (id is! String ||
        !RegExp(r'^g[0-9]+-d[0-9]+$').hasMatch(id) ||
        name is! String ||
        name.trim().isEmpty) {
      throw const FormatException('Invalid hotel information');
    }
    final reviews = json['review_summary'];
    final reviewMap = reviews is Map<String, dynamic>
        ? reviews
        : <String, dynamic>{};
    final rating = reviewMap['rating'];
    final count = reviewMap['count'];
    final image = json['image'];
    final uri = image is String ? Uri.tryParse(image) : null;
    final imageUrl = uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? image as String
        : '';
    final labels = json['merchandising_labels'];
    final mentions = json['mentions'];
    final amenities = labels is List
        ? labels.whereType<String>().take(6).toList()
        : <String>[];
    final characteristics = mentions is List
        ? mentions.whereType<String>().take(4).join(', ')
        : '';
    return Hotel(
      id: id,
      name: name.trim(),
      city: city,
      pricePerNight: 0.0,
      rating: rating is num && rating.isFinite && rating >= 0 && rating <= 5
          ? rating.toDouble()
          : 0.0,
      reviewCount: count is num && count.isFinite
          ? count.toInt().clamp(0, 10000000).toInt()
          : 0,
      imageUrl: imageUrl,
      photos: imageUrl.isEmpty ? const [] : [imageUrl],
      assetPhotos: inspirationPhotos,
      description: characteristics.isEmpty
          ? 'Explore ${name.trim()} in $city and plan your next stay.'
          : 'Explore ${name.trim()} in $city. $characteristics.',
      category: json['accommodation_type'] is String
          ? json['accommodation_type'] as String
          : 'Hotel',
      amenities: amenities,
      sourceUrl: json['url'] is String ? json['url'] as String : null,
    );
  }

  Hotel copyWith({
    String? id,
    String? name,
    double? pricePerNight,
    DateTime? rateDate,
  }) => Hotel(
    id: id ?? this.id,
    name: name ?? this.name,
    city: city,
    pricePerNight: pricePerNight ?? this.pricePerNight,
    rating: rating,
    imageUrl: imageUrl,
    description: description,
    category: category,
    amenities: amenities,
    reviewCount: reviewCount,
    photos: photos,
    assetPhotos: assetPhotos,
    address: address,
    sourceUrl: sourceUrl,
    rateDate: rateDate ?? this.rateDate,
  );
}
