import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/connection/message_type.dart';
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
  final SensorBuffer _buffer = SensorBuffer();
  StreamSubscription<List<int>>? _sub;
  int  _pageIndex = 0;
  bool _devMode   = false;

  // IMU sensitivity constants (LSM6DSO16IS)
  static const double kAccelSens = 2.0 / 32767.0;  // g/LSB  (±2 g range)
  static const double kGyroSens  = 1.0 / 175.0;    // °/s/LSB (±250 dps range)

  @override
  void initState() {
    super.initState();
    _startSession();
    _sub = widget.stream.controller.stream.listen(_onPacket);
  }

  // ── Session start/end ──────────────────────────────────────────────────────

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

  @override
  void dispose() {
    _sub?.cancel();
    context.read<SessionStore>()
        .endSession()
        .catchError((e) => debugPrint('MainShell: endSession error — $e'));
    _buffer.dispose();
    super.dispose();
  }

  // ── Packet router ──────────────────────────────────────────────────────────

  void _onPacket(List<int> data) {
    if (data.length < 20) return;
    final msgType = MsgType.fromByte(data[1]);
    if (msgType == null) {
      debugPrint('MainShell: unknown packet type 0x${data[1].toRadixString(16)}');
      return;
    }

    final store = context.read<SessionStore>();
    final ts    = DateTime.now();

    switch (msgType) {
      // ── Accelerometer ────────────────────────────────────────────────────
      case MsgType.imuAccel:
        final ax = _int16le(data, 2) * kAccelSens;
        final ay = _int16le(data, 4) * kAccelSens;
        final az = _int16le(data, 6) * kAccelSens;
        final stepCount = _uint16le(data, 8);
        _buffer.addAccel(ts, ax, ay, az);
        store.onImuPacket(ImuSample(
          sessionId:  store.activeSession?.id ?? 0,
          timestamp:  ts, type: 'A',
          x: ax, y: ay, z: az,
          stepCount:  stepCount,
        ));

      // ── Gyroscope ────────────────────────────────────────────────────────
      case MsgType.imuGyro:
        final gx = _int16le(data, 2) * kGyroSens;
        final gy = _int16le(data, 4) * kGyroSens;
        final gz = _int16le(data, 6) * kGyroSens;
        _buffer.addGyro(ts, gx, gy, gz);
        store.onImuPacket(ImuSample(
          sessionId: store.activeSession?.id ?? 0,
          timestamp: ts, type: 'G',
          x: gx, y: gy, z: gz,
        ));

      // ── Light sensor ─────────────────────────────────────────────────────
      // TODO: confirm byte offsets once firmware documents the 'L' packet.
      case MsgType.light:
        final uvRisk         = data[2].toDouble();
        final blueLightInt   = _uint16le(data, 3).toDouble();
        final blueLightRatio = data[5] / 100.0;
        final sunLikeIndex   = data[6].toDouble();
        final metric1        = _int16le(data, 7).toDouble();
        _buffer.addLight(ts, uvRisk, blueLightInt, blueLightRatio, sunLikeIndex);
        store.onLightPacket(LightSample(
          sessionId:          store.activeSession?.id ?? 0,
          timestamp:          ts,
          uvRisk:             uvRisk,
          blueLightIntensity: blueLightInt,
          blueLightRatio:     blueLightRatio,
          sunLikeIndex:       sunLikeIndex,
          metric1:            metric1,
        ));

      // ── Microphone ───────────────────────────────────────────────────────
      // TODO: confirm byte offsets once firmware documents the 'M' packet.
      case MsgType.mic:
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

      default:
        debugPrint('MainShell: unhandled packet type ${msgType.name}');
    }
  }

  // ── Little-endian helpers ──────────────────────────────────────────────────

  static int _int16le(List<int> d, int i) {
    int v = d[i] | (d[i + 1] << 8);
    if (v >= 0x8000) v -= 0x10000;
    return v;
  }

  static int _uint16le(List<int> d, int i) => d[i] | (d[i + 1] << 8);

  // ── UI ─────────────────────────────────────────────────────────────────────

  static const _pages = [
    _PageMeta(icon: Icons.show_chart,       label: 'Live'),
    _PageMeta(icon: Icons.directions_run,   label: 'Fitness'),
    _PageMeta(icon: Icons.wb_sunny,         label: 'Light'),
    _PageMeta(icon: Icons.self_improvement, label: 'Stress'),
    _PageMeta(icon: Icons.settings,         label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _pageIndex,
        children: [
          HomePage(title: 'Live Sensors', buffer: _buffer),
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
