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
    this.reviewCount = 120,
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
    );
  }
}
