import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/data/session_store.dart';
import 'package:smart_wearables_app/main_shell.dart';
import 'package:smart_wearables_app/theme_provider.dart';


void main() async {
  // Required before any async call or plugin use in main().
  WidgetsFlutterBinding.ensureInitialized();

  // Open the SQLite DB and recover any in-progress session.
  final sessionStore = SessionStore();
  try {
    await sessionStore.init();
  } catch (e) {
    debugPrint("Database Initialization Failed: $e");
    // to handle the corrupted state during app startup.
  }

  runApp(
    // MultiProvider allows you to inject both stores at the root
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sessionStore),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the ThemeProvider for real-time changes
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Smart Wearables App',
      themeMode: themeProvider.themeMode, // Drives Light/Dark/Auto
      
      // Light Theme Definition
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.accentColor, // Dynamic accent!
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        useMaterial3: true,
      ),
      
      // Dark Theme Definition
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.accentColor, // Dynamic accent!
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      
      home: const MainShell(),
    );
  }
}
