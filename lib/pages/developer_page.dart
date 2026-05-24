import 'package:flutter/material.dart';
import '../theme.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A0F),
      body: SafeArea(
        child: Column(
          children: [
            _StatusBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('STM32U875RIT6Q',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF4B7A5E),
                                    fontFamily: 'monospace',
                                    letterSpacing: 1)),
                            Text('Developer Dashboard',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00FF88))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0040).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFFF0040).withOpacity(0.5)),
                          ),
                          child: const Text('LIVE',
                              style: TextStyle(
                                  color: Color(0xFFFF0040),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _MetricCard(label: 'RSSI', value: '-63', unit: 'dBm', color: const Color(0xFF00C8FF)),
                        const SizedBox(width: 10),
                        _MetricCard(label: 'LATENCY', value: '15', unit: 'ms', color: const Color(0xFF00FF88)),
                        const SizedBox(width: 10),
                        _MetricCard(label: 'FPS', value: '49', unit: 'pk/s', color: const Color(0xFFFFCC00)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SpectralCard(),
                    const SizedBox(height: 12),
                    _WaveformCard(),
                    const SizedBox(height: 12),
                    _IMUCard(),
                    const SizedBox(height: 12),
                    _BLELogCard(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1A0F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, color: Color(0xFF00FF88), size: 16),
          ),
          const SizedBox(width: 4),
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: Color(0xFF00FF88), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text('DEV MODE',
              style: TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontFamily: 'monospace')),
          const SizedBox(width: 16),
          const Text('|', style: TextStyle(color: Color(0xFF2A3A2A))),
          const SizedBox(width: 16),
          const Text('BLE -63dBm',
              style: TextStyle(
                  color: Color(0xFF00C8FF),
                  fontSize: 11,
                  fontFamily: 'monospace')),
          const SizedBox(width: 16),
          const Text('|', style: TextStyle(color: Color(0xFF2A3A2A))),
          const SizedBox(width: 16),
          const Text('49 FPS',
              style: TextStyle(
                  color: Color(0xFFFFCC00),
                  fontSize: 11,
                  fontFamily: 'monospace')),
          const Spacer(),
          const Text('9:41',
              style: TextStyle(color: Color(0xFF4B7A5E), fontSize: 11)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1A14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A2A1E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: 1,
                    color: Color(0xFF4B7A5E),
                    fontFamily: 'monospace')),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'monospace')),
            Text(unit,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4B7A5E),
                    fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}

class _SpectralCard extends StatelessWidget {
  const _SpectralCard();

  @override
  Widget build(BuildContext context) {
    const labels = ['415', '445', '480', '515', '555', '590', '630', '680', '910', 'Clr', 'NIR'];
    const vals = [0.3, 0.4, 0.55, 0.65, 0.72, 0.58, 0.45, 0.6, 0.5, 0.8, 0.7];

    return _DevCard(
      title: '11-CH SPECTRAL SENSOR (AS7341)',
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(labels.length, (i) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 18,
                      height: 60 * vals[i],
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C8FF).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(labels[i],
                        style: const TextStyle(
                            fontSize: 7,
                            color: Color(0xFF4B7A5E),
                            fontFamily: 'monospace')),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('415nm                                                NIR',
                style: TextStyle(fontSize: 8, color: Color(0xFF4B7A5E), fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}

class _WaveformCard extends StatelessWidget {
  const _WaveformCard();

  @override
  Widget build(BuildContext context) {
    final bars = List.generate(40, (i) {
      final h = 0.3 + 0.6 * (0.5 + 0.5 * (i % 7 < 3 ? 1.0 : 0.4));
      return h + (i % 3 == 0 ? 0.1 : -0.05);
    });

    return _DevCard(
      title: 'MEMS MIC — WAVEFORM',
      trailing: const Text('67.3 dB',
          style: TextStyle(
              color: Color(0xFF00C8FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: bars.map((h) {
                final clamped = h.clamp(0.1, 1.0);
                return Container(
                  width: 5,
                  height: 60 * clamped,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C8FF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _FreqLabel('Low Band', '45%', Color(0xFF4B7A5E)),
              _FreqLabel('Mid Band', '72%', Color(0xFF00FF88)),
              _FreqLabel('High Band', '38%', Color(0xFF00C8FF)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FreqLabel extends StatelessWidget {
  final String band;
  final String pct;
  final Color color;

  const _FreqLabel(this.band, this.pct, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(band, style: const TextStyle(fontSize: 9, color: Color(0xFF4B7A5E), fontFamily: 'monospace')),
        Text(pct, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}

class _IMUCard extends StatelessWidget {
  const _IMUCard();

  @override
  Widget build(BuildContext context) {
    return _DevCard(
      title: 'IMU — ACCEL & GYRO (LSM6DS0)',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Accelerometer (m/s²)',
                        style: TextStyle(fontSize: 9, color: Color(0xFF4B7A5E), fontFamily: 'monospace')),
                    const SizedBox(height: 8),
                    _IMURow('X', 0.29, const Color(0xFFEF4444)),
                    const SizedBox(height: 6),
                    _IMURow('Y', 0.64, const Color(0xFF22C55E)),
                    const SizedBox(height: 6),
                    _IMURow('Z', 0.39, const Color(0xFF3B82F6)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gyroscope (°/s)',
                        style: TextStyle(fontSize: 9, color: Color(0xFF4B7A5E), fontFamily: 'monospace')),
                    const SizedBox(height: 8),
                    _IMURow('X', 0.98, const Color(0xFFEF4444)),
                    const SizedBox(height: 6),
                    _IMURow('Y', 0.38, const Color(0xFF22C55E)),
                    const SizedBox(height: 6),
                    _IMURow('Z', 0.06, const Color(0xFF3B82F6)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IMURow extends StatelessWidget {
  final String axis;
  final double value;
  final Color color;

  const _IMURow(this.axis, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(axis,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: const Color(0xFF1A2A1E),
              valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.7)),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(value.toStringAsFixed(2),
            style: const TextStyle(
                color: Color(0xFF4B7A5E),
                fontSize: 10,
                fontFamily: 'monospace')),
      ],
    );
  }
}

class _BLELogCard extends StatelessWidget {
  const _BLELogCard();

  static const _logs = [
    '3772  BLE_RX: IMU[ax=0.12,Ay=9.73,az=0.31]',
    '3772  BLE_RX: SPEC[c0=0.12,c1=0.18,c2=0.28]',
    '3772  BLE_RX: MIC[db=67.4,freq=22006z]',
    '3770  BLE_CONN: RSSI=-62dBm, PPS=48',
  ];

  @override
  Widget build(BuildContext context) {
    return _DevCard(
      title: 'BLE PACKET LOG',
      trailing: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(color: Color(0xFF00FF88), shape: BoxShape.circle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _logs.map((log) {
          final isConn = log.contains('BLE_CONN');
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(log,
                style: TextStyle(
                    fontSize: 10,
                    color: isConn
                        ? const Color(0xFF4B7A5E)
                        : const Color(0xFF00C8FF),
                    fontFamily: 'monospace')),
          );
        }).toList(),
      ),
    );
  }
}

class _DevCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _DevCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2A1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: Color(0xFF4B7A5E),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace')),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
