import 'dart:typed_data';

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.photo,
    required this.caption,
    required this.takenAt,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
  });

  factory JournalEntry.fromRow(Map<String, Object?> row) => JournalEntry(
    id: row['id'] as int,
    photo: row['photo'] as Uint8List,
    caption: row['caption'] as String,
    takenAt: DateTime.fromMillisecondsSinceEpoch(row['taken_at'] as int),
    latitude: (row['latitude'] as num).toDouble(),
    longitude: (row['longitude'] as num).toDouble(),
    altitude: (row['altitude'] as num).toDouble(),
    accuracy: (row['accuracy'] as num).toDouble(),
  );

  final int id;
  final Uint8List photo;
  final String caption;
  final DateTime takenAt;
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;

  String get coordinates =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}
