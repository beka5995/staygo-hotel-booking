import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/cart_bloc.dart';

import '../state/store_controller.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'notes_screen.dart';
import '../state/preferences_store.dart';

class HomeShell extends StatefulWidget {
  final StoreController store;

  const HomeShell({super.key, required this.store});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SneakShop',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 25),
            ),
            Text(
              context.watch<PreferencesStore>().displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notes',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Notes')),
                  body: const NotesScreen(),
                ),
              ),
            ),
          ),
          BlocBuilder<CartBloc, CartState>(
            builder: (context, cart) {
              return Badge(
                isLabelVisible: cart.count > 0,
                label: Text('${cart.count}'),
                child: IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  tooltip: 'Shopping bag',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HeroMode(
            enabled: _selectedIndex == 0,
            child: CatalogScreen(store: widget.store),
          ),
          HeroMode(
            enabled: _selectedIndex == 1,
            child: FavoritesScreen(store: widget.store),
          ),
          ProfileScreen(
            store: widget.store,
            onSignedIn: () => setState(() => _selectedIndex = 0),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
