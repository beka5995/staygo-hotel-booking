import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project_android_hotelbooking/main.dart';
import 'package:final_project_android_hotelbooking/state/preferences_store.dart';
import 'package:final_project_android_hotelbooking/state/hotel_store.dart';

import 'support/fixtures.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> mount(WidgetTester tester, PreferencesStore local) async {
    final store = HotelStore(service: fixtureService());
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MyApp(preferences: local, store: store, enablePlatformServices: false),
    );
  }

  Future<void> notesTab(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Notes'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Saved dark mode is present on the very first MaterialApp frame',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        PreferencesStore.themeKey: true,
        PreferencesStore.nameKey: 'Saved name',
      });
      final local = await PreferencesStore.load();
      await mount(tester, local);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
      );
      await tester.pumpAndSettle();
      await notesTab(tester);
      expect(find.text('Hello, Saved name'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      local.dispose();
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 360),
    const Size(1440, 900),
  ]) {
    testWidgets('Dark notes and settings fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({PreferencesStore.themeKey: true});
      final local = await PreferencesStore.load();
      await local.addNote(
        'A reminder long enough to wrap neatly on a narrow phone screen.',
      );
      await mount(tester, local);
      await tester.pumpAndSettle();
      await notesTab(tester);
      final list = find
          .descendant(
            of: find.byKey(const PageStorageKey('notes-vault')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(local.notes.first.id)),
        180,
        scrollable: list,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      local.dispose();
    });
  }

  testWidgets(
    'UI saves name, theme and two notes, restores them and deletes on disk',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var local = await PreferencesStore.load();
      await mount(tester, local);
      await tester.pumpAndSettle();
      await notesTab(tester);
      await tester.enterText(
        find.byKey(const ValueKey('display-name-field')),
        'Beka',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('save-display-name')),
      );
      await tester.tap(find.byKey(const ValueKey('save-display-name')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('dark-mode-toggle')),
      );
      await tester.tap(find.byKey(const ValueKey('dark-mode-toggle')));
      await tester.pumpAndSettle();
      expect(local.darkMode, isTrue);
      for (final title in ['First reminder', 'Second reminder']) {
        await tester.ensureVisible(
          find.byKey(const ValueKey('note-title-field')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('note-title-field')),
          title,
        );
        await tester.ensureVisible(find.byKey(const ValueKey('add-note')));
        await tester.tap(find.byKey(const ValueKey('add-note')));
        await tester.pumpAndSettle();
      }
      final list = find
          .descendant(
            of: find.byKey(const PageStorageKey('notes-vault')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(local.notes.first.id)),
        180,
        scrollable: list,
      );
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(local.notes.first.isCompleted, isTrue);
      final disk = await SharedPreferences.getInstance();
      final snapshot = {for (final key in disk.getKeys()) key: disk.get(key)!};
      await tester.pumpWidget(const SizedBox());
      local.dispose();
      SharedPreferences.setMockInitialValues(snapshot);
      local = await PreferencesStore.load();
      await mount(tester, local);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      await tester.pumpAndSettle();
      await notesTab(tester);
      expect(find.text('Hello, Beka'), findsOneWidget);
      expect(local.notes, hasLength(2));
      expect(local.notes.first.isCompleted, isTrue);
      final restoredList = find
          .descendant(
            of: find.byKey(const PageStorageKey('notes-vault')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(local.notes.first.id)),
        180,
        scrollable: restoredList,
      );
      await tester.tap(find.byTooltip('Delete note').first);
      await tester.pumpAndSettle();
      expect(local.notes, hasLength(1));
      final reloaded = await PreferencesStore.load();
      expect(reloaded.notes, hasLength(1));
      reloaded.dispose();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      local.dispose();
    },
  );
}
