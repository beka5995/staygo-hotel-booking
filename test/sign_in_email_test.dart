import 'dart:io';

import 'package:final_project_android_hotelbooking/database/local_auth.dart';
import 'package:final_project_android_hotelbooking/main.dart';
import 'package:final_project_android_hotelbooking/state/auth_cubit.dart';
import 'package:final_project_android_hotelbooking/state/hotel_store.dart';
import 'package:final_project_android_hotelbooking/state/preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fixtures.dart';

void main() {
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('sign_in_email_');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    await databaseFactory.setDatabasesPath(directory.path);
    final db = await LocalAuth.instance.database;
    addTearDown(() async {
      await db.close();
      await directory.delete(recursive: true);
    });
  });

  testWidgets('Registration remembers the email after sign-out and restart', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const email = 'traveler@example.com';
    const password = 'test-password';

    Future<void> openApp() async {
      final store = HotelStore(service: fixtureService());
      final preferences = await PreferencesStore.load();
      addTearDown(store.dispose);
      addTearDown(preferences.dispose);
      await tester.pumpWidget(
        MyApp(
          preferences: preferences,
          store: store,
          enablePlatformServices: false,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await openApp();
    await tapVisible(find.widgetWithText(FilledButton, 'Create account'));
    final fields = find.byType(TextFormField);
    for (final (index, value) in [
      (0, 'Traveler Name'),
      (1, email),
      (2, password),
      (3, password),
    ]) {
      await tester.ensureVisible(fields.at(index));
      await tester.enterText(fields.at(index), value);
    }
    await tapVisible(find.byType(CheckboxListTile));
    final submit = find.widgetWithText(FilledButton, 'Create account');
    final cubit = tester.element(submit).read<AuthCubit>();
    // SQLite uses real asynchronous I/O even when the widget clock is mocked.
    await tester.runAsync(() async {
      final outcome = cubit.stream.firstWhere((state) => state is! AuthLoading);
      tester.widget<FilledButton>(submit).onPressed!();
      expect(
        await outcome.timeout(const Duration(seconds: 5)),
        isA<AuthSuccess>(),
      );
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    final signOut = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Sign out'),
    );
    await tester.runAsync(signOut.onPressed! as Future<void> Function());
    await tester.pumpAndSettle();
    await tapVisible(find.widgetWithText(OutlinedButton, 'Sign in'));
    String textAt(int index) => tester
        .widget<EditableText>(find.byType(EditableText).at(index))
        .controller
        .text;
    expect(textAt(0), email);
    expect(textAt(1), isEmpty);

    final prefs = await SharedPreferences.getInstance();
    final persistedValues = {
      for (final key in prefs.getKeys()) key: prefs.get(key)!,
    };
    await tester.pumpWidget(const SizedBox());
    SharedPreferences.setMockInitialValues(persistedValues);
    await openApp();
    await tapVisible(find.widgetWithText(OutlinedButton, 'Sign in'));
    expect(textAt(0), email);
    expect(textAt(1), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
