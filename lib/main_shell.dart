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
import 'package:smart_wearables_app/pages/stress_page.dart';
import 'package:smart_wearables_app/pages/settings_page.dart';
import 'app_theme.dart';

class MainShell extends StatefulWidget {
  final MyStream stream;
  final String deviceId;
  const MainShell({super.key, required this.stream, required this.deviceId});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int  _selectedIndex = 0;
  bool _devMode       = false;

  late final SensorBuffer  _buffer;
  late final SessionStore  _store;

  @override
  void initState() {
    super.initState();
    _buffer = SensorBuffer();
    _store  = context.read<SessionStore>();
    _store.startSession(widget.deviceId);
    widget.stream.controller.stream.listen(_onPacket);
  }

  void _onPacket(List<int> packet) {
    if (packet.length < 2) return;
    final type = packet[1];

    switch (type) {
      // IMU — 'A' (0x41) accelerometer, 'G' (0x47) gyroscope
      case 0x41:
      case 0x47:
        final s = ImuSample(
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          stepCount: _extractInt16(packet, 2),
          metric3: _extractInt16(packet, 4).toDouble(),
        );
        _store.onImuPacket(s);
        if (_devMode) _buffer.ingestImu(s);
        break;

      // Light — 'L' (0x4C)
      case 0x4C:
        final s = LightSample(
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          uvRisk:             _extractUint16(packet, 2) / 65535.0,
          blueLightIntensity: _extractUint16(packet, 4).toDouble(),
          blueLightRatio:     _extractUint16(packet, 6) / 65535.0,
          sunLikeIndex:       _extractUint16(packet, 8) / 65535.0,
          metric1:            _extractUint16(packet, 10).toDouble(),
        );
        _store.onLightPacket(s);
        if (_devMode) _buffer.ingestLight(s);
        break;

      // Mic — 'M' (0x4D)
      case 0x4D:
        final s = MicSample(
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          noiseLevel: _extractUint16(packet, 2) / 10.0,  // tenths of dB
          noiseTime:  _extractUint16(packet, 4).toDouble(),
          metric2:    _extractUint16(packet, 6).toDouble(),
        );
        _store.onMicPacket(s);
        if (_devMode) _buffer.ingestMic(s);
        break;
    }
  }

  // ── Packet helpers ─────────────────────────────────────────────────────────
  int _extractInt16(List<int> p, int offset) {
    if (p.length < offset + 2) return 0;
    final lo = p[offset];
    final hi = p[offset + 1];
    int v = (hi << 8) | lo;
    if (v >= 0x8000) v -= 0x10000;
    return v;
  }

  int _extractUint16(List<int> p, int offset) {
    if (p.length < offset + 2) return 0;
    return (p[offset + 1] << 8) | p[offset];
  }

  // ── Dev mode ───────────────────────────────────────────────────────────────
  void _onDevModeChanged(bool val) {
    setState(() {
      _devMode = val;
      if (!val && _selectedIndex == 4) _selectedIndex = 0;
    });
  }

  void _onTabTapped(int index) {
    if (index == 4 && !_devMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable Developer Mode in Settings to access this tab.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _buffer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _buffer),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            const FitnessPage(),
            const LightPage(),
            const StressPage(),
            SettingsPage(
              devMode: _devMode,
              onDevModeChanged: _onDevModeChanged,
            ),
            HomePage(
              title: 'Developer',
              stream: widget.stream,
              buffer: _buffer,
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined,      Icons.home_rounded,     'Home'),
              _navItem(1, Icons.light_mode_outlined, Icons.light_mode_rounded,'Light'),
              _navItem(2, Icons.graphic_eq,          Icons.graphic_eq,       'Stress'),
              _navItem(3, Icons.settings_outlined,   Icons.settings_rounded,  'Settings'),
              _navItem(4, Icons.terminal_outlined,   Icons.terminal,          'Developer',
                  disabled: !_devMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label, {
    bool disabled = false,
  }) {
    final isActive = _selectedIndex == index;
    final color = disabled
        ? AppColors.inactive.withOpacity(0.4)
        : isActive ? AppColors.accent : AppColors.inactive;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? filledIcon : outlinedIcon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              )),
          ],
        ),
      ),
    );
  }
}
