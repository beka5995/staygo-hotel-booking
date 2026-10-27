
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:final_project_android_hotelbooking/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  Future<void> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
  }

  testWidgets('Home opens with navigation tabs', (tester) async {
    await openApp(tester);

    expect(find.text('StayGo'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('Hotel details open and can go back', (tester) async {
    await openApp(tester);

    await tester.tap(find.text('Ocean Hotel').first);
    await tester.pumpAndSettle();

    expect(find.text('Hotel details'), findsOneWidget);
    expect(find.text('Book now'), findsOneWidget);
    expect(find.text('Add to Trip'), findsOneWidget);

    final backButton = find.text('Back to hotels');

    await tester.ensureVisible(backButton);
    await tester.pumpAndSettle();

    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('Find your next stay'), findsOneWidget);
  });

  testWidgets('Favorites show empty state', (tester) async {
    await openApp(tester);

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('Registration and login switch correctly',
          (tester) async {
        await openApp(tester);

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create account'));
        await tester.pumpAndSettle();

        expect(find.text('Welcome to StayGo'), findsOneWidget);

        final signInButton = find.text(
          'Already have an account? Sign in',
        );

        expect(signInButton, findsOneWidget);

        await tester.tap(signInButton);
        await tester.pumpAndSettle();

        expect(find.text('Welcome back'), findsOneWidget);

        expect(
          find.text('New to StayGo? Create account'),
          findsOneWidget,
        );
      });

  testWidgets('Registration validates empty fields',
          (tester) async {
        await openApp(tester);

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create account'));
        await tester.pumpAndSettle();

        final submitButton = find.widgetWithText(
          FilledButton,
          'Create account',
        );

        await tester.ensureVisible(submitButton);
        await tester.pumpAndSettle();

        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(
          find.text('Please accept the Terms and Conditions'),
          findsOneWidget,
        );
      });

  testWidgets('Trip List opens from AppBar', (tester) async {
    await openApp(tester);

    await tester.tap(find.byTooltip('Trip List'));
    await tester.pumpAndSettle();

    expect(find.text('Trip List'), findsOneWidget);

    expect(
      find.text('Your trip list is empty'),
      findsOneWidget,
    );
  });

  testWidgets('Cart synchronizes with catalog', (tester) async {
    await openApp(tester);

    final addButton = find.widgetWithText(
      OutlinedButton,
      'Add to Trip',
    ).first;

    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Remove from Trip'), findsWidgets);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Trip List'));
    await tester.pumpAndSettle();

    expect(find.text('Clear All'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);

    await tester.tap(
      find.byTooltip('Remove item').first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Your trip list is empty'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Add to Trip'), findsWidgets);
  });

  testWidgets('Clear All empties Trip List', (tester) async {
    await openApp(tester);

    final addButton = find.widgetWithText(
      OutlinedButton,
      'Add to Trip',
    ).first;

    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Trip List'));
    await tester.pumpAndSettle();

    expect(find.text('Clear All'), findsOneWidget);

    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    expect(
      find.text('Your trip list is empty'),
      findsOneWidget,
    );

    expect(find.text('Total'), findsNothing);
  });
}
