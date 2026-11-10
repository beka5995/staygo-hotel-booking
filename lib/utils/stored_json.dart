// Strict readers for our own saved snapshots; API parsing stays in fromJson().
class StoredJson {
  static String text(
    Map<String, dynamic> json,
    String key, {
    bool required = false,
  }) {
    final value = json[key];
    if (value is! String || (required && value.trim().isEmpty)) {
      throw FormatException('Invalid $key');
    }
    return value;
  }

  static double number(
    Map<String, dynamic> json,
    String key, {
    double maximum = double.infinity,
  }) {
    final value = json[key];
    if (value is! num || !value.isFinite || value < 0 || value > maximum) {
      throw FormatException('Invalid $key');
    }
    return value.toDouble();
  }

  static int integer(
    Map<String, dynamic> json,
    String key, {
    int minimum = 0,
    int maximum = 10000000,
  }) {
    final value = number(json, key, maximum: maximum.toDouble());
    if (value != value.truncateToDouble() || value < minimum) {
      throw FormatException('Invalid $key');
    }
    return value.toInt();
  }

  static List<String> strings(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List || value.any((e) => e is! String)) {
      throw FormatException('Invalid $key');
    }
    return value.cast<String>();
  }

  static Map<String, dynamic> object(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! Map<String, dynamic>) throw FormatException('Invalid $key');
    return value;
  }
}
