import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project/state/preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_project/state/cart_bloc.dart';
import 'package:final_project/screens/catalog_screen.dart';
import 'package:final_project/screens/home_shell.dart';
import 'package:final_project/screens/product_detail_screen.dart';
import 'package:final_project/screens/profile_screen.dart';
import 'package:final_project/utils/price.dart';

import 'fixtures/catalog.dart';

late PreferencesStore localPreferences;
Widget host(Widget child, CartBloc cart) => MultiProvider(
      providers: [
        BlocProvider<CartBloc>.value(value: cart),
        ChangeNotifierProvider<PreferencesStore>.value(value: localPreferences),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localPreferences = await PreferencesStore.load();
  });
  tearDown(() => localPreferences.dispose());
  test('prices retain cents and the cart currency', () {
    expect(formatPrice(149.99), '\$149.99');
    expect(formatPrice(150), '\$150.00');
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 360),
    const Size(1440, 900),
  ]) {
    testWidgets('full app and product details fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = testStore();
      await store.loadCatalog();
      final cart = CartBloc();
      await tester.pumpWidget(host(HomeShell(store: store), cart));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('List view'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        host(
          ProductDetailScreen(product: store.products.first, store: store),
          cart,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      unawaited(cart.close());
      await tester.pump();
    });
  }

  testWidgets(
    'details pass a complete product and body back preserves favorites',
    (tester) async {
      final store = testStore();
      await store.loadCatalog();
      final product = store.products.first;
      store.toggleFavorite(product.id);
      final cart = CartBloc();
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ProductDetailScreen(product: product, store: store),
                ),
              ),
              child: const Text('Open pair'),
            ),
          ),
          cart,
        ),
      );
      await tester.tap(find.text('Open pair'));
      await tester.pumpAndSettle();
      expect(find.text(product.name), findsOneWidget);
      await tester.ensureVisible(find.text('Back to catalog'));
      await tester.tap(find.text('Back to catalog'));
      await tester.pumpAndSettle();
      expect(find.text('Open pair'), findsOneWidget);
      expect(store.isFavorite(product.id), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      unawaited(cart.close());
      await tester.pump();
    },
  );

  testWidgets('registration validates fields, passwords and required terms', (
    tester,
  ) async {
    final store = testStore();
    final cart = CartBloc();
    await tester.pumpWidget(host(ProfileScreen(store: store), cart));
    await tester.tap(find.text('New to SneakShop? Create account'));
    await tester.pumpAndSettle();
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Student Name');
    await tester.enterText(fields.at(1), 'student@narxoz.kz');
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), '123');
    await tester.ensureVisible(fields.at(3));
    await tester.enterText(fields.at(3), 'different');
    expect(form.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), 'secret123');
    await tester.ensureVisible(fields.at(3));
    await tester.enterText(fields.at(3), 'secret123');
    expect(form.validate(), isTrue);
    final submit = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Please accept the Terms and Conditions'), findsOneWidget);
    expect(store.account, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
    unawaited(cart.close());
    await tester.pump();
  });

  testWidgets('swipe, UNDO, empty state and network reset work together', (
    tester,
  ) async {
    final store = testStore();
    await store.loadCatalog();
    final cart = CartBloc();
    final ids = store.products.map((p) => p.id).toList();
    await tester.pumpWidget(host(CatalogScreen(store: store), cart));
    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Dismissible).first, const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(store.products.length, 5);
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(store.products.map((p) => p.id).toList(), ids);
    for (final item in store.products.toList()) {
      store.removeProduct(item.id);
    }
    await tester.pumpAndSettle();
    expect(find.text('Catalog is Empty'), findsOneWidget);
    await tester.tap(find.text('Reset Catalog'));
    await tester.pumpAndSettle();
    expect(store.products.length, 6);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
    unawaited(cart.close());
    await tester.pump();
  });
}
