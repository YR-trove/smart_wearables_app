import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/connection/connection_page.dart';
import 'package:smart_wearables_app/connection/message_type.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/data/models/live_packets.dart';
import 'package:smart_wearables_app/data/models/unified_telemetry.dart'; // TODO-REMOVE
import 'package:smart_wearables_app/data/session_store.dart';
import 'package:smart_wearables_app/data/sensor_buffer.dart';
import 'package:smart_wearables_app/home_page.dart';
import 'package:smart_wearables_app/pages/fitness_page.dart';
import 'package:smart_wearables_app/pages/light_page.dart';
import 'package:smart_wearables_app/pages/settings_page.dart';
import 'package:smart_wearables_app/pages/stress_page.dart';

// ── Navigation tabs ───────────────────────────────────────────────────────────

enum AppTab { devData, fitness, light, stress, settings }

/// Top-level shell shown while a BLE device is connected.
class MainShell extends StatefulWidget {
  final MyStream? stream;
  final String?   deviceId;

  const MainShell({super.key, this.stream, this.deviceId});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  StreamSubscription<List<int>>? _sub;

  /// TODO-REMOVE: _devSub was the 20 Hz dev-mode stream subscription.
  /// Remove once dev-dashboard is updated / removed.
  StreamSubscription<List<int>>? _devSub; // TODO-REMOVE

  AppTab _currentTab = AppTab.fitness;
  bool   _devMode    = false;

  final SensorBuffer _sensorBuffer = SensorBuffer();

  @override
  void initState() {
    super.initState();
    if (widget.stream != null && widget.deviceId != null) {
      _startSession();
      _sub = widget.stream!.controller.stream.listen(_onPacket);
      // TODO-REMOVE: remove _devSub once dev-dashboard is removed.
      _devSub = widget.stream!.controllerDevMode.stream.listen(_onDevPacket); // TODO-REMOVE
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _devSub?.cancel(); // TODO-REMOVE
    if (widget.stream != null) {
      context.read<SessionStore>()
          .endSession()
          .catchError((e) => debugPrint('MainShell: endSession error — $e'));
    }
    _sensorBuffer.dispose();
    super.dispose();
  }

  // ── Session start ──────────────────────────────────────────────────────────

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

  // ── Live-mode packet router ────────────────────────────────────────────────
  // Dispatches bare fixed-size packets by their leading msg_type byte.

  void _onPacket(List<int> data) {
    if (data.isEmpty) return;

    final msgType = MsgType.fromByte(data[0]);
    if (msgType == null) {
      debugPrint('MainShell: unknown msg_type 0x${data[0].toRadixString(16).toUpperCase()}');
      return;
    }

    final store     = context.read<SessionStore>();
    final sessionId = store.activeSession?.id;
    final tsMs      = DateTime.now().millisecondsSinceEpoch;

    switch (msgType) {

      // ── IMU metrics (0x50, 7 bytes, 1 Hz) ─────────────────────────────────
      case MsgType.imuMetrics:
        if (sessionId == null) return;
        final packet = LiveImuPacket.fromBytes(data, sessionId: sessionId, tsMs: tsMs);
        store.onImuPacket(packet);
        _sensorBuffer.addImuMetrics(
          steps:    packet.stepCount.toDouble(),
          activity: packet.activity.value.toDouble(),
        );

      // ── Light metrics (0x51, 3 bytes, ~3 s change-gated) ──────────────────
      case MsgType.lightMetrics:
        if (sessionId == null) return;
        final packet = LiveLightPacket.fromBytes(data, sessionId: sessionId, tsMs: tsMs);
        store.onLightPacket(packet);
        _sensorBuffer.addLightMetrics(
          intensity:     packet.intensity.toDouble(),
          exposureClass: packet.exposureClass.value.toDouble(),
        );

      // ── Mic metrics (0x52, 4 bytes, ~3 s change-gated) ────────────────────
      case MsgType.micMetrics:
        if (sessionId == null) return;
        final packet = LiveMicPacket.fromBytes(data, sessionId: sessionId, tsMs: tsMs);
        store.onMicPacket(packet);
        _sensorBuffer.addMicMetrics(
          laeqDb:   packet.laeqDb,
          envClass: packet.envClass.value.toDouble(),
        );

      // ── Connection event (0x53, 2 bytes) ──────────────────────────────────
      case MsgType.connectionEvent:
        if (data.length < 2) return;
        final event = LiveConnectionEvent.fromByte(data[1]);
        if (event == null) return;
        final ack = store.onConnectionEvent(event);
        widget.stream?.sendData(ack);

      // ── Legacy: unified state (0x55) — BLE-sync path only ─────────────────
      // TODO-REMOVE: Remove this case once BLE-sync is migrated.
      case MsgType.unifiedState: // TODO-REMOVE
        if (sessionId == null) return; // TODO-REMOVE
        debugPrint('MainShell: unexpected unifiedState packet in live mode'); // TODO-REMOVE

      // ── TODO-REMOVE: HAR — not yet implemented ─────────────────────────────
      case MsgType.har: // TODO-REMOVE
        debugPrint('MainShell: HAR packet received (not yet handled)'); // TODO-REMOVE

      case MsgType.end:
        debugPrint('MainShell: end-of-stream packet received.');
    }
  }

  // ── TODO-REMOVE: _onDevPacket — 20 Hz raw dev-mode path ───────────────────
  // No equivalent packet exists in ble_live workflow.
  void _onDevPacket(List<int> frame) { // TODO-REMOVE
    debugPrint('MainShell: _onDevPacket called — no-op in ble_live mode'); // TODO-REMOVE
  } // TODO-REMOVE

  // ── Helpers — nav ──────────────────────────────────────────────────────────

  List<AppTab> get _activeTabs => [
    if (_devMode) AppTab.devData,
    AppTab.fitness,
    AppTab.light,
    AppTab.stress,
    AppTab.settings,
  ];

  int get _pageIndex =>
      _activeTabs.indexOf(_currentTab).clamp(0, _activeTabs.length - 1);

  void _onDevModeChanged(bool enabled) {
    setState(() {
      _devMode    = enabled;
      _currentTab = AppTab.fitness;
      // TODO-REMOVE: setMcuMode is a no-op in ble_live; remove call below.
      if (widget.stream != null) widget.stream!.setMcuMode(enabled); // TODO-REMOVE
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.stream != null;
    final tabs        = _activeTabs;

    final screens = tabs.map((tab) => switch (tab) {
      AppTab.devData  => HomePage(
          title: 'Raw Data (Dev)',
          buffer: _sensorBuffer,
          stream: widget.stream),
      AppTab.fitness  => const FitnessPage(),
      AppTab.light    => const LightPage(),
      AppTab.stress   => const StressPage(),
      AppTab.settings => SettingsPage(
          devMode: _devMode,
          onDevModeChanged: _onDevModeChanged,
        ),
    }).toList();

    final destinations = tabs.map((tab) => switch (tab) {
      AppTab.devData  => const NavigationDestination(
          icon: Icon(Icons.developer_board), label: 'Dev Data'),
      AppTab.fitness  => const NavigationDestination(
          icon: Icon(Icons.directions_run), label: 'Fitness'),
      AppTab.light    => const NavigationDestination(
          icon: Icon(Icons.wb_sunny), label: 'Light'),
      AppTab.stress   => const NavigationDestination(
          icon: Icon(Icons.self_improvement), label: 'Stress'),
      AppTab.settings => const NavigationDestination(
          icon: Icon(Icons.settings), label: 'Settings'),
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
                  builder: (_) =>
                      const ConnectionPage(title: 'Connect your device!'),
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
        onDestinationSelected: (i) =>
            setState(() => _currentTab = _activeTabs[i]),
        destinations: destinations,
      ),
    );
  }
}
