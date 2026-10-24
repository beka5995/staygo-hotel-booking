import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_project_android_hotelbooking/main.dart';

void main() {
  Future<void> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
  }

  testWidgets('Home opens with three navigation tabs', (tester) async {
    await openApp(tester);
    expect(find.text('StayGo'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Hotel details open and can go back', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Ocean Hotel').first);
    await tester.pumpAndSettle();
    expect(find.text('Hotel details'), findsOneWidget);
    expect(find.text('Book now'), findsOneWidget);
    await tester.ensureVisible(find.text('Back to hotels'));
    await tester.tap(find.text('Back to hotels'));
    await tester.pumpAndSettle();
    expect(find.text('Find your next stay'), findsOneWidget);
  });

  testWidgets('Favorites show their empty state', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('Registration shows errors for empty inputs', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    final submitButton = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please accept the Terms and Conditions'), findsOneWidget);
  });
}
