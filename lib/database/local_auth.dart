
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/user_profile.dart';

class LocalAuth {
  LocalAuth._();

  static final instance = LocalAuth._();

  Future<Database>? _databaseFuture;

  Future<Database> get database {
    return _databaseFuture ??= _open();
  }

  Future<Database> _open() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

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
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE active_session (
            slot INTEGER PRIMARY KEY,
            user_id INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  UserProfile _toProfile(Map<String, Object?> row) {
    return UserProfile(
      fullName: row['name'] as String,
      email: row['email'] as String,
      role: row['role'] as String,
    );
  }

  Future<void> _saveSession(int id) async {
    final db = await database;

    await db.insert(
      'active_session',
      {'slot': 1, 'user_id': id},
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
    final normalizedEmail = email.trim().toLowerCase();

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw StateError('This email is already registered');
    }

    final passwordHash = BCrypt.hashpw(
      password,
      BCrypt.gensalt(),
    );

    final id = await db.insert('users', {
      'name': name.trim(),
      'email': normalizedEmail,
      'password_hash': passwordHash,
      'role': role,
    });

    await _saveSession(id);

    return UserProfile(
      fullName: name.trim(),
      email: normalizedEmail,
      role: role,
    );
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final db = await database;

    final users = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (users.isEmpty) {
      throw StateError('Incorrect email or password');
    }

    final user = users.first;
    final hash = user['password_hash'] as String;

    if (!BCrypt.checkpw(password, hash)) {
      throw StateError('Incorrect email or password');
    }

    await _saveSession(user['id'] as int);

    return _toProfile(user);
  }

  Future<UserProfile?> currentProfile() async {
    final db = await database;

    final users = await db.rawQuery('''
      SELECT users.name, users.email, users.role
      FROM users
      INNER JOIN active_session
      ON users.id = active_session.user_id
      WHERE active_session.slot = 1
      LIMIT 1
    ''');

    if (users.isEmpty) return null;

    return _toProfile(users.first);
  }

  Future<void> logout() async {
    final db = await database;
    await db.delete('active_session');
  }
}
