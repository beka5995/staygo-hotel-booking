import 'dart:typed_data';

import 'package:flutter/material.dart';

Widget localPhotoPreview(String path, Uint8List bytes) =>
    Image.memory(bytes, fit: BoxFit.contain, semanticLabel: 'Selected photo');
