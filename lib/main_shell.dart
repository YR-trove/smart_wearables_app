import 'package:flutter/material.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/home_page.dart';
import 'package:smart_wearables_app/pages/fitness_page.dart';
import 'package:smart_wearables_app/pages/light_page.dart';
import 'package:smart_wearables_app/pages/stress_page.dart';
import 'package:smart_wearables_app/pages/settings_page.dart';
import 'app_theme.dart';

class MainShell extends StatefulWidget {
  final MyStream stream;
  const MainShell({super.key, required this.stream});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _devMode = false;

  void _onDevModeChanged(bool val) {
    setState(() {
      _devMode = val;
      // If dev mode turned off while on dev tab, go back to home
      if (!val && _selectedIndex == 4) {
        _selectedIndex = 0;
      }
    });
  }

  void _onTabTapped(int index) {
    if (index == 4 && !_devMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable Developer Mode in Settings to access this tab.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const FitnessPage(),
          const LightPage(),
          const StressPage(),
          SettingsPage(
            devMode: _devMode,
            onDevModeChanged: _onDevModeChanged,
          ),
          HomePage(
            title: 'Developer',
            stream: widget.stream,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.light_mode_outlined, Icons.light_mode_rounded, 'Light'),
              _navItem(2, Icons.graphic_eq, Icons.graphic_eq, 'Stress'),
              _navItem(3, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
              _navItem(4, Icons.terminal_outlined, Icons.terminal, 'Developer',
                  disabled: !_devMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label, {
    bool disabled = false,
  }) {
    final isActive = _selectedIndex == index;
    final color = disabled
        ? AppColors.inactive.withOpacity(0.4)
        : isActive
            ? AppColors.accent
            : AppColors.inactive;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? filledIcon : outlinedIcon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
