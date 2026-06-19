import 'dart:async';
import 'dart:typed_data'; 
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

// FIX 1: Added the underscore back to _MainShellState
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
    _rxBuffer.addAll(data);

    while (_rxBuffer.length >= 20) {
      final startIndex = _rxBuffer.indexOf(0x7B);

      if (startIndex == -1) {
        _rxBuffer.clear();
        return;
      }

      if (startIndex > 0) {
        _rxBuffer.removeRange(0, startIndex);
        if (_rxBuffer.length < 20) return; 
      }

      if (_rxBuffer[19] == 0x7D) {
        final validFrame = _rxBuffer.sublist(0, 20);
        _rxBuffer.removeRange(0, 20); 
        _routeFrame(validFrame);
      } else {
        _rxBuffer.removeAt(0);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Verified Frame Router
  // ---------------------------------------------------------------------------

  void _routeFrame(List<int> frame) {
    final msgType = MsgType.fromByte(frame[1]);
    if (msgType == null) return;

    switch (msgType) {
      case MsgType.unifiedState: // 0x55
        context.read<SessionStore>().onUnifiedPacket(frame);
        final bd = ByteData.sublistView(Uint8List.fromList(frame));
        final cadence = frame[4].toDouble();
        final clearChannel = bd.getUint16(14, Endian.little).toDouble();
        final blueRatio = bd.getUint16(10, Endian.little) / 32767.0;
        _sensorBuffer.addMetrics(cadence: cadence, lux: clearChannel, blueRatio: blueRatio);

      case MsgType.accel: // 0x01
        final bd = ByteData.sublistView(Uint8List.fromList(frame));
        final x = bd.getInt16(2, Endian.little).toDouble(); 
        final y = bd.getInt16(4, Endian.little).toDouble(); 
        final z = bd.getInt16(6, Endian.little).toDouble(); 
        _sensorBuffer.addRawAccel(x, y, z); 

      case MsgType.gyro: // 0x02
        final bd = ByteData.sublistView(Uint8List.fromList(frame));
        final x = bd.getInt16(2, Endian.little).toDouble(); 
        final y = bd.getInt16(4, Endian.little).toDouble(); 
        final z = bd.getInt16(6, Endian.little).toDouble(); 
        _sensorBuffer.addRawGyro(x, y, z); 

      case MsgType.lightRawVis: // 0x03
        final bd = ByteData.sublistView(Uint8List.fromList(frame));
        _sensorBuffer.addRawLight(
          bd.getUint16(2, Endian.little).toDouble(),  // F1
          bd.getUint16(4, Endian.little).toDouble(),  // F2
          bd.getUint16(6, Endian.little).toDouble(),  // F3
          bd.getUint16(8, Endian.little).toDouble(),  // F4
          bd.getUint16(10, Endian.little).toDouble(), // F5
          bd.getUint16(12, Endian.little).toDouble(), // F6
          bd.getUint16(14, Endian.little).toDouble(), // F7
          bd.getUint16(16, Endian.little).toDouble(), // F8
        );

      case MsgType.battery: // 0xB0
        widget.stream?.controllerBattery.add(frame);
      
      default:
        break;
    }
  } // FIX 3: Added missing closing bracket for the _routeFrame function!

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.stream != null;

    final screens = <Widget>[
      if (_devMode) HomePage(title: 'Raw Data (Dev)', buffer: _sensorBuffer, stream: widget.stream),
      const FitnessPage(),
      const LightPage(),
      const StressPage(),
      SettingsPage(
        devMode: _devMode,
        onDevModeChanged: (v) {
          setState(() {
            _devMode = v;
            if (_devMode) {
              _pageIndex++;
            } else {
              _pageIndex--;
              if (widget.stream != null) {
                widget.stream!.setMcuMode(false);
              }
            }
          });
        },
      ),
    ];

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