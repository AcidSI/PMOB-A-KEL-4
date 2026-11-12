import 'package:flutter/material.dart';

import '../models/item.dart';
import '../screens/add_report_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/lost_item_list_screen.dart';
import '../screens/map_discovery_screen.dart';
import '../screens/campus_location_picker_screen.dart';
import '../screens/matching_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/register_screen.dart';
import '../services/matching_service.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String home = '/home';
  static const String detail = '/detail';
  static const String addReport = '/laporan/tambah';
  static const String chat = '/chat';
  static const String advancedSearch = '/pencarian-lanjutan';
  static const String matches = '/matching';
  static const String register = '/register';
  static const String mapDiscovery = '/peta-discovery';
  static const String locationPicker = '/lokasi/pilih';

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
      case register:
        return MaterialPageRoute<String>(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case advancedSearch:
        return MaterialPageRoute<void>(
          builder: (_) => const LostItemListScreen(),
          settings: settings,
        );
      case matches:
        final arguments = settings.arguments;
        if (arguments is MatchingService) {
          return MaterialPageRoute<void>(
            builder: (_) => MatchingScreen(service: arguments),
            settings: settings,
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => NotFoundScreen(routeName: settings.name),
          settings: settings,
        );
      case detail:
        final arguments = settings.arguments;
        if (arguments is Item) {
          return MaterialPageRoute<String>(
            builder: (_) => DetailScreen(item: arguments),
            settings: settings,
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => NotFoundScreen(routeName: settings.name),
          settings: settings,
        );
      case addReport:
        final arguments = settings.arguments;
        if (arguments is bool) {
          return MaterialPageRoute<Item>(
            builder: (_) => AddReportScreen(isFound: arguments),
            settings: settings,
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => NotFoundScreen(routeName: settings.name),
          settings: settings,
        );
      case chat:
        final arguments = settings.arguments;
        if (arguments is Item) {
          return MaterialPageRoute<void>(
            builder: (_) => ChatScreen(item: arguments),
            settings: settings,
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => NotFoundScreen(routeName: settings.name),
          settings: settings,
        );
      case mapDiscovery:
        final arguments = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => arguments is Item
              ? MapDiscoveryScreen(initialSelectedItem: arguments)
              : const MapDiscoveryScreen(),
          settings: settings,
        );
      case locationPicker:
        return MaterialPageRoute<CampusLocationResult>(
          builder: (_) => const CampusLocationPickerScreen(),
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
