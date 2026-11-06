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
  });

  final String id;
  final String name;
  final String city;
  final int pricePerNight;
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

  bool get hasPrice => pricePerNight > 0;
  bool get hasRating => rating > 0 && reviewCount > 0;
  bool get isLocalListing => sourceUrl == null;
  List<String> get gallery => assetPhotos.isNotEmpty
      ? assetPhotos
      : (photos.isNotEmpty
          ? photos
          : (imageUrl.isEmpty ? const [] : [imageUrl]));

  Hotel copyWith({String? id, String? name}) {
    return Hotel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city,
      pricePerNight: pricePerNight,
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
    );
  }
}
