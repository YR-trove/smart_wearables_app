import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/app_theme.dart';
import 'package:smart_wearables_app/data/database/session_dao.dart';
import 'package:smart_wearables_app/data/session_store.dart';

/// Fitness dashboard — live biomechanical metrics derived from the 1 Hz
/// MCU telemetry stream via [SessionStore].
///
/// Displays:
///   • Elapsed session time (local Timer.periodic)
///   • Step count, cadence, activity state
///   • Distance covered (km) and caloric expenditure (kcal)
///   • Weekly step bar chart (DB-backed FutureBuilder)
class FitnessPage extends StatefulWidget {
  const FitnessPage({super.key});

  @override
  State<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> {
  Timer?    _clockTimer;
  String    _elapsed   = '00:00:00';
  final     _dao       = SessionDao();

  @override
  void initState() {
    super.initState();
    // Refresh elapsed time every second independently of BLE packets.
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = context.read<SessionStore>().sessionStartTime;
      if (start == null) return;
      final diff  = DateTime.now().difference(start);
      final h     = diff.inHours.toString().padLeft(2, '0');
      final m     = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s     = (diff.inSeconds % 60).toString().padLeft(2, '0');
      if (mounted) setState(() => _elapsed = '$h:$m:$s');
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // ─── Weekly chart future ─────────────────────────────────────────────────────

  late final Future<List<Map<String, dynamic>>> _weeklyFuture =
      _dao.weeklyStepSummary();

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Color _activityColor(int state) => switch (state) {
    2 => AppColors.danger,
    1 => AppColors.success,
    _ => AppColors.inactive,
  };

  IconData _activityIcon(int state) => switch (state) {
    2 => Icons.directions_run,
    1 => Icons.directions_walk,
    _ => Icons.accessibility_new,
  };

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
        title: const Text('Fitness',
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
          : _buildNoSession(),
    );
  }

  // ─── No-session empty state ──────────────────────────────────────────────────

  Widget _buildNoSession() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bluetooth_disabled, size: 56, color: AppColors.inactive),
        const SizedBox(height: 16),
        Text('No active session',
            style: TextStyle(fontSize: 16, color: AppColors.muted)),
        const SizedBox(height: 8),
        Text('Connect a device to start tracking.',
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
          _buildElapsedCard(),
          const SizedBox(height: 12),
          _buildActivityStatusCard(store),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard(
                label:   'Steps',
                value:   '${store.currentSteps}',
                icon:    Icons.footprint,
                color:   AppColors.accent,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard(
                label:   'Cadence',
                value:   '${store.currentCadence} spm',
                icon:    Icons.speed,
                color:   AppColors.warning,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildRingMetricCard(
                label:     'Distance',
                value:     '${store.distanceKm.toStringAsFixed(2)} km',
                progress:  (store.distanceKm / 10.0).clamp(0.0, 1.0),
                color:     AppColors.accent,
                goal:      '10 km goal',
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildRingMetricCard(
                label:     'Calories',
                value:     '${store.totalKcal.toStringAsFixed(0)} kcal',
                progress:  (store.totalKcal / 500.0).clamp(0.0, 1.0),
                color:     AppColors.danger,
                goal:      '500 kcal goal',
              )),
            ],
          ),
          const SizedBox(height: 20),
          _buildWeeklyChart(),
        ],
      ),
    );
  }

  // ─── Elapsed time card ───────────────────────────────────────────────────────

  Widget _buildElapsedCard() => AppCard(
    child: Row(
      children: [
        Icon(Icons.timer_outlined, color: AppColors.accent, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session Time',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
            Text(_elapsed,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
      ],
    ),
  );

  // ─── Activity status card ────────────────────────────────────────────────────

  Widget _buildActivityStatusCard(SessionStore store) => AppCard(
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _activityColor(store.activityState).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_activityIcon(store.activityState),
              color: _activityColor(store.activityState), size: 26),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity State',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
            Text(store.activityLabel,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _activityColor(store.activityState))),
          ],
        ),
      ],
    ),
  );

  // ─── Simple metric card ──────────────────────────────────────────────────────

  Widget _buildMetricCard({
    required String   label,
    required String   value,
    required IconData icon,
    required Color    color,
  }) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700)),
      ],
    ),
  );

  // ─── Ring + metric card ──────────────────────────────────────────────────────

  Widget _buildRingMetricCard({
    required String label,
    required String value,
    required double progress,
    required Color  color,
    required String goal,
  }) => AppCard(
    child: Column(
      children: [
        RingGauge(value: progress, color: color, size: 80, strokeWidth: 9),
        const SizedBox(height: 10),
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(goal,
            style: TextStyle(fontSize: 11, color: AppColors.inactive)),
      ],
    ),
  );

  // ─── Weekly step bar chart (DB query) ────────────────────────────────────────

  Widget _buildWeeklyChart() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('This Week',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary)),
      const SizedBox(height: 10),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _weeklyFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()));
          }
          final data = snap.data ?? [];
          if (data.isEmpty) {
            return Center(
              child: Text('No step data yet.',
                  style: TextStyle(color: AppColors.inactive)));
          }
          final maxSteps = data
              .map((e) => (e['steps'] as int))
              .fold(0, (a, b) => a > b ? a : b)
              .toDouble()
              .clamp(1.0, double.infinity);

          return SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((entry) {
                final steps    = (entry['steps'] as int).toDouble();
                final dayLabel = (entry['day'] as String).substring(5);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          steps > 0 ? '${steps.toInt()}' : '',
                          style: TextStyle(
                              fontSize: 9, color: AppColors.muted),
                        ),
                        const SizedBox(height: 3),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: (steps / maxSteps).clamp(0.04, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: steps > 0
                                    ? AppColors.accent
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(dayLabel,
                            style: TextStyle(
                                fontSize: 10, color: AppColors.muted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    ],
  );
}
