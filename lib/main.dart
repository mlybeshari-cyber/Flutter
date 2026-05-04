import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/traccar_service.dart';
import 'screens/login_screen.dart';

// Pika e hyrjes e aplikacionit Traccar Flutter
// Entry point of the Traccar Flutter application

void main() async {
  // Siguro inicializimin e Flutter / Ensure Flutter initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializo shërbimin / Initialize the service
  final service = TraccarService();
  await service.init();

  runApp(
    // Provide TraccarService to the whole app / Ofroj TraccarService për gjithë aplikacionin
    Provider<TraccarService>.value(
      value: service,
      child: const TraccarApp(),
    ),
  );
}

class TraccarApp extends StatelessWidget {
  const TraccarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traccar GPS',
      debugShowCheckedModeBanner: false,

      // Tema e çelët / Light theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 2,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Tema e errët / Dark theme
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 2,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Ndyshimi automatik i temës / Automatic theme switch
      themeMode: ThemeMode.system,

      // Ekrani fillestar / Initial screen
      home: const LoginScreen(),
    );
  }
}
