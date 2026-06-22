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

class _MainShellState extends State<MainShell> {
  StreamSubscription<List<int>>? _sub;
  StreamSubscription<List<int>>? _devSub; // Separate high-speed subscription
  
  int _pageIndex = 0;
  bool _devMode = false;

  final SensorBuffer _sensorBuffer = SensorBuffer();
  final List<int> _rxBuffer = [];

  @override
  void initState() {
    super.initState();
    if (widget.stream != null && widget.deviceId != null) {
      _startSession();
      _sub = widget.stream!.controller.stream.listen(_onPacket);
      
      // Listen to the high-frequency Dev Mode stream
      _devSub = widget.stream!.controllerDevMode.stream.listen(_onDevPacket);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _devSub?.cancel(); // Clean up the dev stream subscription
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
  // High-Speed 20Hz Binary Unpacker for Dev Mode
  // ---------------------------------------------------------------------------
  void _onDevPacket(List<int> frame) {
    if (frame.length < 20) return;

    // Convert to Little Endian ByteData view
    final bd = ByteData.sublistView(Uint8List.fromList(frame));

    // Unpack fields matching your C-struct sizing rules
    // final int counter   = frame[1];
    final double accX   = bd.getInt16(2, Endian.little).toDouble();
    final double accY   = bd.getInt16(4, Endian.little).toDouble();
    final double accZ   = bd.getInt16(6, Endian.little).toDouble();
    
    final double gyroX  = bd.getInt16(8, Endian.little).toDouble();
    final double gyroY  = bd.getInt16(10, Endian.little).toDouble();
    final double gyroZ  = bd.getInt16(12, Endian.little).toDouble();
    
    final double lightF3    = bd.getUint16(14, Endian.little).toDouble();
    final double lightClear = bd.getUint16(16, Endian.little).toDouble();

    // 4. Audio (Offsets 18 & 19)
    final double noiseDbSpl = frame[18].toDouble();
    final double noiseDbFs  = bd.getInt8(19).toDouble();

    // Push values directly into the active UI buffer pipelines
    _sensorBuffer.addRawAccel(accX, accY, accZ);
    _sensorBuffer.addRawGyro(gyroX, gyroY, gyroZ);
    
    _sensorBuffer.addRawMic(noiseDbSpl, noiseDbFs);
    _sensorBuffer.addRawLight(lightClear, lightF3);

  }

  // ---------------------------------------------------------------------------
  // Verified Frame Router
  // ---------------------------------------------------------------------------

  void _routeFrame(List<int> frame) {
    final msgType = MsgType.fromByte(frame[1]);

    debugPrint('Rx Frame Type: 0x${frame[1].toRadixString(16).toUpperCase()}');
    
    if (msgType == null) return;

 
    context.read<SessionStore>().onUnifiedPacket(frame);

    debugPrint('MainShell: Got 0x55 packet! Cadence: ${frame[4]}');
    
    final bd = ByteData.sublistView(Uint8List.fromList(frame));
    // --- 1. Kinematics (Unchanged) ---
    // Indexes: [2, 3], 4, 5
    final steps        = bd.getUint16(2, Endian.little).toDouble(); 
    final cadence      = frame[4].toDouble();
    final activity     = frame[5].toDouble();
    
    // --- 2. Light Metrics (FIXED ALIGNMENT) ---
    // Indexes: [6, 7], 8, [9, 10], [11, 12], [13, 14]
    final uvRisk        = bd.getUint16(6, Endian.little).toDouble();
    final blueIntensity = frame[8].toDouble(); //  Read as 1 byte (uint8)
    final blueRatio     = bd.getUint16(10, Endian.little) / 32767.0;  // Shifted to index 9
    final colorTemp     = bd.getUint16(12, Endian.little).toDouble();
    final clearChannel  = bd.getUint16(14, Endian.little).toDouble(); // Shifted to index 13
    
    // --- 3. Audio Metrics (NEW) ---
    // Indexes: 15, 16
    final noiseDbfs     = bd.getInt8(16).toDouble();  // int8_t (Signed)
    final noiseDbSpl    = frame[17].toDouble();       // uint8_t (Unsigned)

    // Push to buffer
    _sensorBuffer.addMetrics(
      steps: steps, 
      cadence: cadence, 
      activity: activity,
      lux: clearChannel, 
      uvRisk: uvRisk,
      blueIntensity: blueIntensity,
      blueRatio: blueRatio,
      colorTemp: colorTemp,
    );

    _sensorBuffer.addRawMic(noiseDbSpl, noiseDbfs); // Add mic data to buffers

  }

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
              // Send command to flip hardware microcontroller into RAW mode
              if (widget.stream != null) {
                widget.stream!.setMcuMode(true);
              }
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