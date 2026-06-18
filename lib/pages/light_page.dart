import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/app_theme.dart';
import 'package:smart_wearables_app/data/session_store.dart';

/// Light / Photobiology dashboard — driven entirely by [SessionStore]
/// accumulators updated on every 1 Hz AS7341 packet.
///
/// Displays:
///   • UV index card (live Q15-scaled value)
///   • Sunlight exposure arc gauge (accumulated seconds)
///   • Skin burn risk badge (Low / Moderate / High)
///   • Nighttime blue light exposure bar
///   • Circadian score ring gauge (starts at 100, deducted over time)
class LightPage extends StatelessWidget {
  const LightPage({super.key});

  // ─── Colour helpers ──────────────────────────────────────────────────────────

  Color _uvColor(double idx) {
    if (idx >= 8) return AppColors.danger;
    if (idx >= 6) return AppColors.warning;
    if (idx >= 3) return const Color(0xFFF59E0B);
    return AppColors.success;
  }

  String _uvLabel(double idx) {
    if (idx >= 8) return 'Very High';
    if (idx >= 6) return 'High';
    if (idx >= 3) return 'Moderate';
    return 'Low';
  }

  Color _burnRiskColor(String risk) => switch (risk) {
    'High'     => AppColors.danger,
    'Moderate' => AppColors.warning,
    _          => AppColors.success,
  };

  Color _blueRatioColor(double ratio) {
    if (ratio > 0.5) return AppColors.danger;
    if (ratio > 0.35) return AppColors.warning;
    return AppColors.success;
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SessionStore>();
    final bool  live = store.activeSession != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Light & Environment',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(live ? 'Live' : 'No Session',
                  style: const TextStyle(fontSize: 12, color: Colors.white)),
              backgroundColor: live ? AppColors.success : AppColors.inactive,
              padding: EdgeInsets.zero,
            ),
          )
        ],
      ),
      body: live
          ? _buildLiveDashboard(store)
          : _buildNoSession(context),
    );
  }

  // ─── No-session empty state ──────────────────────────────────────────────────

  Widget _buildNoSession(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wb_sunny_outlined, size: 56, color: AppColors.inactive),
        const SizedBox(height: 16),
        Text('No active session',
            style: TextStyle(fontSize: 16, color: AppColors.muted)),
        const SizedBox(height: 8),
        Text('Connect a device to monitor light exposure.',
            style: TextStyle(fontSize: 14, color: AppColors.inactive)),
      ],
    ),
  );

  // ─── Live dashboard ──────────────────────────────────────────────────────────

  Widget _buildLiveDashboard(SessionStore store) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUvCard(store),
          const SizedBox(height: 12),
          _buildSunlightCard(store),
          const SizedBox(height: 12),
          _buildBlueLightCard(store),
          const SizedBox(height: 12),
          _buildCircadianCard(store),
        ],
      ),
    );
  }

  // ─── UV index card ────────────────────────────────────────────────────────────

  Widget _buildUvCard(SessionStore store) {
    final uv    = store.currentUvIndex;
    final color = _uvColor(uv);
    return AppCard(
      leftBorderColor: color,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.wb_sunny, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UV Index',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(uv.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(_uvLabel(uv),
                          style: TextStyle(fontSize: 14, color: color)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _burnRiskBadge(store.skinBurnRisk),
        ],
      ),
    );
  }

  Widget _burnRiskBadge(String risk) {
    final color = _burnRiskColor(risk);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('Burn: $risk',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ─── Sunlight exposure card ───────────────────────────────────────────────────

  Widget _buildSunlightCard(SessionStore store) {
    final secs  = store.sunlightSeconds;
    final mins  = secs ~/ 60;
    // Recommended 20-30 min of sunlight; cap ring at 60 min.
    final prog  = (secs / 1800.0).clamp(0.0, 1.0);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(text: 'SUNLIGHT EXPOSURE'),
          const SizedBox(height: 12),
          Row(
            children: [
              RingGauge(
                value:       prog,
                color:       AppColors.warning,
                size:        80,
                strokeWidth: 9,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$mins min',
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700)),
                    Text('of broad-spectrum light today',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    AppProgressBar(
                        value: prog, color: AppColors.warning),
                    const SizedBox(height: 4),
                    Text('Goal: 30 min',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.inactive)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Blue light / night exposure card ────────────────────────────────────────

  Widget _buildBlueLightCard(SessionStore store) {
    final nightSecs  = store.nightBlueLightSeconds;
    final nightMins  = nightSecs ~/ 60;
    final ratio      = store.currentBlueRatio;
    final riskProg   = (nightSecs / 3600.0).clamp(0.0, 1.0);
    final riskLabel  = nightSecs < 1800 ? 'Low'
                     : nightSecs < 3600 ? 'Moderate'
                     : 'High';
    final riskColor  = _burnRiskColor(riskLabel);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(text: 'BLUE LIGHT (NIGHT)'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$nightMins min exposure',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('after 19:00 · ratio > 0.35 threshold',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 10),
                    AppProgressBar(value: riskProg, color: riskColor),
                    const SizedBox(height: 4),
                    Text('Risk level: $riskLabel',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: riskColor)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text('Live ratio',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 6),
                  RingGauge(
                    value:       ratio.clamp(0.0, 1.0),
                    color:       _blueRatioColor(ratio),
                    size:        64,
                    strokeWidth: 7,
                  ),
                  const SizedBox(height: 4),
                  Text('${(ratio * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _blueRatioColor(ratio))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Circadian score card ─────────────────────────────────────────────────────

  Widget _buildCircadianCard(SessionStore store) {
    final score = store.circadianScore;
    final prog  = (score / 100.0).clamp(0.0, 1.0);
    final color = score >= 80 ? AppColors.success
                : score >= 50 ? AppColors.warning
                : AppColors.danger;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(text: 'CIRCADIAN RHYTHM SCORE'),
          const SizedBox(height: 12),
          Row(
            children: [
              RingGauge(
                  value: prog, color: color, size: 90, strokeWidth: 10),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$score / 100',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    const SizedBox(height: 6),
                    Text(
                      score >= 80
                          ? 'Great — minimal circadian disruption.'
                          : score >= 50
                              ? 'Moderate — reduce screen time after 19:00.'
                              : 'High disruption — consider blue-light glasses.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Night blue-light: ${store.nightBlueLightSeconds ~/ 60} min',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.inactive),
                    ),
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
