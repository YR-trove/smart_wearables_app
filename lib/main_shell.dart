import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/connection/connection_page.dart';
import 'package:smart_wearables_app/connection/message_type.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/data/models/live_packets.dart';
import 'package:smart_wearables_app/data/session_store.dart';
import 'package:smart_wearables_app/pages/fitness_page.dart';
import 'package:smart_wearables_app/pages/light_page.dart';
import 'package:smart_wearables_app/pages/settings_page.dart';
import 'package:smart_wearables_app/pages/stress_page.dart';

// ── Navigation tabs ───────────────────────────────────────────────────────────

enum AppTab { fitness, light, stress, settings }

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

  AppTab _currentTab = AppTab.fitness;

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

    int typeByte = data[0];
    // If the packet starts with the 0x7B sentinel (Unified Packet wrapper), the type is at data[1]
    if (typeByte == 0x7B && data.length >= 2) {
      typeByte = data[1];
    }

    final msgType = MsgType.fromByte(typeByte);
    if (msgType == null) {
      debugPrint('MainShell: unknown msg_type 0x${typeByte.toRadixString(16).toUpperCase()}');
      return;
    }

    final store     = context.read<SessionStore>();
    final sessionId = store.activeSession?.id;
    final tsMs      = DateTime.now().millisecondsSinceEpoch;

    switch (msgType) {

      // ── Unified metrics (0x55, 20 bytes, 2 Hz) ──────────────────────────────
      case MsgType.unifiedMetrics:
        if (sessionId == null) return;
        final packet = UnifiedLivePacket.fromBytes(data, sessionId: sessionId, tsMs: tsMs);
        store.onUnifiedPacket(packet);

      // ── Connection event (0x53, 2 bytes) ──────────────────────────────────
      case MsgType.connectionEvent:
        if (data.length < 2) return;
        final event = LiveConnectionEvent.fromByte(data[1]);
        if (event == null) return;
        store.onConnectionEvent(event);

      case MsgType.end:
        debugPrint('MainShell: end-of-stream packet received.');
    }
  }

  // ── Helpers — nav ──────────────────────────────────────────────────────────

  List<AppTab> get _activeTabs => [
    AppTab.fitness,
    AppTab.light,
    AppTab.stress,
    AppTab.settings,
  ];

  int get _pageIndex =>
      _activeTabs.indexOf(_currentTab).clamp(0, _activeTabs.length - 1);

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.stream != null;
    final tabs        = _activeTabs;

    final screens = tabs.map((tab) => switch (tab) {
      AppTab.fitness  => const FitnessPage(),
      AppTab.light    => const LightPage(),
      AppTab.stress   => const StressPage(),
      AppTab.settings => const SettingsPage(),
    }).toList();

    final destinations = tabs.map((tab) => switch (tab) {
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
