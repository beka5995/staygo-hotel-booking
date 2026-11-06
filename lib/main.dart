
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'data/sample_hotels.dart';
import 'services/staygo_links.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CartProvider>(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: 'StayGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
        onGenerateRoute: (settings) {
          final hotelId = hotelIdFromLink(settings.name ?? '');
          if (hotelId == null ||
              !sampleHotels.any((hotel) => hotel.id == hotelId)) {
            return null;
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => HomeScreen(initialHotelId: hotelId),
          );
        },
      ),
    );
  }
}
