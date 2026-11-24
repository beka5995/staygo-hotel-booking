import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/journal_entry.dart';

class JournalDatabase {
  const JournalDatabase();

  Future<Database> open() async {
    const file = 'staygo_journal.db';
    final path = kIsWeb ? file : join(await getDatabasesPath(), file);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE journal_entries (
          id INTEGER PRIMARY KEY,
          photo BLOB NOT NULL,
          caption TEXT NOT NULL,
          taken_at INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          altitude REAL NOT NULL,
          accuracy REAL NOT NULL
        )
      '''),
    );
  }

  Future<List<JournalEntry>> read() async {
    final db = await open();
    final rows = await db.query('journal_entries', orderBy: 'id DESC');
    return rows.map(JournalEntry.fromRow).toList();
  }

  Future<JournalEntry> save({
    required Uint8List photo,
    required String caption,
    required DateTime takenAt,
    required Position location,
  }) async {
    final db = await open();
    final values = {
      'photo': photo,
      'caption': caption,
      'taken_at': takenAt.millisecondsSinceEpoch,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'altitude': location.altitude,
      'accuracy': location.accuracy,
    };
    final id = await db.insert('journal_entries', values);
    return JournalEntry.fromRow({...values, 'id': id});
  }

  Future<void> delete(int id) async {
    final db = await open();
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }
}
