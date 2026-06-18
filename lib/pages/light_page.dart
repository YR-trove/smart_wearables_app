import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store/session_store.dart';

// ---------------------------------------------------------------------------
// LightPage
//
// Displays photobiology metrics derived from the AS7341 spectral sensor.
// All computation lives in SessionStore._processLightMetrics();
// this widget only reads and visualises the results.
// ---------------------------------------------------------------------------
class LightPage extends StatelessWidget {
  const LightPage({super.key});

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _formatSeconds(int s) {
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final rem = s % 60;
    return '${m}m ${rem}s';
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'High':
        return const Color(0xFFEF5350);
      case 'Moderate':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF66BB6A);
    }
  }

  Color _exposureColor(String level) {
    switch (level) {
      case 'High':
        return const Color(0xFFEF5350);
      case 'Moderate':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF26C6DA);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SessionStore>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Light Environment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Circadian score hero card ──
            _CircadianScoreCard(score: store.circadianScore),

            const SizedBox(height: 12),

            // ── Sunlight exposure card ──
            _LightCard(
              icon: Icons.wb_sunny_rounded,
              iconColor: const Color(0xFFFFCA28),
              title: 'Sunlight Exposure',
              children: [
                _MetricRow(
                  label: 'Total Time',
                  value: _formatSeconds(store.sunlightSeconds),
                  valueColor: Colors.white,
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  label: 'UV Index',
                  value: store.currentUvIndex.toStringAsFixed(1),
                  valueColor: Colors.white,
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  label: 'Skin Burn Risk',
                  value: store.skinBurnRisk,
                  valueColor: _riskColor(store.skinBurnRisk),
                ),
                const SizedBox(height: 12),
                // Sunlight progress bar (goal: 20 min = 1200 s for vitamin D)
                _ExposureBar(
                  seconds: store.sunlightSeconds,
                  goalSeconds: 1200,
                  color: const Color(0xFFFFCA28),
                  goalLabel: '20 min recommended daily',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Night blue-light exposure card ──
            _LightCard(
              icon: Icons.nights_stay_rounded,
              iconColor: const Color(0xFF5C6BC0),
              title: 'Night Blue Light',
              children: [
                _MetricRow(
                  label: 'Exposure (after 19:00)',
                  value: _formatSeconds(store.nightBlueLightSeconds),
                  valueColor: Colors.white,
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  label: 'Level',
                  value: store.blueLightExposureLevel,
                  valueColor: _exposureColor(store.blueLightExposureLevel),
                ),
                const SizedBox(height: 12),
                // Blue-light bar (3600 s = High threshold)
                _ExposureBar(
                  seconds: store.nightBlueLightSeconds,
                  goalSeconds: 3600,
                  color: const Color(0xFF5C6BC0),
                  goalLabel: 'Keep below 60 min for healthy sleep',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── UV index gauge card ──
            _LightCard(
              icon: Icons.thermostat_rounded,
              iconColor: const Color(0xFFEF5350),
              title: 'Current UV Index',
              children: [
                _UvGauge(uvIndex: store.currentUvIndex),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Sub-widgets
// ============================================================================

class _LightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _LightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white38, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ExposureBar extends StatelessWidget {
  final int seconds;
  final int goalSeconds;
  final Color color;
  final String goalLabel;

  const _ExposureBar({
    required this.seconds,
    required this.goalSeconds,
    required this.color,
    required this.goalLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (seconds / goalSeconds).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          goalLabel,
          style: const TextStyle(color: Colors.white30, fontSize: 11),
        ),
      ],
    );
  }
}

/// Large circular score widget for the circadian rhythm score (0–100).
class _CircadianScoreCard extends StatelessWidget {
  final int score;
  const _CircadianScoreCard({required this.score});

  Color get _scoreColor {
    if (score >= 80) return const Color(0xFF66BB6A);
    if (score >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFEF5350);
  }

  String get _scoreLabel {
    if (score >= 80) return 'Healthy';
    if (score >= 50) return 'Disrupted';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          const Text(
            'Circadian Rhythm Score',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 10,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        color: _scoreColor,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _scoreLabel,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Score resets to 100 each morning. Deducted by night-time blue light after 19:00.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white30, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// A horizontal UV-index scale bar with a moving needle indicator.
class _UvGauge extends StatelessWidget {
  final double uvIndex;
  const _UvGauge({required this.uvIndex});

  String get _uvLabel {
    if (uvIndex < 3) return 'Low';
    if (uvIndex < 6) return 'Moderate';
    if (uvIndex < 8) return 'High';
    if (uvIndex < 11) return 'Very High';
    return 'Extreme';
  }

  Color get _uvColor {
    if (uvIndex < 3) return const Color(0xFF66BB6A);
    if (uvIndex < 6) return const Color(0xFFFFCA28);
    if (uvIndex < 8) return const Color(0xFFFF9800);
    if (uvIndex < 11) return const Color(0xFFEF5350);
    return const Color(0xFFAB47BC);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (uvIndex / 11.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              uvIndex.toStringAsFixed(1),
              style: TextStyle(
                color: _uvColor,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _uvColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _uvColor.withOpacity(0.4)),
              ),
              child: Text(
                _uvLabel,
                style: TextStyle(
                    color: _uvColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Gradient scale bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 10,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF66BB6A), // Low
                  Color(0xFFFFCA28), // Moderate
                  Color(0xFFFF9800), // High
                  Color(0xFFEF5350), // Very High
                  Color(0xFFAB47BC), // Extreme
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Needle
        FractionallySizedBox(
          widthFactor: fraction,
          alignment: Alignment.centerLeft,
          child: const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.arrow_drop_up_rounded,
                color: Colors.white70, size: 18),
          ),
        ),
        const SizedBox(height: 2),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: TextStyle(color: Colors.white30, fontSize: 10)),
            Text('5', style: TextStyle(color: Colors.white30, fontSize: 10)),
            Text('11+',
                style: TextStyle(color: Colors.white30, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
