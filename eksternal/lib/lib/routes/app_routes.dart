import 'package:flutter/material.dart';

import '../models/item.dart';
// import '../screens/catatan_form_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/add_report_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Kata kunci static digunakan pada variabel atau method agar milik kelas secara langsung, bukan milik objek
  static const String login = '/login'; 
  static const String home = '/home';
  static const String detail = '/detail';
  //static const String noteForm = '/catatan-form';
  static const String addReport = '/laporan/tambah';
  static const String chat = '/chat';

  // Fungsi yang dipanggil MaterialApp untuk membuat rute berdasarkan settings
  // Route<dynamic>? berarti fungsi dapat mengembalikan rute dengan hasil berbagai tipe atau null jika nama rutenya tidak cocok.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>( // Tipe void berarti rute ini tidak mengembalikan data melalui Navigator.pop
          builder: (_) => const LoginScreen(),
          settings: settings, // Meneruskan informasi rute, termasuk nama dan argumen, ke objek rute
        );
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case detail:
        final arguments = settings.arguments; // Mengambil argumen yang diteruskan ke rute ini
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
      /*case noteForm:
        return MaterialPageRoute<String>(
          builder: (_) => const CatatanFormScreen(),
          settings: settings,
        );*/
      case addReport:
        final arguments = settings.arguments; // Mengambil argumen yang diteruskan ke rute ini
        if (arguments is bool) { // Memeriksa apakah argumen yang diteruskan adalah boolean
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