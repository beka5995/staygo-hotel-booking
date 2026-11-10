import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_item.dart';

class PreferencesStore extends ChangeNotifier {
  PreferencesStore._(
    this._preferences,
    this._darkMode,
    this._displayName,
    this._notes,
    this._error,
  );
  static const themeKey = 'app_theme_dark_mode';
  static const nameKey = 'user_display_name';
  static const notesKey = 'user_notes_json';
  final SharedPreferences _preferences;
  bool _darkMode;
  String _displayName;
  List<NoteItem> _notes;
  String? _error;
  bool _saving = false;
  bool _disposed = false;
  int _sequence = 0;
  Future<void> _pending = Future<void>.value();
  final Map<String, String> _snapshots = {};

  Future<void> get pendingWrites => _pending;

  bool get darkMode => _darkMode;
  String get displayName => _displayName;
  List<NoteItem> get notes => List.unmodifiable(_notes);
  bool get isSaving => _saving;
  String? get error => _error;

  // main() awaits this before runApp(), so the first frame has the saved theme.
  static Future<PreferencesStore> load() async {
    final preferences = await SharedPreferences.getInstance();
    final dark = preferences.getBool(themeKey) ?? false;
    final name = preferences.getString(nameKey) ?? 'Guest User';
    final raw = preferences.getString(notesKey);
    final notes = <NoteItem>[];
    String? error;
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) throw const FormatException('Invalid notes list');
        final ids = <String>{};
        for (final entry in decoded) {
          if (entry is! Map<String, dynamic>) {
            throw const FormatException('Invalid note');
          }
          final note = NoteItem.fromJson(entry);
          if (ids.add(note.id)) notes.add(note);
        }
      } on FormatException {
        notes.clear();
        error = 'Saved notes could not be read. You can create a new list.';
      }
    }
    return PreferencesStore._(
      preferences,
      dark,
      name.trim().isEmpty ? 'Guest User' : name,
      notes,
      error,
    );
  }

  // Writes are serialized; quick actions cannot overwrite a more recent list.
  // State is committed only after the storage plugin confirms a successful save.
  Future<bool> _enqueue(Future<void> Function() write) {
    final result = Completer<bool>();
    _pending = _pending.then((_) async {
      if (_disposed) {
        result.complete(false);
        return;
      }
      _saving = true;
      _error = null;
      notifyListeners();
      try {
        await write();
        result.complete(true);
      } catch (_) {
        _error = 'Could not save changes. Please try again.';
        result.complete(false);
      } finally {
        _saving = false;
        if (!_disposed) notifyListeners();
      }
    });
    return result.future;
  }

  Future<void> _saveNotes(List<NoteItem> next) async {
    final encoded = jsonEncode(next.map((note) => note.toJson()).toList());
    if (!await _preferences.setString(notesKey, encoded)) {
      throw StateError('Save failed');
    }
    _notes = next;
  }

  Future<bool> setDarkMode(bool value) => _enqueue(() async {
    if (!await _preferences.setBool(themeKey, value)) {
      throw StateError('Save failed');
    }
    _darkMode = value;
  });

  Future<bool> saveDisplayName(String value) => _enqueue(() async {
    final name = value.trim().isEmpty ? 'Guest User' : value.trim();
    if (!await _preferences.setString(nameKey, name)) {
      throw StateError('Save failed');
    }
    _displayName = name;
  });

  Future<bool> addNote(String title) {
    final text = title.trim();
    if (text.isEmpty) return Future<bool>.value(false);
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    final note = NoteItem(
      id: '${now.microsecondsSinceEpoch}_${_sequence++}',
      title: text,
      dateText:
          '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}',
    );
    return _enqueue(() => _saveNotes([note, ..._notes]));
  }

  Future<bool> toggleNote(String id) => _enqueue(
    () => _saveNotes([
      for (final note in _notes)
        if (note.id == id) note.toggle() else note,
    ]),
  );
  Future<bool> deleteNote(String id) => _enqueue(
    () => _saveNotes(_notes.where((note) => note.id != id).toList()),
  );

  // Saved user selections are independent from the live catalog feed.
  List<T> readItems<T>(String key, T Function(Map<String, dynamic>) decode) {
    final raw = _preferences.getString(key);
    if (raw == null) return [];
    final result = <T>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('Invalid saved list');
      for (final entry in decoded) {
        try {
          if (entry is! Map<String, dynamic>) {
            throw const FormatException('Invalid saved item');
          }
          result.add(decode(entry));
        } on FormatException {
          _error = 'Some saved selections could not be restored.';
        }
      }
      _snapshots[key] = raw;
    } on FormatException {
      _error = 'Saved selections could not be read.';
    }
    return result;
  }

  Future<bool> saveItems(String key, List<Map<String, dynamic>> items) {
    final encoded = jsonEncode(items);
    if (_snapshots[key] == encoded) return Future<bool>.value(true);
    _snapshots[key] = encoded;
    return _enqueue(() async {
      if (!await _preferences.setString(key, encoded)) {
        throw StateError('Save failed');
      }
    }).then((saved) {
      if (!saved && _snapshots[key] == encoded) _snapshots.remove(key);
      return saved;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
