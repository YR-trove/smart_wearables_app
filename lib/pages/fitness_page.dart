import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/data/session_store.dart';

// ---------------------------------------------------------------------------
// FitnessPage
//
// Displays live kinematic & biomechanical metrics derived in SessionStore.
// This widget is intentionally kept free of any computation logic — it only
// reads state and renders it.
// ---------------------------------------------------------------------------
class FitnessPage extends StatefulWidget {
  const FitnessPage({super.key});

  @override
  State<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> {
  // A local 1-second timer drives the elapsed-time display so the clock
  // ticks even when no BLE packet arrives.
  late final Timer _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _activityLabel(int state) {
    switch (state) {
      case 1:
        return 'Walking';
      case 2:
        return 'Running';
      default:
        return 'Idle';
    }
  }

  IconData _activityIcon(int state) {
    switch (state) {
      case 1:
        return Icons.directions_walk_rounded;
      case 2:
        return Icons.directions_run_rounded;
      default:
        return Icons.self_improvement_rounded;
    }
  }

  Color _activityColor(int state) {
    switch (state) {
      case 1:
        return const Color(0xFF43A047); // green
      case 2:
        return const Color(0xFFE53935); // red
      default:
        return const Color(0xFF1E88E5); // blue
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SessionStore>();
    final theme = Theme.of(context);
    final elapsed = store.elapsed;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Fitness',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          // Activity state badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: Icon(
                _activityIcon(store.activityState),
                color: Colors.white,
                size: 16,
              ),
              label: Text(
                _activityLabel(store.activityState),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: _activityColor(store.activityState),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Session clock ──
            _SectionCard(
              child: _BigStatTile(
                icon: Icons.timer_rounded,
                iconColor: const Color(0xFFFF9800),
                label: 'Session Time',
                value: _formatDuration(elapsed),
                unit: '',
              ),
            ),

            const SizedBox(height: 12),

            // ── Key metrics row ──
            Row(
              children: [
                Expanded(
                  child: _SectionCard(
                    child: _BigStatTile(
                      icon: Icons.directions_walk_rounded,
                      iconColor: const Color(0xFF26C6DA),
                      label: 'Steps',
                      value: store.currentSteps.toString(),
                      unit: 'steps',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SectionCard(
                    child: _BigStatTile(
                      icon: Icons.route_rounded,
                      iconColor: const Color(0xFF66BB6A),
                      label: 'Distance',
                      value: store.distanceKm.toStringAsFixed(2),
                      unit: 'km',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Calorie meter ──
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: Color(0xFFEF5350), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Calories Burned',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        store.totalKcal.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          'kcal',
                          style: TextStyle(color: Colors.white38, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Visual burn bar — relative to a 500 kcal daily goal
                  _BurnBar(kcal: store.totalKcal, goalKcal: 500),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Weekly steps chart ──
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          color: Color(0xFFAB47BC), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Weekly Steps',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _WeeklyStepsChart(),
                ],
              ),
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

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class _BigStatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _BigStatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            if (unit.isNotEmpty) ...
              [
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(unit,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 14)),
                ),
              ],
          ],
        ),
      ],
    );
  }
}

class _BurnBar extends StatelessWidget {
  final double kcal;
  final double goalKcal;
  const _BurnBar({required this.kcal, required this.goalKcal});

  @override
  Widget build(BuildContext context) {
    final progress = (kcal / goalKcal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF5350)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toStringAsFixed(0)}% of ${goalKcal.toInt()} kcal goal',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

/// Placeholder chart — replace body of FutureBuilder with a real DB query
/// (SELECT day, MAX(step_count) FROM sensor_snapshots
///  WHERE ts > datetime('now', '-7 days') GROUP BY date(ts))
/// and feed the results into the bar painter below.
class _WeeklyStepsChart extends StatelessWidget {
  // Placeholder data — wire to actual SQLite DAO in final integration
  static const List<_DaySteps> _placeholder = [
    _DaySteps('Mon', 4200),
    _DaySteps('Tue', 7800),
    _DaySteps('Wed', 5100),
    _DaySteps('Thu', 9400),
    _DaySteps('Fri', 3300),
    _DaySteps('Sat', 11200),
    _DaySteps('Sun', 6700),
  ];

  const _WeeklyStepsChart();

  @override
  Widget build(BuildContext context) {
    const maxSteps = 12000.0;
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _placeholder.map((d) {
          final frac = d.steps / maxSteps;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: frac * 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFAB47BC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(d.day,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DaySteps {
  final String day;
  final int steps;
  const _DaySteps(this.day, this.steps);
}
