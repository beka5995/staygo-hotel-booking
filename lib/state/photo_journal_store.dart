import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../database/journal_database.dart';
import '../models/journal_entry.dart';

class PhotoJournalStore extends ChangeNotifier {
  final _database = const JournalDatabase();
  final List<JournalEntry> _entries = [];
  bool loaded = false;
  bool _disposed = false;
  Future<void>? _loading;
  String? error;

  List<JournalEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() {
    if (loaded) return Future.value();
    return _loading ??= _read();
  }

  Future<void> _read() async {
    try {
      _entries
        ..clear()
        ..addAll(await _database.read());
      loaded = true;
      error = null;
    } catch (_) {
      error = 'Could not open the photo journal.';
    } finally {
      _loading = null;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> save({
    required Uint8List photo,
    required String caption,
    required DateTime takenAt,
    required Position location,
  }) async {
    await load();
    if (!loaded) throw StateError('Journal could not be loaded');
    final entry = await _database.save(
      photo: photo,
      caption: caption,
      takenAt: takenAt,
      location: location,
    );
    _entries.insert(0, entry);
    if (!_disposed) notifyListeners();
  }

  Future<void> delete(int id) async {
    await _database.delete(id);
    _entries.removeWhere((entry) => entry.id == id);
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
