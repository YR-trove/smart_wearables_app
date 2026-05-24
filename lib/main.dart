import 'package:flutter/material.dart';
import 'package:smart_wearables_app/connection/connection_page.dart';
import 'theme.dart';
import 'pages/fitness_page.dart';
import 'pages/light_page.dart';
import 'pages/noise_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Wearables App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),

      home: const ConnectionPage(title: 'Connect your device!'),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}
// class SmartWearablesApp extends StatelessWidget {
//   const SmartWearablesApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Smart Wearables',
//       debugShowCheckedModeBanner: false,
//       theme: buildAppTheme(),
//       home: const MainScaffold(),
//     );
//   }
// }
class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    //HomePage(),
    FitnessPage(),
    LightPage(),
    NoisePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1220),
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: _navColor(_currentIndex),
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.directions_run),
              ),
              label: 'Fitness',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.wb_sunny_outlined),
              ),
              label: 'Light',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.headphones_outlined),
              ),
              label: 'Noise',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.settings_outlined),
              ),
              label: 'Settings',
            ),
          ],
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Color _navColor(int index) {
    switch (index) {
      case 0: return AppColors.cyan;
      case 1: return AppColors.yellow;
      case 2: return AppColors.orange;
      case 3: return AppColors.cyan;
      default: return AppColors.cyan;
    }
  }
}
