import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

Widget localPhotoPreview(String path, Uint8List bytes) => Image.file(
  File(path),
  fit: BoxFit.contain,
  semanticLabel: 'Selected photo',
  errorBuilder: (_, _, _) => Image.memory(bytes, fit: BoxFit.contain),
);
