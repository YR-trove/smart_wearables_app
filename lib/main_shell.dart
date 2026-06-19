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
  // The holding tank for fragmented BLE packets
  final List<int> _rxBuffer = [];

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
  // Packet Assembly & Fragmentation Handler — 1 Hz unified telemetry
  // ---------------------------------------------------------------------------

  void _onPacket(List<int> data) {
    // 1. Add all incoming fragmented bytes to our holding tank
    _rxBuffer.addAll(data);

    // 2. Keep processing as long as we have at least one full 20-byte potential frame
    while (_rxBuffer.length >= 20) {
      
      // Look for the Start Marker '{' (0x7B)
      final startIndex = _rxBuffer.indexOf(0x7B);

      if (startIndex == -1) {
        // No start marker found anywhere in the buffer. It's garbage. Clear it.
        _rxBuffer.clear();
        return;
      }

      if (startIndex > 0) {
        // We found a start marker, but there is garbage data before it. Toss the garbage.
        _rxBuffer.removeRange(0, startIndex);
        // If removing the garbage pushed us under 20 bytes, wait for the next BLE transmission.
        if (_rxBuffer.length < 20) return; 
      }

      // At this point, _rxBuffer[0] is guaranteed to be 0x7B.
      // Now, check if the 20th byte (index 19) is our End Marker '}' (0x7D).
      if (_rxBuffer[19] == 0x7D) {
        
        // WE HAVE A PERFECT 20-BYTE FRAME! Extract it.
        final validFrame = _rxBuffer.sublist(0, 20);
        
        // Remove it from the holding tank so we can process the next one
        _rxBuffer.removeRange(0, 20); 

        // Send the verified frame to the router
        _routeFrame(validFrame);
        
      } else {
        // We found a 0x7B, but the 20th byte isn't 0x7D. This means the 0x7B we 
        // found was probably just a random data value, not a real start marker.
        // Pop the first byte off to shift the buffer and keep searching.
        _rxBuffer.removeAt(0);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Verified Frame Router
  // ---------------------------------------------------------------------------

  void _routeFrame(List<int> frame) {
    final msgType = MsgType.fromByte(frame[1]);
    
    if (msgType == null) {
      debugPrint('MainShell: unknown packet type 0x${frame[1].toRadixString(16)}');
      return;
    }

    switch (msgType) {
      case MsgType.unifiedState:
        // Hand the safely assembled 20-byte frame to the Store
        context.read<SessionStore>().onUnifiedPacket(frame);
      case MsgType.battery:
        widget.stream?.controllerBattery.add(frame);
      default:
        // Ignore other types safely
        break;
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