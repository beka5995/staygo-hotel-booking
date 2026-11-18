import 'package:flutter/foundation.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/account.dart';

class LocalAuth {
  LocalAuth._();

  static final instance = LocalAuth._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final path = kIsWeb
        ? 'sneakshop.db'
        : join(await getDatabasesPath(), 'sneakshop.db');

    _db = await openDatabase(
      path,
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

    return _db!;
  }

  Account _account(Map<String, Object?> row) {
    return Account(
      fullName: row['name'] as String,
      email: row['email'] as String,
      role: row['role'] as String,
    );
  }

  Future<void> _saveSession(int userId) async {
    final db = await database;

    await db.insert(
        'active_session',
        {
          'slot': 1,
          'user_id': userId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Account> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final db = await database;
    email = email.trim().toLowerCase();

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existing.isNotEmpty) {
      throw StateError('This email is already registered');
    }

    final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

    final id = await db.insert('users', {
      'name': name.trim(),
      'email': email,
      'password_hash': passwordHash,
      'role': role,
    });

    await _saveSession(id);

    return Account(fullName: name.trim(), email: email, role: role);
  }

  Future<Account> login(String email, String password) async {
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
    return _account(user);
  }

  Future<Account?> currentAccount() async {
    final db = await database;

    final rows = await db.rawQuery('''
      SELECT users.name, users.email, users.role
      FROM users
      JOIN active_session
      ON users.id = active_session.user_id
      WHERE active_session.slot = 1
      LIMIT 1
    ''');

    if (rows.isEmpty) return null;
    return _account(rows.first);
  }

  Future<void> logout() async {
    final db = await database;
    await db.delete('active_session');
  }
}
