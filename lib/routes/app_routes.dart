import 'package:flutter/material.dart';

import '../models/item.dart';
import '../screens/catatan_form_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/not_found_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Semua route dipusatkan di sini; argumen detail diperiksa sebelum dipakai.
  static const String login = '/login';
  static const String home = '/home';
  static const String detail = '/detail';
  static const String noteForm = '/catatan-form';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case detail:
        final arguments = settings.arguments;
        if (arguments is Item) {
          return MaterialPageRoute<void>(
            builder: (_) => DetailScreen(item: arguments),
            settings: settings,
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => NotFoundScreen(routeName: settings.name),
          settings: settings,
        );
      case noteForm:
        return MaterialPageRoute<String>(
          builder: (_) => const CatatanFormScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => NotFoundScreen(routeName: settings.name),
      settings: settings,
    );
  }
}