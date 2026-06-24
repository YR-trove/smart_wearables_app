import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/connection/connection_page.dart';
import 'package:smart_wearables_app/connection/message_type.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/data/models/unified_telemetry.dart';
import 'package:smart_wearables_app/data/session_store.dart';
import 'package:smart_wearables_app/data/sensor_buffer.dart';
import 'package:smart_wearables_app/home_page.dart';
import 'package:smart_wearables_app/pages/fitness_page.dart';
import 'package:smart_wearables_app/pages/light_page.dart';
import 'package:smart_wearables_app/pages/settings_page.dart';
import 'package:smart_wearables_app/pages/stress_page.dart';

// ---------------------------------------------------------------------------
// Navigation tabs — enum-based so toggling dev mode never causes index drift.
// ---------------------------------------------------------------------------

enum AppTab { devData, fitness, light, stress, settings }

/// Top-level shell shown while a BLE device is connected (or offline).
class MainShell extends StatefulWidget {
  final MyStream? stream;
  final String?   deviceId;

  const MainShell({super.key, this.stream, this.deviceId});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  StreamSubscription<List<int>>? _sub;
  StreamSubscription<List<int>>? _devSub;

  AppTab _currentTab = AppTab.fitness;
  bool   _devMode    = false;

  final SensorBuffer _sensorBuffer = SensorBuffer();
  final List<int>    _rxBuffer     = [];

  @override
  void initState() {
    super.initState();
    if (widget.stream != null && widget.deviceId != null) {
      _startSession();
      _sub    = widget.stream!.controller.stream.listen(_onPacket);
      _devSub = widget.stream!.controllerDevMode.stream.listen(_onDevPacket);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _devSub?.cancel();
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
  // Packet assembly — 1 Hz unified telemetry
  // ---------------------------------------------------------------------------

  void _onPacket(List<int> data) {
    _rxBuffer.addAll(data);

    while (_rxBuffer.length >= 20) {
      final startIndex = _rxBuffer.indexOf(0x7B);

      if (startIndex == -1) { _rxBuffer.clear(); return; }

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
  // High-speed 20 Hz binary unpacker — dev mode only
  // ---------------------------------------------------------------------------

  void _onDevPacket(List<int> frame) {
    if (frame.length < 20) return;
    final bd = ByteData.sublistView(Uint8List.fromList(frame));

    _sensorBuffer.addRawAccel(
      bd.getInt16(2,  Endian.little).toDouble(),
      bd.getInt16(4,  Endian.little).toDouble(),
      bd.getInt16(6,  Endian.little).toDouble(),
    );
    _sensorBuffer.addRawGyro(
      bd.getInt16(8,  Endian.little).toDouble(),
      bd.getInt16(10, Endian.little).toDouble(),
      bd.getInt16(12, Endian.little).toDouble(),
    );
    _sensorBuffer.addRawLight(
      bd.getUint16(16, Endian.little).toDouble(), // clear
      bd.getUint16(14, Endian.little).toDouble(), // f3
    );
    // Mic data for SensorBuffer comes exclusively from this 20 Hz path.
    _sensorBuffer.addRawMic(
      frame[18].toDouble(),          // noiseDbSpl uint8
      bd.getInt8(19).toDouble(),     // noiseDbFs  int8
    );
  }

  // ---------------------------------------------------------------------------
  // Verified frame router — 1 Hz path
  // ---------------------------------------------------------------------------

  void _routeFrame(List<int> frame) {
    final msgType = MsgType.fromByte(frame[1]);
    if (msgType == null) {
      debugPrint('MainShell: unknown msg type 0x${frame[1].toRadixString(16).toUpperCase()}');
      return;
    }

    switch (msgType) {
      case MsgType.unifiedState:
        // Parse once here — canonical byte offsets live in UnifiedTelemetry.fromFrame().
        final sessionId = context.read<SessionStore>().activeSession?.id;
        if (sessionId == null) return;

        final packet = UnifiedTelemetry.fromFrame(
          frame,
          sessionId: sessionId,
          tsMs: DateTime.now().millisecondsSinceEpoch,
        );

        // Feed UI buffer (charts).
        _sensorBuffer.addMetrics(
          steps:         packet.stepCount.toDouble(),
          cadence:       packet.cadence.toDouble(),
          activity:      packet.activityState.toDouble(),
          lux:           packet.clearChannel.toDouble(),
          uvRisk:        packet.uvRisk * 11.0,
          blueIntensity: packet.blueLightIntensity.toDouble(),
          blueRatio:     packet.blueLightRatio,
          colorTemp:     packet.colorTemp.toDouble(),
        );

        // Persist + update domain state. 1 Hz mic values are available via
        // SessionStore.latestNoiseDbSpl / latestNoiseDbFs — not from SensorBuffer.
        context.read<SessionStore>().onUnifiedPacket(packet);

      case MsgType.har:
        // TODO: route HAR activity recognition packet.
        debugPrint('MainShell: HAR packet received (not yet handled)');

      case MsgType.end:
        debugPrint('MainShell: end-of-stream packet received.');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers — nav
  // ---------------------------------------------------------------------------

  List<AppTab> get _activeTabs => [
    if (_devMode) AppTab.devData,
    AppTab.fitness,
    AppTab.light,
    AppTab.stress,
    AppTab.settings,
  ];

  int get _pageIndex => _activeTabs.indexOf(_currentTab).clamp(0, _activeTabs.length - 1);

  void _onDevModeChanged(bool enabled) {
    setState(() {
      _devMode    = enabled;
      _currentTab = AppTab.fitness; // always land on Fitness when toggling
      if (widget.stream != null) widget.stream!.setMcuMode(enabled);
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.stream != null;
    final tabs = _activeTabs;

    final screens = tabs.map((tab) => switch (tab) {
      AppTab.devData  => HomePage(title: 'Raw Data (Dev)', buffer: _sensorBuffer, stream: widget.stream),
      AppTab.fitness  => const FitnessPage(),
      AppTab.light    => const LightPage(),
      AppTab.stress   => const StressPage(),
      AppTab.settings => SettingsPage(
          devMode: _devMode,
          onDevModeChanged: _onDevModeChanged,
        ),
    }).toList();

    final destinations = tabs.map((tab) => switch (tab) {
      AppTab.devData  => const NavigationDestination(icon: Icon(Icons.developer_board), label: 'Dev Data'),
      AppTab.fitness  => const NavigationDestination(icon: Icon(Icons.directions_run),  label: 'Fitness'),
      AppTab.light    => const NavigationDestination(icon: Icon(Icons.wb_sunny),         label: 'Light'),
      AppTab.stress   => const NavigationDestination(icon: Icon(Icons.self_improvement), label: 'Stress'),
      AppTab.settings => const NavigationDestination(icon: Icon(Icons.settings),         label: 'Settings'),
    }).toList();

    return Scaffold(
      body: IndexedStack(
        index: _pageIndex,
        children: screens,
      ),
      floatingActionButton: !isConnected
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConnectionPage(title: 'Connect your device!'),
                ),
              ),
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Connect Glasses'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: (i) => setState(() => _currentTab = _activeTabs[i]),
        destinations: destinations,
      ),
    );
  }
}
