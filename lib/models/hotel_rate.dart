class HotelRate {
  const HotelRate({required this.price});
  final double price;
  factory HotelRate.fromJson(Map<String, dynamic> json) {
    final value = json['rate'];
    if (value is! num || !value.isFinite || value <= 0) {
      throw const FormatException('Invalid nightly rate');
    }
    return HotelRate(price: (json['rate'] as num).toDouble());
  }
}
