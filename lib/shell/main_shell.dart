import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/store/session_store.dart';
import 'package:smart_wearables_app/home_page.dart';
import 'package:smart_wearables_app/pages/fitness_page.dart';
import 'package:smart_wearables_app/pages/light_page.dart';

// ---------------------------------------------------------------------------
// MainShell
//
// The post-connection destination.  It owns a BottomNavigationBar with three
// tabs:
//   0 – Sensors  (the original HomePage chart view)
//   1 – Fitness  (FitnessPage  – reads SessionStore)
//   2 – Light    (LightPage    – reads SessionStore)
//
// Packet routing:
//   • All validated 20-byte BLE packets arrive here via [stream].
//   • IMU packets ('A' / 'G') are forwarded to the Sensors tab exactly as
//     before (via MyStream.setNum so the SfCartesianChart controllers update).
//   • Unified telemetry packets ('U') are decoded here and fed to
//     SessionStore.onUnifiedPacket() so Fitness & Light pages update.
//
// UserProfile:
//   Default values (170 cm / 70 kg) are used until a proper settings screen
//   is added.  Replace the constants below or inject real values from a
//   settings provider.
// ---------------------------------------------------------------------------

// Default anthropometric values – replace with settings store later.
const double _kDefaultHeightCm = 170.0;
const double _kDefaultWeightKg = 70.0;

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.stream});
  final MyStream stream;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late StreamSubscription<List<int>> _dataSubscription;

  // Keep the Sensors tab widget alive across tab switches with an IndexedStack.
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      // Tab 0: original chart view – still driven by MyStream directly
      HomePage(
        title: 'Sensors Data',
        stream: widget.stream,
      ),
      // Tab 1 & 2: purely reactive – read SessionStore via context.watch
      const FitnessPage(),
      const LightPage(),
    ];

    // Start the session with default profile as soon as we land here.
    // In a production app you would read this from a user settings provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionStore>().startSession(
            const UserProfile(
              heightCm: _kDefaultHeightCm,
              weightKg: _kDefaultWeightKg,
            ),
          );
    });

    // ── Subscribe to the BLE stream and route each packet ─────────────────
    _dataSubscription =
        widget.stream.controller.stream.listen(_onPacket);
  }

  @override
  void dispose() {
    _dataSubscription.cancel();
    // End the session when we leave the shell (disconnect / back navigation).
    context.read<SessionStore>().endSession();
    super.dispose();
  }

  // ── Packet router ────────────────────────────────────────────────────────
  //
  // Byte layout (20 bytes total):
  //   [0]      = '{' (0x7B) – start byte
  //   [1]      = message type ASCII char
  //   [2..18]  = payload (type-dependent)
  //   [19]     = '}' (0x7D) – end byte
  //
  // Type 'A' / 'G'  → forwarded to home_page.dart via MyStream (unchanged).
  // Type 'U'        → decoded as unified telemetry and sent to SessionStore.
  // Type 'B' (0xb0) → battery; forwarded to controllerBattery (future use).
  void _onPacket(List<int> packet) {
    if (packet.length < 20) return;
    final String type = String.fromCharCode(packet[1]);

    switch (type) {
      // ── IMU data: let home_page.dart handle rendering as before ──────────
      case 'A':
      case 'G':
        // MyStream.setNum() was already called by connection_page before the
        // stream broadcasts here, so we just need to forward to SessionStore
        // for the activity-state + step-count side-channel below.
        // (If no HAR packet exists yet, IMU data alone won't update fitness.)
        break;

      // ── Unified telemetry (1 Hz) ─────────────────────────────────────────
      // Expected payload layout (bytes 2-18):
      //   [2-3]  stepCount     Int16 LE
      //   [4]    activityState uint8  (0=Idle, 1=Walk, 2=Run)
      //   [5-6]  blueRatio     Int16 LE  Q15 fraction  → divide by 32767
      //   [7-8]  sunLike       Int16 LE  Q15 fraction  → divide by 32767
      //   [9-10] uvRisk        Int16 LE  Q15 fraction  → divide by 32767
      //
      // Adjust offsets to match your actual MCU firmware packet layout.
      case 'U':
        _routeUnifiedPacket(packet);
        break;

      default:
        break;
    }
  }

  void _routeUnifiedPacket(List<int> raw) {
    final bd = Uint8List.fromList(raw.sublist(2, 18)).buffer.asByteData();

    final int stepCount     = bd.getInt16(0, Endian.little);
    final int activityState = raw[6]; // byte offset 4 relative to payload start = raw[2+4]=raw[6]
    final double blueRatio  = bd.getInt16(3, Endian.little) / 32767.0;
    final double sunLike    = bd.getInt16(5, Endian.little) / 32767.0;
    final double uvRisk     = bd.getInt16(7, Endian.little) / 32767.0;

    final Map<String, dynamic> packet = {
      'stepCount':     stepCount.clamp(0, 65535),
      'activityState': activityState.clamp(0, 2),
      'blueRatio':     blueRatio.clamp(0.0, 1.0),
      'sunLike':       sunLike.clamp(0.0, 1.0),
      'uvRisk':        uvRisk.clamp(0.0, 1.0),
    };

    // Feed decoded values into the ChangeNotifier → Fitness & Light rebuild.
    context.read<SessionStore>().onUnifiedPacket(packet);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all three pages alive; only visibility changes.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFF1A1A1A),
        indicatorColor: Colors.deepOrange.withOpacity(0.25),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.sensors, color: Colors.deepOrange),
            label: 'Sensors',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined, color: Colors.white54),
            selectedIcon:
                Icon(Icons.directions_run, color: Colors.deepOrange),
            label: 'Fitness',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.wb_sunny, color: Colors.deepOrange),
            label: 'Light',
          ),
        ],
      ),
    );
  }
}
