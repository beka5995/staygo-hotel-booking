import 'dart:typed_data';

import 'package:image/image.dart' as image;

Uint8List optimizeJournalPhoto(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported photo format');
  final oriented = image.bakeOrientation(decoded);
  final resized = oriented.width > 1080
      ? image.copyResize(oriented, width: 1080)
      : oriented;
  // Keep the captured location in the journal entry, independently of EXIF.
  resized.exif = image.ExifData();
  return image.encodeJpg(resized, quality: 80);
}
