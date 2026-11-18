import 'dart:io';

import 'package:final_project/database/local_auth.dart';
import 'package:final_project/state/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('Login checks real local accounts and emits loading, error and success', () async {
    final directory = await Directory.systemTemp.createTemp('auth_cubit_test_');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    await databaseFactory.setDatabasesPath(directory.path);
    final auth = LocalAuth.instance;
    final db = await auth.database;
    final cubit = AuthCubit();
    addTearDown(() async {
      await cubit.close();
      await db.close();
      await directory.delete(recursive: true);
    });

    await auth.register(
      name: 'Test Account',
      email: 'user@example.com',
      password: 'test-password',
      role: 'Shopper',
    );
    await auth.logout();

    expect(cubit.state, const AuthInitial());
    final failure = cubit.login('user@example.com', 'wrong-password');
    expect(cubit.state, const AuthLoading());
    await failure;
    expect(cubit.state, const AuthError('Incorrect email or password'));
    expect(await auth.currentAccount(), isNull);

    final success = cubit.login(' USER@example.com ', 'test-password');
    expect(cubit.state, const AuthLoading());
    await success;
    final signedIn = cubit.state as AuthSuccess;
    expect(signedIn.username, 'Test Account');
    expect(signedIn.email, 'user@example.com');
    expect((await auth.currentAccount())?.email, signedIn.email);
  });
}
