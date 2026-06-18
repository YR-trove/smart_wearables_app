import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/connection/connection_page.dart';
import 'package:smart_wearables_app/store/session_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Step 1: Provide SessionStore above the entire widget tree ──────────
    // A single ChangeNotifierProvider means every descendant (ConnectionPage,
    // MainShell, FitnessPage, LightPage) shares the same store instance and
    // rebuilds automatically when notifyListeners() is called.
    return ChangeNotifierProvider<SessionStore>(
      create: (_) => SessionStore(),
      child: MaterialApp(
        title: 'Smart Wearables App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        home: const ConnectionPage(title: 'Connect your device!'),
      ),
    );
  }
}
