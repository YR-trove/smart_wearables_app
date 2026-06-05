import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/data/models/imu_sample.dart';
import 'package:smart_wearables_app/data/models/light_sample.dart';
import 'package:smart_wearables_app/data/models/mic_sample.dart';
import 'package:smart_wearables_app/data/sensor_buffer.dart';
import 'package:smart_wearables_app/data/session_store.dart';
import 'package:smart_wearables_app/home_page.dart';
import 'package:smart_wearables_app/pages/fitness_page.dart';
import 'package:smart_wearables_app/pages/light_page.dart';
import 'package:smart_wearables_app/pages/settings_page.dart';
import 'package:smart_wearables_app/pages/stress_page.dart';

/// Top-level shell shown while a BLE device is connected.
/// Owns the [SensorBuffer] (dev-mode ring buffer) and routes every
/// validated BLE packet to both the buffer (for live charts) and the
/// [SessionStore] (for DB persistence).
class MainShell extends StatefulWidget {
  final MyStream stream;

  /// The BLE device ID returned by [ConnectionPage]. Used by [SessionStore]
  /// to tag the recording session.
  final String deviceId;

  const MainShell({super.key, required this.stream, required this.deviceId});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final SensorBuffer _buffer = SensorBuffer();
  StreamSubscription<List<int>>? _sub;
  int _pageIndex = 0;

  // IMU sensitivity constants (LSM6DSO16IS)
  static const double kAccelSens = 2.0 / 32767.0;  // g/LSB  (±2g range)
  static const double kGyroSens  = 1.0 / 175.0;    // °/s/LSB (±250 dps range)

  @override
  void initState() {
    super.initState();
    _startSession();
    _sub = widget.stream.controller.stream.listen(_onPacket);
  }

  // ── Session start/end ─────────────────────────────────────────

  void _startSession() {
    // Use addPostFrameCallback so the Provider tree is ready before the
    // async call. Errors are logged; the app continues even if DB fails.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final store = context.read<SessionStore>();
        await store.startSession(widget.deviceId);
        debugPrint('MainShell: session started for device ${widget.deviceId}');
      } catch (e) {
        debugPrint('MainShell: startSession error — $e');
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    // End the session when the shell is popped (device disconnect / back nav).
    final store = context.read<SessionStore>();
    store.endSession().catchError(
      (e) => debugPrint('MainShell: endSession error — $e'));
    _buffer.dispose();
    super.dispose();
  }

  // ── Packet router ───────────────────────────────────────────────

  void _onPacket(List<int> data) {
    if (data.length < 20) return;
    final type = String.fromCharCode(data[1]);
    final store = context.read<SessionStore>();
    final ts = DateTime.now();

    switch (type) {
      // ── IMU: Accelerometer ─────────────────────────────────────
      case 'A':
        final ax = _int16le(data, 2) * kAccelSens;
        final ay = _int16le(data, 4) * kAccelSens;
        final az = _int16le(data, 6) * kAccelSens;
        final stepCount = _uint16le(data, 8);
        _buffer.addAccel(ts, ax, ay, az);
        store.onImuPacket(ImuSample(
          sessionId: store.activeSession?.id ?? 0,
          timestamp: ts,
          type: 'A',
          x: ax, y: ay, z: az,
          stepCount: stepCount,
        ));
        break;

      // ── IMU: Gyroscope ────────────────────────────────────────
      case 'G':
        final gx = _int16le(data, 2) * kGyroSens;
        final gy = _int16le(data, 4) * kGyroSens;
        final gz = _int16le(data, 6) * kGyroSens;
        _buffer.addGyro(ts, gx, gy, gz);
        store.onImuPacket(ImuSample(
          sessionId: store.activeSession?.id ?? 0,
          timestamp: ts,
          type: 'G',
          x: gx, y: gy, z: gz,
        ));
        break;

      // ── Light sensor ───────────────────────────────────────────
      // TODO: confirm byte offsets once firmware defines 'L' packet layout.
      case 'L':
        final uvRisk          = data[2].toDouble();
        final blueLightInt    = _uint16le(data, 3).toDouble();
        final blueLightRatio  = data[5] / 100.0;   // byte → 0–255 / 100 ratio
        final sunLikeIndex    = data[6].toDouble();
        final metric1         = _int16le(data, 7).toDouble();
        _buffer.addLight(ts, uvRisk, blueLightInt, blueLightRatio, sunLikeIndex);
        store.onLightPacket(LightSample(
          sessionId:        store.activeSession?.id ?? 0,
          timestamp:        ts,
          uvRisk:           uvRisk,
          blueLightIntensity: blueLightInt,
          blueLightRatio:   blueLightRatio,
          sunLikeIndex:     sunLikeIndex,
          metric1:          metric1,
        ));
        break;

      // ── Microphone ───────────────────────────────────────────────
      // TODO: confirm byte offsets once firmware defines 'M' packet layout.
      case 'M':
        final noiseLevel = _uint16le(data, 2).toDouble();
        final noiseTime  = _uint16le(data, 4).toDouble();
        final metric2    = _int16le(data, 6).toDouble();
        _buffer.addMic(ts, noiseLevel, noiseTime);
        store.onMicPacket(MicSample(
          sessionId:  store.activeSession?.id ?? 0,
          timestamp:  ts,
          noiseLevel: noiseLevel,
          noiseTime:  noiseTime,
          metric2:    metric2,
        ));
        break;

      default:
        debugPrint('MainShell: unknown packet type “$type”');
    }
  }

  // ── Little-endian helpers ───────────────────────────────────────

  static int _int16le(List<int> d, int i) {
    int v = d[i] | (d[i + 1] << 8);
    if (v >= 0x8000) v -= 0x10000;
    return v;
  }

  static int _uint16le(List<int> d, int i) => d[i] | (d[i + 1] << 8);

  // ── UI ────────────────────────────────────────────────────────────────

  static const _pages = [
    _PageMeta(icon: Icons.show_chart,    label: 'Live'),
    _PageMeta(icon: Icons.directions_run,label: 'Fitness'),
    _PageMeta(icon: Icons.wb_sunny,      label: 'Light'),
    _PageMeta(icon: Icons.self_improvement, label: 'Stress'),
    _PageMeta(icon: Icons.settings,      label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _pageIndex,
        children: [
          HomePage(title: 'Live Sensors', buffer: _buffer),
          FitnessPage(buffer: _buffer),
          LightPage(buffer: _buffer),
          StressPage(buffer: _buffer),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: (i) => setState(() => _pageIndex = i),
        destinations: _pages
            .map((p) => NavigationDestination(
                  icon: Icon(p.icon),
                  label: p.label,
                ))
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
