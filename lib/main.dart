import 'package:flutter/material.dart';

import 'routes/app_routes.dart';

void main() { 
  runApp(const FindItApp()); 
}
class FindItApp extends StatelessWidget {
  const FindItApp({super.key});

  @override
  Widget build(BuildContext context) {
    const forest = Color (0xFF045436); // Alternatif: 0xFF0B6670
    return MaterialApp( 
      title: "Find!t",
      debugShowCheckedModeBanner: false,
      theme: ThemeData( 
        colorScheme: ColorScheme.fromSeed(seedColor: forest, primary: forest, secondary: const Color.fromARGB(255, 115, 196, 122)),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: forest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // tepi tombol melengkung dengan radius 10
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      useMaterial3: true,
    ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute, 
      onUnknownRoute: AppRoutes.onUnknownRoute,
    );
  }
}