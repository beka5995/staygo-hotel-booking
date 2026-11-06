import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/hotel.dart';

String hotelShareLink(Hotel hotel) =>
    hotel.sourceUrl ?? 'staygo://hotel/${Uri.encodeComponent(hotel.id)}';

String? hotelIdFromLink(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (uri.scheme == 'staygo' && uri.host == 'hotel' && uri.pathSegments.length == 1) {
    final id = uri.pathSegments.first;
    return id.isEmpty ? null : id;
  }
  if (uri.scheme.isEmpty && uri.pathSegments.length == 2 &&
      uri.pathSegments.first == 'hotel') {
    return uri.pathSegments[1];
  }
  return null;
}

Future<void> showHotelShareSheet(BuildContext context, Hotel hotel) {
  final link = hotelShareLink(hotel);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this stay',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(hotel.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SelectableText(link),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(content: Text('Link copied')),
                  );
                  Navigator.of(sheetContext).pop();
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy link'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
