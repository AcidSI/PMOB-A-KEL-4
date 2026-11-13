import 'package:flutter/material.dart';

import 'package:find_it/models/item.dart';
import 'package:find_it/screens/add_report_screen.dart';
import 'package:find_it/screens/campus_location_picker_screen.dart';
import 'package:find_it/screens/chat_screen.dart';
import 'package:find_it/screens/detail_screen.dart';
import 'package:find_it/screens/home_screen.dart';
import 'package:find_it/screens/login_screen.dart';
import 'package:find_it/screens/lost_item_list_screen.dart';
import 'package:find_it/screens/map_discovery_screen.dart';
import 'package:find_it/screens/matching_screen.dart';
import 'package:find_it/screens/my_reports_screen.dart';
import 'package:find_it/screens/not_found_screen.dart';
import 'package:find_it/screens/register_screen.dart';
import 'package:find_it/services/matching_service.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String home = '/home';
  static const String detail = '/detail';
  static const String addReport = '/laporan/tambah';
  static const String editReport = '/laporan/ubah';
  static const String myReports = '/laporan/saya';
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
        return _notFound(settings);
      // ------------------------------------------------------- Modul 1
      case detail:
        final arguments = settings.arguments;
        if (arguments is Item) {
          return MaterialPageRoute<String>(
            builder: (_) => DetailScreen(item: arguments),
            settings: settings,
          );
        }
        return _notFound(settings);
      case addReport:
        // Argumen: bool isFound.
        final arguments = settings.arguments;
        if (arguments is bool) {
          return MaterialPageRoute<Item>(
            builder: (_) => AddReportScreen(isFound: arguments),
            settings: settings,
          );
        }
        return _notFound(settings);
      case editReport:
        // Argumen: laporan yang akan diubah (FR-R04).
        final arguments = settings.arguments;
        if (arguments is Item) {
          return MaterialPageRoute<Item>(
            builder: (_) => AddReportScreen(
              isFound: arguments.isFound,
              editItem: arguments,
            ),
            settings: settings,
          );
        }
        return _notFound(settings);
      case myReports:
        return MaterialPageRoute<void>(
          builder: (_) => const MyReportsScreen(),
          settings: settings,
        );
      // ----------------------------------------------------------------
      case chat:
        final arguments = settings.arguments;
        if (arguments is Item) {
          return MaterialPageRoute<void>(
            builder: (_) => ChatScreen(item: arguments),
            settings: settings,
          );
        }
        return _notFound(settings);
      case mapDiscovery:
        final arguments = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => arguments is Item
              ? MapDiscoveryScreen(initialSelectedItem: arguments)
              : const MapDiscoveryScreen(),
          settings: settings,
        );
      case locationPicker:
        final arguments = settings.arguments;
        if (arguments is Map<String, dynamic>) {
          return MaterialPageRoute<CampusLocationResult>(
            builder: (_) => CampusLocationPickerScreen(
              initialCenter: arguments['initialCenter'],
              initialLocationName: arguments['initialLocationName'],
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute<CampusLocationResult>(
          builder: (_) => const CampusLocationPickerScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) =>
      _notFound(settings);

  static Route<dynamic> _notFound(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => NotFoundScreen(routeName: settings.name),
      settings: settings,
    );
  }
}
