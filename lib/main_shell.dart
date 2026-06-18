import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/connection/message_type.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/data/session_store.dart';
import 'package:smart_wearables_app/home_page.dart';
import 'package:smart_wearables_app/pages/fitness_page.dart';
import 'package:smart_wearables_app/pages/light_page.dart';
import 'package:smart_wearables_app/pages/settings_page.dart';
import 'package:smart_wearables_app/pages/stress_page.dart';

/// Top-level shell shown while a BLE device is connected.
///
/// Responsibilities:
///   - Owns the BLE stream subscription.
///   - Validates every incoming 20-byte frame.
///   - Routes [MsgType.unifiedState] (0x55) packets to [SessionStore.onUnifiedPacket].
///   - Manages session start/end lifecycle.
class MainShell extends StatefulWidget {
  final MyStream stream;
  final String   deviceId;

  const MainShell({
    super.key,
    required this.stream,
    required this.deviceId,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  StreamSubscription<List<int>>? _sub;
  int  _pageIndex = 0;
  bool _devMode   = false;

  @override
  void initState() {
    super.initState();
    _startSession();
    _sub = widget.stream.controller.stream.listen(_onPacket);
  }

  @override
  void dispose() {
    _sub?.cancel();
    context.read<SessionStore>()
        .endSession()
        .catchError((e) => debugPrint('MainShell: endSession error — $e'));
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Session start
  // ---------------------------------------------------------------------------

  void _startSession() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<SessionStore>().startSession(widget.deviceId);
        debugPrint('MainShell: session started (${widget.deviceId})');
      } catch (e) {
        debugPrint('MainShell: startSession error — $e');
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Packet router — 1 Hz unified telemetry
  // ---------------------------------------------------------------------------

  void _onPacket(List<int> data) {
    // Frame validation: exactly 20 bytes, correct start/end markers.
    if (data.length != 20 || data[0] != 0x7B || data[19] != 0x7D) return;

    final msgType = MsgType.fromByte(data[1]);
    if (msgType == null) {
      debugPrint('MainShell: unknown packet type 0x${data[1].toRadixString(16)}');
      return;
    }

    switch (msgType) {
      case MsgType.unifiedState:
        // Hand the raw validated frame to SessionStore for decoding + persistence.
        // No axis scaling, no buffering — MCU delivers ready-to-use values.
        context.read<SessionStore>().onUnifiedPacket(data);

      case MsgType.battery:
        // Routed to the battery stream in MyStream for UI consumption.
        widget.stream.controllerBattery.add(data);

      default:
        debugPrint('MainShell: unhandled packet type ${msgType.name}');
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  static const _pages = [
    _PageMeta(icon: Icons.dashboard,            label: 'Dashboard'),
    _PageMeta(icon: Icons.directions_run,        label: 'Fitness'),
    _PageMeta(icon: Icons.wb_sunny,              label: 'Light'),
    _PageMeta(icon: Icons.self_improvement,      label: 'Stress'),
    _PageMeta(icon: Icons.settings,              label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _pageIndex,
        children: [
          const HomePage(),
          const FitnessPage(),
          const LightPage(),
          const StressPage(),
          SettingsPage(
            devMode: _devMode,
            onDevModeChanged: (v) => setState(() => _devMode = v),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: (i) => setState(() => _pageIndex = i),
        destinations: _pages
            .map((p) => NavigationDestination(
                  icon: Icon(p.icon), label: p.label))
            .toList(),
      ),
    );
  }
}

class _PageMeta {
  final IconData icon;
  final String   label;
  const _PageMeta({required this.icon, required this.label});
}
