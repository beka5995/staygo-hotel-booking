import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_profile.dart';

class LocalAuth {
  LocalAuth._();
  static final instance = LocalAuth._();

  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final dbPath = kIsWeb
        ? 'staygo.db'
        : join(await getDatabasesPath(), 'staygo.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE session (
            slot INTEGER PRIMARY KEY,
            user_id INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  UserProfile _profile(Map<String, Object?> row) => UserProfile(
        fullName: row['full_name'] as String,
        email: row['email'] as String,
        role: row['role'] as String,
      );

  Future<void> _saveSession(int userId) async {
    final db = await database;
    await db.insert(
      'session',
      {'slot': 1, 'user_id': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final db = await database;
    final normalized = email.trim().toLowerCase();
    final existing = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw StateError('This email is already registered');
    }

    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    final id = await db.insert('users', {
      'full_name': name.trim(),
      'email': normalized,
      'password_hash': hash,
      'role': role,
    });
    await _saveSession(id);

    return UserProfile(
      fullName: name.trim(),
      email: normalized,
      role: role,
    );
  }

  Future<UserProfile> login(String email, String password) async {
    final db = await database;
    final matches = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (matches.isEmpty) {
      throw StateError('Incorrect email or password');
    }

    final user = matches.first;
    if (!BCrypt.checkpw(password, user['password_hash'] as String)) {
      throw StateError('Incorrect email or password');
    }

    await _saveSession(user['id'] as int);
    return _profile(user);
  }

  Future<UserProfile?> currentUser() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT users.full_name, users.email, users.role
      FROM users
      JOIN session ON session.user_id = users.id
      WHERE session.slot = 1
      LIMIT 1
    ''');
    return result.isEmpty ? null : _profile(result.first);
  }

  Future<void> logout() async {
    final db = await database;
    await db.delete('session');
  }
}
