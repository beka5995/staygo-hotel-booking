import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project_android_hotelbooking/models/note_item.dart';
import 'package:final_project_android_hotelbooking/state/preferences_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('First launch has safe defaults', () async {
    final local = await PreferencesStore.load();
    addTearDown(local.dispose);
    expect(local.darkMode, isFalse);
    expect(local.displayName, 'Guest User');
    expect(local.notes, isEmpty);
  });

  test(
    'Note JSON round-trips completed state and rejects incorrect field types',
    () {
      const note = NoteItem(
        id: 'n1',
        title: 'Remember the details',
        dateText: '2026-11-10',
        isCompleted: true,
      );
      final decoded = NoteItem.fromJson(
        jsonDecode(jsonEncode(note.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.toJson(), note.toJson());
      expect(decoded.toggle().isCompleted, isFalse);
      expect(
        () => NoteItem.fromJson({...note.toJson(), 'isCompleted': 'true'}),
        throwsFormatException,
      );
    },
  );

  test('Theme and name use the required bool and String keys', () async {
    final local = await PreferencesStore.load();
    addTearDown(local.dispose);
    await local.setDarkMode(true);
    await local.saveDisplayName('  Бека  ');
    final disk = await SharedPreferences.getInstance();
    expect(disk.getBool('app_theme_dark_mode'), isTrue);
    expect(disk.getString('user_display_name'), 'Бека');
    await local.saveDisplayName('   ');
    expect(local.displayName, 'Guest User');
  });

  test(
    'Create prepends, checkbox updates JSON, delete updates persisted list',
    () async {
      final local = await PreferencesStore.load();
      addTearDown(local.dispose);
      await local.addNote('First');
      await local.addNote('Second');
      expect(local.notes.map((n) => n.title), ['Second', 'First']);
      expect(local.notes[0].id, isNot(local.notes[1].id));
      final id = local.notes.first.id;
      await local.toggleNote(id);
      final disk = await SharedPreferences.getInstance();
      final json =
          jsonDecode(disk.getString(PreferencesStore.notesKey)!) as List;
      expect((json.first as Map)['isCompleted'], isTrue);
      await local.deleteNote(id);
      final restored = await PreferencesStore.load();
      addTearDown(restored.dispose);
      expect(restored.notes.single.title, 'First');
    },
  );

  test(
    'Fresh preferences cache restores two notes, name and dark theme',
    () async {
      final local = await PreferencesStore.load();
      await local.addNote('First');
      await local.addNote('Second');
      await local.toggleNote(local.notes.first.id);
      await local.setDarkMode(true);
      await local.saveDisplayName('Traveler');
      final disk = await SharedPreferences.getInstance();
      final snapshot = {for (final key in disk.getKeys()) key: disk.get(key)!};
      local.dispose();
      // Simulates a new process cache reading the values written through the plugin.
      SharedPreferences.setMockInitialValues(snapshot);
      final restarted = await PreferencesStore.load();
      addTearDown(restarted.dispose);
      expect(restarted.darkMode, isTrue);
      expect(restarted.displayName, 'Traveler');
      expect(restarted.notes.map((n) => n.title), ['Second', 'First']);
      expect(restarted.notes.first.isCompleted, isTrue);
    },
  );

  test(
    'Queued actions preserve every note and the most recent theme/name',
    () async {
      final local = await PreferencesStore.load();
      addTearDown(local.dispose);
      await Future.wait([
        local.addNote('One'),
        local.addNote('Two'),
        local.setDarkMode(true),
        local.saveDisplayName('First name'),
        local.saveDisplayName('Latest name'),
        local.setDarkMode(false),
      ]);
      final restarted = await PreferencesStore.load();
      addTearDown(restarted.dispose);
      expect(restarted.notes, hasLength(2));
      expect(restarted.displayName, 'Latest name');
      expect(restarted.darkMode, isFalse);
    },
  );

  test(
    'Malformed saved notes do not crash startup or silently rewrite storage',
    () async {
      SharedPreferences.setMockInitialValues({
        PreferencesStore.notesKey: '{invalid',
      });
      final local = await PreferencesStore.load();
      addTearDown(local.dispose);
      expect(local.notes, isEmpty);
      expect(local.error, isNotNull);
      expect(
        (await SharedPreferences.getInstance()).getString(
          PreferencesStore.notesKey,
        ),
        '{invalid',
      );
    },
  );
}
