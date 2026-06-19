import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/connection/connection_page.dart';
import 'package:smart_wearables_app/connection/message_type.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/data/session_store.dart';
import 'package:smart_wearables_app/data/sensor_buffer.dart';
import 'package:smart_wearables_app/home_page.dart';
import 'package:smart_wearables_app/pages/fitness_page.dart';
import 'package:smart_wearables_app/pages/light_page.dart';
import 'package:smart_wearables_app/pages/settings_page.dart';
import 'package:smart_wearables_app/pages/stress_page.dart';

/// Top-level shell shown while a BLE device is connected (or offline).
class MainShell extends StatefulWidget {
  final MyStream? stream;
  final String? deviceId;

  const MainShell({
    super.key,
    this.stream,
    this.deviceId,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  StreamSubscription<List<int>>? _sub;
  
  // Since devMode defaults to false, index 0 will now point to the Fitness Page!
  int _pageIndex = 0;
  bool _devMode = false;

  final SensorBuffer _sensorBuffer = SensorBuffer();

  @override
  void initState() {
    super.initState();
    if (widget.stream != null && widget.deviceId != null) {
      _startSession();
      _sub = widget.stream!.controller.stream.listen(_onPacket);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (widget.stream != null) {
      context.read<SessionStore>()
          .endSession()
          .catchError((e) => debugPrint('MainShell: endSession error — $e'));
    }
    _sensorBuffer.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Session start
  // ---------------------------------------------------------------------------

  void _startSession() {
    if (widget.deviceId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<SessionStore>().startSession(widget.deviceId!);
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
    if (data.length != 20 || data[0] != 0x7B || data[19] != 0x7D) return;

    final msgType = MsgType.fromByte(data[1]);
    if (msgType == null) {
      debugPrint('MainShell: unknown packet type 0x${data[1].toRadixString(16)}');
      return;
    }

    switch (msgType) {
      case MsgType.unifiedState:
        context.read<SessionStore>().onUnifiedPacket(data);
      case MsgType.battery:
        widget.stream?.controllerBattery.add(data);
      default:
        debugPrint('MainShell: unhandled packet type ${msgType.name}');
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.stream != null;

    // 1. Dynamically build the list of pages based on Dev Mode
    final screens = <Widget>[
      if (_devMode) HomePage(title: 'Raw Data (Dev)', buffer: _sensorBuffer),
      const FitnessPage(),
      const LightPage(),
      const StressPage(),
      SettingsPage(
        devMode: _devMode,
        onDevModeChanged: (v) {
          setState(() {
            _devMode = v;
            // Index Shifting Logic:
            // When turning Dev Mode ON, the Dev page is inserted at the front (index 0).
            // We must increment the current index so the user doesn't get kicked off the Settings page.
            if (_devMode) {
              _pageIndex++;
            } else {
              _pageIndex--;
            }
          });
        },
      ),
    ];

    // 2. Dynamically build the Navigation bar icons
    final destinations = <NavigationDestination>[
      if (_devMode) const NavigationDestination(icon: Icon(Icons.developer_board), label: 'Dev Data'),
      const NavigationDestination(icon: Icon(Icons.directions_run), label: 'Fitness'),
      const NavigationDestination(icon: Icon(Icons.wb_sunny), label: 'Light'),
      const NavigationDestination(icon: Icon(Icons.self_improvement), label: 'Stress'),
      const NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _pageIndex,
        children: screens,
      ),
      floatingActionButton: !isConnected
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConnectionPage(title: 'Connect your device!'),
                  ),
                );
              },
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Connect Glasses'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: (i) => setState(() => _pageIndex = i),
        destinations: destinations,
      ),
    );
  }
}